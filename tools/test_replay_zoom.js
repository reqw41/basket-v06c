#!/usr/bin/env node
/**
 * Replay zoom: reproduce the old bugs, then check the native blit.
 *
 *   node tools/test_replay_zoom.js                 # fixed ROM
 *   node tools/test_replay_zoom.js --before        # control ROM, expect the bugs
 *   node tools/test_replay_zoom.js path/to.rom
 */
'use strict';
const fs = require('fs');
const { sym } = require('./v06syms');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const args = process.argv.slice(2);
const BEFORE = args.includes('--before');
const romArg = args.find(a => !a.startsWith('--'));
const ROM = romArg
  ? path.resolve(romArg)
  : path.join(ROOT, BEFORE ? 'build/v06/basket-replay-before.rom' : 'build/v06/basket-replay.rom');

const TAB = [0x00, 0x03, 0x0c, 0x0f, 0x30, 0x33, 0x3c, 0x3f,
             0xc0, 0xc3, 0xcc, 0xcf, 0xf0, 0xf3, 0xfc, 0xff];
const GLYPH = [0x0f, 0x77, 0x77, 0x0f, 0x5f, 0x6f, 0x77, 0xff];
const REPLAY_ROWS = 48;   // one composed eighth: 8 columns x 48 court rows
const ZOOM_ROWS = 96;     // the MSX window: court rows 8..103 → plane y 0..191

function decodeRle(file, expected) {
  const src = fs.readFileSync(file), out = Buffer.alloc(expected);
  let s = 0, d = 0;
  while (s < src.length) {
    const tag = src[s++];
    if (!tag) break;
    if (tag & 0x80) {
      const n = tag & 0x7f, value = src[s++];
      out.fill(value, d, d + n); d += n;
    } else {
      src.copy(out, d, s, s + tag); s += tag; d += tag;
    }
  }
  if (d !== expected) throw new Error(`RLE ${file} produced ${d}, want ${expected}`);
  return out;
}

function expand(b) { return [TAB[b >> 4], TAB[b & 15]]; }

const g = {};
for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g;
g.document = {
  createElement: () => fc(),
  getElementById: () => fc(),
};
function fcx() {
  return {
    createImageData: (w, h) => ({ data: new Uint8ClampedArray((w || 1) * (h || 1) * 4), width: w, height: h }),
    putImageData: () => {}, drawImage: () => {}, getImageData: () => ({ data: new Uint8ClampedArray(4) }),
    fillRect: () => {}, save: () => {}, restore: () => {}, scale: () => {}, setTransform: () => {},
  };
}
function fc() { return { width: 0, height: 0, style: {}, getContext: () => fcx() }; }
g.document.createElement = () => fc();
g.requestAnimationFrame = () => 0;
g.setTimeout = () => 0;
g.print = () => {};
g.console = console;
const ctx = vm.createContext(g);
for (const f of [
  'i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js',
  'src/fili.js', 'src/ay.js', 'src/fd1793.js', 'src/fddimage.js', 'src/i8253.js',
  'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  'Z80_v06.js', 'z80_adapter.js',
]) {
  vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
}
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

function makeEmu() {
  const memory = new Memory();
  const keyboard = new Keyboard();
  const timer = new I8253();
  const ay = new AY();
  const floppy = new (Floppy().FD1793)();
  const io = new IO(keyboard, timer, memory, ay, floppy);
  io.Palette = new Array(16).fill(0xff000000);
  const tape = { advance: () => {}, sample: 0, reset: () => {}, stop: () => {}, sampleAt: () => 0 };
  io.tape_player = tape;
  const cpu = new I8080(memory, io);
  const v06c = new Vector06c(cpu, memory, io, ay, tape);
  v06c.tape_player = tape;
  v06c.bmp = new Uint32Array(576 * 288);
  v06c.displayFrame = () => {};
  v06c.dbg = null;
  v06c.check_breakpoint = () => false;
  const file = new Uint8Array(fs.readFileSync(ROM));
  const base = file.length === 65536 ? 0 : 0x100;
  for (let i = 0; i < file.length && base + i < 0x10000; i++) memory.write(base + i, file[i], false);
  if (memory.detach_boot) memory.detach_boot();
  // Boot copies PAGE0_BLOB (0E00) over the RST page. Do that before any CALL.
  function install() {
    for (let i = 0; i < file.length && base + i < 0x10000; i++) memory.write(base + i, file[i], false);
    if (base === 0x100) {
      for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
    }
    const st = cpu.getState();
    st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 0;
    st.a = st.b = st.c = st.d = st.e = st.h = st.l = 0;
    cpu.setState(st);
    cpu.pc = 0x0100;
    cpu.sp = 0xe000;
    cpu.iff = false;
  }
  install();
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  return { memory, keyboard, cpu, v06c, install };
}

const { memory, keyboard, cpu, v06c, install } = makeEmu();
const rd = a => memory.read(a & 0xffff, false);
const wr = (a, v) => memory.write(a & 0xffff, v & 0xff, false);

let fails = 0;
function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`);
  if (!ok) fails++;
}

function call(addr, regs, opts = {}) {
  const RET = 0x0ff8;
  wr(RET, 0xc9);
  const st = cpu.getState();
  st.pc = addr;
  st.sp = 0xbfee;
  st.a = regs.a ?? 0;
  st.b = regs.b ?? 0;
  st.c = regs.c ?? 0;
  st.d = regs.d ?? 0;
  st.e = regs.e ?? 0;
  st.h = regs.h ?? 0;
  st.l = regs.l ?? 0;
  st.iff1 = opts.iff ? 1 : 0;
  st.iff2 = st.iff1;
  st.imode = opts.imode ?? 1;
  st.halted = false;
  if (regs.flags) Object.assign(st.flags, regs.flags);
  wr(0xbfee, RET & 0xff);
  wr(0xbfef, RET >> 8);
  cpu.setState(st);
  cpu.sp = 0xbfee;
  let cycles = 0, steps = 0, rst08 = 0, rst10 = 0, di = 0, halts = 0;
  const watch = opts.watch || null;
  const reads = { c398: 0, compose: 0, bios: 0 };
  const orig = memory.read.bind(memory);
  memory.read = function (addr, stack) {
    const a = addr & 0xffff;
    const pc = cpu.pc & 0xffff;
    if (!stack && (a < pc || a > pc + 3)) {
      if (a >= 0xc398 && a < 0xc398 + 0xc00) reads.c398++;
      if (a >= 0x2000 && a < 0x4000) reads.compose++;
      if (a >= 0x1e4f && a < 0x1e57) reads.bios++;
    }
    return orig(addr, stack);
  };
  const max = opts.max || 8000000;
  try {
    while ((cpu.pc & 0xffff) !== RET) {
      const pc = cpu.pc & 0xffff;
      if (pc === 0x0008) rst08++;
      if (pc === 0x0010) rst10++;
      if (rd(pc) === 0xf3) di++;
      if (rd(pc) === 0x76) halts++;
      if (watch) watch(pc);
      // NOISE_WAIT (speaker noise) spins until the next vblank without HALT.
      if (pc >= sym('NOISE_SPEAKER') && pc < sym('SND_NOISE_END') && cpu.iff && steps % 2000 === 1999) cpu.interrupt(false);
      if (cpu.getState().halted) {
        if (opts.onHalt) opts.onHalt();
        else cpu.interrupt(false);
      }
      cycles += cpu.instruction() || 0;
      if (++steps > max) throw new Error('timeout pc=' + (cpu.pc & 0xffff).toString(16));
    }
  } finally {
    memory.read = orig;
  }
  return { cycles, steps, rst08, rst10, di, halts, reads, state: cpu.getState() };
}

function fill(lo, hi, v) { for (let a = lo; a < hi; a++) wr(a, v); }

function planeAddr(col, y) { return 0xe000 + col * 256 + ((0xdf - y) & 0xff); }

function writeColorPpm(file) {
  const palette = [[0, 0, 255], [255, 255, 255], [0, 0, 0], [255, 128, 95]];
  const pixels = Buffer.alloc(256 * 192 * 3);
  let out = 0;
  for (let y = 0; y < 192; y++) for (let x = 0; x < 256; x++) {
    const bit = 0x80 >> (x & 7), low = planeAddr(x >> 3, y);
    const pen = ((rd(low) & bit) ? 1 : 0) | ((rd(low - 0x2000) & bit) ? 2 : 0);
    const rgb = palette[pen];
    pixels[out++] = rgb[0]; pixels[out++] = rgb[1]; pixels[out++] = rgb[2];
  }
  fs.writeFileSync(file, Buffer.concat([Buffer.from('P6\n256 192\n255\n'), pixels]));
  const planes = Buffer.alloc(0x4000);
  for (let i = 0; i < 0x2000; i++) {
    planes[i] = rd(0xe000 + i); planes[0x2000 + i] = rd(0xc000 + i);
  }
  fs.writeFileSync(`${file}.planes`, planes);
}
function visibleLowAddr(col, low) { return 0xe000 + col * 256 + low; }
// Composed eighth at 2000: 8 cols x 48 rows, row-major (low, high) pairs.
function quarterAddr(c, r) { return 0x2000 + (r * 8 + c) * 2; }
function putQuarter(fn) {
  fill(0x2000, 0x2500, 0);
  for (let r = 0; r < REPLAY_ROWS; r++) for (let c = 0; c < 8; c++) {
    const [lo, hi] = fn(c, r);
    wr(quarterAddr(c, r), lo & 0xff); wr(quarterAddr(c, r) + 1, hi & 0xff);
  }
}
// Output quarter q (0: columns 0..15, 1: 16..31) against pair source fn.
function expectQuarter(q, fn) {
  const bad = [];
  for (let r = 0; r < REPLAY_ROWS; r++) for (let c = 0; c < 8; c++) {
    const [lo, hi] = fn(c, r);
    const want = [...expand(lo & 0xff), ...expand(hi & 0xff)];
    for (const dy of [0, 1]) {
      const y = 2 * r + dy, col = q * 16 + 2 * c;
      const got = [rd(planeAddr(col, y)), rd(planeAddr(col + 1, y)),
                   rd(planeAddr(col, y) - 0x2000), rd(planeAddr(col + 1, y) - 0x2000)];
      if (got.some((v, i) => v !== want[i])) {
        bad.push(`q${q} r${r}c${c} y${y} got ${got.map(v => v.toString(16))} want ${want.map(v => v.toString(16))}`);
        if (bad.length > 6) return bad;
      }
    }
  }
  return bad;
}
// Snapshot of the zoomed area, then the same staged frame published the
// match way on a clean court; the zoom must be that window doubled.
function snapZoom() {
  const z = [];
  for (let col = 0; col < 32; col++) for (let y = 0; y < 2 * ZOOM_ROWS; y++)
    z.push(rd(planeAddr(col, y)), rd(planeAddr(col, y) - 0x2000));
  return z;
}
function zoomVsWindow(z, half) {
  const bad = [];
  for (let c = 0; c < 16; c++) for (let r = 0; r < ZOOM_ROWS; r++) {
    const col = c + (half ? 16 : 0), low = 0xcf - r;
    const want = [...expand(rd(visibleLowAddr(col, low))), ...expand(rd(visibleLowAddr(col, low) - 0x2000))];
    for (const dy of [0, 1]) {
      const y = 2 * r + dy;
      const H = 2 * ZOOM_ROWS;
      const got = [z[(2 * c * H + y) * 2], z[((2 * c + 1) * H + y) * 2],
                   z[(2 * c * H + y) * 2 + 1], z[((2 * c + 1) * H + y) * 2 + 1]];
      if (got.some((v, i) => v !== want[i])) {
        bad.push(`c${col} r${r} y${y} got ${got.map(v => v.toString(16))} want ${want.map(v => v.toString(16))}`);
        if (bad.length > 6) return bad;
      }
    }
  }
  return bad;
}
const expectedPairs = fs.readFileSync(path.join(ROOT, 'build/v06/expected_court_pairs.bin'));
// Indexed by court source row 0..111 (plane y-8).
const courtPair = (col, y) => {
  const i = ((y - 8) * 32 + col) * 2;
  return [expectedPairs[i], expectedPairs[i + 1]];
};

console.log('ROM', ROM);

if (BEFORE) {
  fill(0xe000, 0x10000, 0);
  wr(0x0f09, 0); wr(0x0f0a, 0); wr(0x0f0b, 0);
  const r = call(0xa93c, { a: 0xaa, h: 0, l: 0, flags: { C: 1, Z: 0, S: 0, H: 0, P: 0, N: 0, Y: 0, X: 0 } }, { max: 200000 });
  const b0 = rd(planeAddr(0, 0)), b1 = rd(planeAddr(0, 1));
  console.log(`A93C A=AA H=0 L=0 → plane y0=${b0.toString(16)} y1=${b1.toString(16)} A=${r.state.a.toString(16)} cycles=${r.cycles} rst08=${r.rst08} rst10=${r.rst10}`);
  check('control: second byte is not AA', b0 === 0xaa && b1 === 0x00, `got ${b0.toString(16)} ${b1.toString(16)}`);

  fill(0xc398, 0xc398 + 0xc00, 0xaa);
  fill(0x2000, 0x4000, 0x55);
  wr(0xa8f9, 0); wr(0xa8fa, 0);
  const z = call(0xa8f4, {}, { max: 8000000 });
  console.log(`A8F4 cycles=${z.cycles} steps=${z.steps} rst08=${z.rst08} rst10=${z.rst10} C398 reads=${z.reads.c398} COMPOSE reads=${z.reads.compose}`);
  check('control: 1536 C398 reads', z.reads.c398 === 1536, String(z.reads.c398));
  check('control: no COMPOSE reads', z.reads.compose === 0, String(z.reads.compose));
  check('control: 6144 RST 08 and RST 10', z.rst08 === 6144 && z.rst10 === 6144, `${z.rst08} ${z.rst10}`);
  process.exit(fails ? 1 : 0);
}

// --- fixed ROM ---
const SYM = require('./v06syms').SYMS;
const BLIT = SYM.REPLAY_BLIT, ZOOM = SYM.REPLAY_ZOOM, STAMP = SYM.REPLAY_STAMP;
const COMPOSE = SYM.REPLAY_COMPOSE, PACE = SYM.REPLAY_PACE, PACE_N = SYM.REPLAY_PACE_N;
const DONE = SYM.REPLAY_DONE;
wr(PACE_N, 0);

// Resource RLE decoder: literals, runs, 127-byte boundary and terminator.
{
  const packed = [3, 0x10, 0x20, 0x30, 0x85, 0xaa, 1, 0x55, 0];
  packed.forEach((v, i) => wr(0x3000 + i, v));
  fill(0x3400, 0x3420, 0xcc);
  const t = call(SYM.RLE_UNPACK, { h: 0x30, l: 0x00, d: 0x34, e: 0x00 });
  const want = [0x10, 0x20, 0x30, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0x55];
  const got = want.map((_, i) => rd(0x3400 + i));
  check('RLE decoder round-trip', got.every((v, i) => v === want[i]) && rd(0x3409) === 0xcc,
    got.map(v => v.toString(16)).join(' '));
}

let r;
// Remaining OUT (98h)/(99h) intercepts, not only the replay double.
{
  const af = { C: 1, Z: 0, S: 1, H: 1, P: 0, N: 1, Y: 0, X: 0 };
  const kept = (st, a) => st.a === a && st.flags.C === 1 && st.flags.Z === 0 && st.flags.S === 1
    && st.flags.H === 1 && st.flags.P === 0 && st.flags.N === 1;
  wr(0x0f0b, 0);
  let o = call(0x0010, { a: 0x00, flags: af });
  check('OUT99 first byte keeps A and flags', kept(o.state, 0x00),
    `A=${o.state.a.toString(16)} C=${o.state.flags.C} Z=${o.state.flags.Z}`);
  o = call(0x0010, { a: 0x40, flags: af });
  check('OUT99 address byte keeps A and flags', kept(o.state, 0x40),
    `A=${o.state.a.toString(16)} C=${o.state.flags.C} Z=${o.state.flags.Z}`);
  o = call(0x0008, { a: 0xaa, flags: af });
  check('OUT98 data byte keeps A and flags', kept(o.state, 0xaa),
    `A=${o.state.a.toString(16)} C=${o.state.flags.C} Z=${o.state.flags.Z}`);
}

// 2-4. quarter blit: patterns, both quarters, both planes, edges, sentinels
function runPattern(name, fn, q) {
  putQuarter(fn);
  fill(0xe000, 0x10000, 0xa5);
  fill(0xc000, 0xe000, 0x5a);
  const t = call(BLIT, { d: q ? 0xf0 : 0xe0, e: 0xdf });
  const bad = expectQuarter(q, fn);
  const Y = 2 * REPLAY_ROWS;
  const below = rd(planeAddr(0, Y)), belowHi = rd(planeAddr(31, Y) - 0x2000);
  const other = rd(planeAddr(q ? 0 : 16, 0)), otherHi = rd(planeAddr(q ? 15 : 31, Y - 1) - 0x2000);
  check(name, bad.length === 0 && below === 0xa5 && belowHi === 0x5a && other === 0xa5 && otherHi === 0x5a
    && t.rst08 === 0 && t.rst10 === 0 && t.di === 0,
    bad[0] || `rst ${t.rst08}/${t.rst10} di ${t.di} below=${below.toString(16)}/${belowHi.toString(16)} other=${other.toString(16)}/${otherHi.toString(16)} cyc ${t.cycles}`);
  return t;
}
const solid = (lo, hi) => () => [lo, hi];
runPattern('solid 00/FF q0', solid(0x00, 0xff), 0);
runPattern('solid FF/00 q0', solid(0xff, 0x00), 0);
runPattern('solid AA/55 q1', solid(0xaa, 0x55), 1);
for (let bit = 0; bit < 8; bit++) runPattern('bit ' + bit, solid(1 << bit, 0x80 >> bit), bit & 1);
runPattern('coord q0', (c, i) => [(c * 17 + i * 3), (c * 5 + i * 11 + 7)], 0);
runPattern('coord q1', (c, i) => [(0x80 + c * 9 + i), (0x33 + c * 3 - i)], 1);
for (const [name, c, i, q] of [['tl', 0, 0, 0], ['tr', 7, 0, 0], ['bl', 0, REPLAY_ROWS - 1, 0], ['br', 7, REPLAY_ROWS - 1, 1]]) {
  runPattern('corner ' + name, (cc, ii) => (cc === c && ii === i ? [0x81, 0x18] : [0, 0]), q);
}

// 5. marker: odd states only; composed into the quarter that holds col 3/28
{
  wr(0x3332, 0);
  call(STAMP, {});
  const odd = rd(0x3332) === 1 && rd(0x0f15) === 1;
  call(STAMP, {});
  check('marker toggles on odd states', odd && rd(0x3332) === 0 && rd(0x0f15) === 0);
  const composeCase = (label, col, stamped, side, glyphCol, row0 = 8) => {
    wr(0x0f80, 0); wr(0x0f15, stamped); wr(0x3333, side); wr(0x0fee, 1);
    fill(0x2000, 0x2500, 0xee);
    const t = call(COMPOSE, { a: col, e: row0 }, { iff: 1 });
    let why = '';
    for (let r = 0; r < REPLAY_ROWS && !why; r++) for (let c = 0; c < 8; c++) {
      let want = courtPair(col + c, r + row0 + 8);
      if (c === glyphCol && r < 8) want = [GLYPH[r], 0];
      const got = [rd(quarterAddr(c, r)), rd(quarterAddr(c, r) + 1)];
      if (got[0] !== want[0] || got[1] !== want[1]) {
        why = `c${c} r${r} got ${got.map(v => v.toString(16))} want ${want.map(v => v.toString(16))}`;
        break;
      }
    }
    const tail = rd(0x2000 + 16 * REPLAY_ROWS);
    check(label, !why && tail === 0xee && t.halts === 0, why || `tail ${tail.toString(16)} cyc ${t.cycles}`);
    return t;
  };
  composeCase('compose court quarter 0', 0, 0, 0, -1);
  composeCase('compose court quarter 3', 24, 0, 0, -1);
  composeCase('marker left at column 3', 0, 1, 0, 3);
  composeCase('marker right at column 28', 24, 1, 0x80, 4);
  composeCase('right marker not in quarter 2', 16, 1, 0x80, -1);
  composeCase('lower half of quarter 0 (rows 56..103)', 0, 0, 0, -1, 8 + REPLAY_ROWS);
  composeCase('marker stays out of the lower half', 0, 1, 0, -1, 8 + REPLAY_ROWS);
  wr(0x0f15, 0);
}


// Runtime sprite record: canvas height, width, top, kept rows, kept rows only
// (tools/prepare_cpc_sprite_bank.py). Rows outside [top, top+keep) are empty.
// Mirrored frames (top bit 7) point at the source rows: bytes in reverse
// order, bits reversed (tools/pack_sprite_mirrors.py, MIR_ROW).
function recordByte(ptr, y, plane, x) {
  const stride = Math.ceil(rd(ptr + 1) / 8), top = rd(ptr + 2) & 0x7f, keep = rd(ptr + 3);
  if (y < top || y >= top + keep) return 0;
  if (rd(ptr + 2) & 0x80) {
    const rows = rd(ptr + 4) | (rd(ptr + 5) << 8);
    let b = rd(rows + (y - top) * stride * 2 + plane * stride + stride - 1 - x), r = 0;
    for (let k = 0; k < 8; k++) { r = (r << 1) | (b & 1); b >>= 1; }
    return r;
  }
  return rd(ptr + 4 + (y - top) * stride * 2 + plane * stride + x);
}

// The match publisher composes damage over the court (damage_publish.asm),
// not over whatever the planes held: stands put the court etalon on screen
// and expect court + sprites.
function courtOnPlanes() {
  wr(SYM.BG_FETCH + 1, SYM.COURT_TILE_PAIR & 0xff); wr(SYM.BG_FETCH + 2, SYM.COURT_TILE_PAIR >> 8);
  const lo = new Uint8Array(32 * 112), hi = new Uint8Array(32 * 112);
  for (let y = 0; y < 112; y++) for (let col = 0; col < 32; col++) {
    const n = y * 32 + col, a = col * 256 + 0xd7 - y;
    lo[n] = expectedPairs[n * 2]; hi[n] = expectedPairs[n * 2 + 1];
    wr(0xe000 + a, lo[n]); wr(0xc000 + a, hi[n]);
  }
  return { lo, hi };
}
// CPC record at ptr drawn at X (two-pixel units) and court row y into the
// expected planes (row-major 32 x 112): pens 1,2,3 → Vector 2,1,3.
function expectSprite(exp, ptr, xUnits, ySigned) {
  const height = rd(ptr), width = rd(ptr + 1), x0 = xUnits * 2;
  for (let sy = 0; sy < height; sy++) {
    const dy = ySigned + sy;
    if (dy < 0 || dy >= 112) continue;
    for (let sx = 0; sx < width; sx++) {
      const dx = x0 + sx;
      if (dx < 0 || dx >= 256) continue;
      const sb = sx >> 3, bit = 0x80 >> (sx & 7);
      const pen = ((recordByte(ptr, sy, 0, sb) & bit) ? 1 : 0) | ((recordByte(ptr, sy, 1, sb) & bit) ? 2 : 0);
      if (!pen) continue;
      const vectorPen = pen === 1 ? 2 : pen === 2 ? 1 : 3;
      const out = dy * 32 + (dx >> 3), outBit = 0x80 >> (dx & 7);
      exp.lo[out] = (exp.lo[out] & ~outBit) | ((vectorPen & 1) ? outBit : 0);
      exp.hi[out] = (exp.hi[out] & ~outBit) | ((vectorPen & 2) ? outBit : 0);
    }
  }
}
function planesMatch(exp) {
  for (let y = 0; y < 112; y++) for (let col = 0; col < 32; col++) {
    const n = y * 32 + col, a = col * 256 + 0xd7 - y, lo = rd(0xe000 + a), hi = rd(0xc000 + a);
    if (lo !== exp.lo[n] || hi !== exp.hi[n])
      return `at ${col * 8},${y}: got ${lo.toString(16)}/${hi.toString(16)} want ${exp.lo[n].toString(16)}/${exp.hi[n].toString(16)}`;
  }
  return '';
}

// overlapping CPC sprites through the direct two-plane entry, then zoom low bit
{
  function spritePtr(index) {
    const off = rd(0x7760 + index * 2) | (rd(0x7761 + index * 2) << 8);
    return 0x415a + off;
  }
  function draw(index, x, y) {
    const ptr = spritePtr(index);
    wr(0x3300, y); wr(0x3301, x);
    wr(0x3302, ptr & 0xff); wr(0x3303, ptr >> 8);
    return call(0x01e9, {});
  }
  function beginColourFrame() {
    // Match renderer (COURT_SYNCED): earlier zoom calls no longer republish
    // the court, which used to set this flag as a side effect.
    wr(0x0fee, 1);
    wr(0x0f80, 0); wr(0xb258, 0);
    wr(0x0f69, 0x98); wr(0x0f6a, 0xb4);
  }
  // Two sprites in one frame: the second is drawn over the first.
  const exp = courtOnPlanes();
  beginColourFrame();
  const colourCycles = draw(0, 16, 20).cycles; // byte column 4, no shift
  draw(1, 16, 20);
  call(SYM.COLOR_FRAME_END, {});
  expectSprite(exp, spritePtr(0), 16, 20);
  expectSprite(exp, spritePtr(1), 16, 20);
  const overlapWhy = planesMatch(exp);
  const overlapOk = !overlapWhy, changed = true;
  // Two staged objects over the court: the zoom equals the doubled window
  // of the same frame published by FRAME_END.
  call(SYM.COURT_TO_PLANES, {}, { max: 4000000 });
  beginColourFrame();
  draw(0, 16, 20);
  draw(1, 22, 30);
  wr(0xa8f9, 0); wr(0x0f18, 0); wr(0x0f15, 0); wr(PACE_N, 0);
  // The zoom borrows CSPR_CACHE_PTR (0F69) as its row cursor; the game never
  // publishes after it, this test does: keep the end of the staged stream.
  const streamEnd = [rd(0x0f69), rd(0x0f6a)];
  const tz = call(ZOOM, {}, { iff: 1, max: 8000000 });
  wr(0x0f69, streamEnd[0]); wr(0x0f6a, streamEnd[1]);
  const z = snapZoom();
  call(SYM.COURT_TO_PLANES, {}, { max: 4000000 });
  call(SYM.COLOR_FRAME_END, {}, { max: 4000000 });
  const bad = zoomVsWindow(z, 0);
  check('zoom of staged sprites matches the published window', bad.length === 0 && tz.rst08 === 0,
    bad[0] || `zoom cyc ${tz.cycles}`);
  check('two-plane transparency/order kept', overlapOk && changed,
    overlapWhy || `one 24x32 sprite ${colourCycles} cycles`);
}

// Staged colour renderer: compare all visible bytes with a pixel model for
// every two-pixel shift and for clipping on each screen edge.
{
  function spritePtr(index) {
    const off = rd(0x7760 + index * 2) | (rd(0x7761 + index * 2) << 8);
    return 0x415a + off;
  }
  function colourCase(label, index, xUnits, ySigned) {
    const exp = courtOnPlanes();
    wr(0x0f80, 0); wr(0xb258, 0);
    wr(0x0f69, 0x98); wr(0x0f6a, 0xb4);
    const ptr = spritePtr(index);
    expectSprite(exp, ptr, xUnits, ySigned);
    wr(0x3300, ySigned & 0xff); wr(0x3301, xUnits & 0xff);
    wr(0x3302, ptr & 0xff); wr(0x3303, ptr >> 8);
    call(0x01e9, {});
    call(SYM.COLOR_FRAME_END, {});
    const why = planesMatch(exp);
    check(label, !why, why);
  }
  colourCase('colour sprite shift 0', 0, 8, 20);
  colourCase('colour sprite shift 2', 0, 9, 20);
  colourCase('colour sprite shift 4', 0, 10, 20);
  colourCase('colour sprite shift 6', 0, 11, 20);
  colourCase('colour sprite clips left/top', 0, -3, -5);
  colourCase('mirrored sprite shift 0', 12, 8, 20);
  colourCase('mirrored sprite shift 6', 12, 11, 20);
  colourCase('mirrored sprite clips left/top', 12, -3, -5);
  colourCase('mirrored hoop shift 2', 67, 9, 20);
  colourCase('colour sprite clips right/bottom', 0, 120, 100);
}

// 6-7. ring step, normal end, key abort, HUD and court come back
{
  const SLOT = 79;
  for (let s = 0; s < 15; s++) {
    for (let i = 0; i < SLOT; i++) wr(0x1b40 + s * SLOT + i, s === 0 ? 0x40 + i : (s & 0xff));
  }
  // ring.asm: playback starts at RING_REPLAY (A859); before the ring has
  // wrapped it plays from slot 1 like the MSX, after a wrap from the oldest
  // record (the next to overwrite) in a circle.
  const play = (wrapped, ptr) => {
    wr(0x0f04, wrapped); wr(0x93d4, ptr & 0xff); wr(0x93d5, ptr >> 8); wr(0x93d3, 0);
    call(SYM.RING_REPLAY, {}, { max: 2000 });
    const seen = [];
    for (let n = 0; n < 20; n++) {
      call(0xa991, {}, { max: 20000 });
      seen.push(rd(0x93eb));
      if (rd(0x93d3) === 1) break;
    }
    return seen;
  };
  let seen = play(0, 0x1b8f + 5 * SLOT);
  check('ring plays slots 1..14 then stops',
    seen.join(',') === '1,2,3,4,5,6,7,8,9,10,11,12,13,14' && rd(0x93d3) === 1, seen.join(','));
  seen = play(1, 0x1b8f + 5 * SLOT);
  check('wrapped ring plays from the oldest record in a circle',
    seen.join(',') === '6,7,8,9,10,11,12,13,14,1,2,3,4,5' && rd(0x93d3) === 1, seen.join(','));

  // The zoom covers the HUD like the MSX full-screen replay; the epilogue
  // draws it back (HUD_DECOR + HUD_TEXT_REFRESH). Reference: the same pair
  // run again on the state the epilogue left (the text follows the state).
  const hudSnap = () => {
    const v = [];
    for (let col = 0; col < 32; col++) for (let e = 0x20; e < 0x68; e++)
      v.push(rd(0xe000 + col * 256 + e), rd(0xc000 + col * 256 + e));
    return v;
  };
  const hudBack = () => {
    const got = hudSnap();
    call(SYM.HUD_DECOR, {}, { iff: 1, max: 4000000 });
    call(SYM.HUD_TEXT_REFRESH, {}, { iff: 1, max: 4000000 });
    const ref = hudSnap();
    const bad = got.findIndex((v, i) => v !== ref[i]);
    if (bad < 0) return '';
    const n = got.filter((v, i) => v !== ref[i]).length, b = bad >> 1;
    return `col ${(b / 72) | 0} e ${(0x20 + b % 72).toString(16)} got ${got[bad].toString(16)} want ${ref[bad].toString(16)} (${n} bytes)`;
  };
  for (let col = 0; col < 32; col++) {
    for (let e = 0x20; e < 0x68; e++) wr(0xe000 + col * 256 + e, (col + e) & 0xff);
  }
  wr(PACE_N, 0);
  wr(0xa8f9, 0);
  wr(0x0f80, 0);
  wr(planeAddr(0, 2 * ZOOM_ROWS), 0x77);
  call(ZOOM, {}, { iff: 1 });
  let covered = 0;
  for (let col = 0; col < 32; col++) for (let y = 2 * ZOOM_ROWS - 72; y < 2 * ZOOM_ROWS; y++)
    if (rd(planeAddr(col, y)) !== ((col + 0xdf - y) & 0xff)) covered++;
  check('zoom covers the HUD band like MSX', covered > 32 * 72 / 2, `${covered} of ${32 * 72} bytes changed`);
  check('zoom stops at plane y 191', rd(planeAddr(0, 2 * ZOOM_ROWS)) === 0x77);
  // normal end: 93D3 = 1, enter at A893. Slot 0 must be copied back to 93EB.
  wr(0x93d3, 1);
  wr(0x93d1, 1);
  r = call(0xa893, {}, { max: 2000000 });
  const hudWhy = hudBack(), hudOk = !hudWhy;
  // court row 0 col 0 is 2500 byte 0 at low D7
  const court0 = rd(0x2500);
  check('normal end restores HUD, court and clears replay flag',
    hudOk && rd(planeAddr(0, 8)) === court0 && rd(0x93d1) === 0 && rd(0x93eb) === 0x40 && rd(0x0f80) === 0 && rd(0xb258) === 0,
    `hud=${hudWhy || 'ok'} court=${rd(planeAddr(0, 8)).toString(16)}/${court0.toString(16)} flag=${rd(0x93d1)} state=${rd(0x93eb).toString(16)}`);
  check('top of the screen is clear after exit', rd(planeAddr(0, 0)) === 0 && rd(planeAddr(31, 7)) === 0);

  // key abort from the real compare, after one more zoom
  for (let col = 0; col < 32; col++) {
    for (let e = 0x20; e < 0x68; e++) wr(0xe000 + col * 256 + e, 0x5a);
  }
  call(ZOOM, {});
  wr(0x4110, 0x20);
  wr(0x93d1, 1);
  wr(0x93d3, 0);
  r = call(0xa8aa, {}, { max: 2000000 });
  const abortWhy = hudBack();
  check('space leaves the loop and restores HUD',
    !abortWhy && rd(0x93d1) === 0 && rd(0x93d3) === 0,
    `hud=${abortWhy || 'ok'} d1=${rd(0x93d1)} d3=${rd(0x93d3)}`);
}

// 8. IRQs during the blit (it never disables them) do not disturb the picture.
{
  const fn = (c, i) => [(c * 13 + i), (c * 7 + 3 * i)];
  putQuarter(fn);
  fill(0xe000, 0x10000, 0);
  const RET = 0x0ff8; wr(RET, 0xc9);
  const st = cpu.getState();
  st.pc = BLIT; st.sp = 0xbfe0; st.iff1 = 1; st.iff2 = 1; st.imode = 1;
  st.d = 0xe0; st.e = 0xdf;
  st.halted = false; st.do_delayed_di = false; st.do_delayed_ei = false;
  wr(0xbfe0, 0xf8); wr(0xbfe1, 0x0f);
  cpu.setState(st); cpu.sp = 0xbfe0;
  let steps = 0, snd = 0, irqs = 0, since = 0;
  while ((cpu.pc & 0xffff) !== RET && steps < 2000000) {
    const pc = cpu.pc & 0xffff;
    if (pc === SYM.V_SND_TICK) snd++;
    if (pc >= BLIT && pc < BLIT + 0x80 && since > 800 && cpu.iff) {
      cpu.interrupt(false, 0xff);
      irqs++;
      since = 0;
    }
    cpu.instruction();
    steps++;
    since++;
  }
  const bad = expectQuarter(0, fn);
  check('IRQ mid-blit still matches the reference', bad.length === 0 && irqs > 0,
    bad[0] || `irqs ${irqs} steps ${steps}`);
  check('those IRQs ran the sound tick', snd === irqs, `snd ${snd} irqs ${irqs}`);
}

// 9. pace from the previous shown state, cycles, RST
{
  wr(0x0f60, 0); wr(0x0f0f, 0); wr(0x0f18, 1);
  wr(PACE_N, 3);
  let snd = 0;
  const t = call(PACE, {}, {
    iff: 1,
    onHalt: () => { cpu.interrupt(false); },
    watch: pc => { if (pc === SYM.V_SND_TICK) snd++; },
  });
  check('pace waits 3 IRQs and ticks sound', t.halts === 3 && rd(0x0f60) === 3 && snd === 3 && rd(0x0f0f) === 3,
    `halts ${t.halts} count ${rd(0x0f60)} last ${rd(0x0f0f)} snd ${snd} cyc ${t.cycles}`);
  wr(0x0f60, 7); wr(0x0f0f, 6);
  const t2 = call(PACE, {}, { iff: 1, onHalt: () => { cpu.interrupt(false); } });
  check('pace counts from the last shown state', t2.halts === 2 && rd(0x0f0f) === 9, `halts ${t2.halts}`);
  wr(0x0f18, 0); wr(0x0f60, 0x40); wr(0x0f0f, 0x3f);
  const t3 = call(PACE, {}, { iff: 1, onHalt: () => { cpu.interrupt(false); } });
  check('first state of a replay shows at once', t3.halts === 0 && rd(0x0f18) === 1 && rd(0x0f0f) === 0x40,
    `halts ${t3.halts} armed ${rd(0x0f18)}`);
  wr(PACE_N, 0);

  putQuarter(solid(0xaa, 0x55));
  const blit = call(BLIT, { d: 0xe0, e: 0xdf });
  wr(0x0f80, 0); wr(0x0f15, 0); wr(0xa8f9, 0);
  const compose = call(COMPOSE, { a: 0, e: 8 }, { iff: 1 });
  const zoom = call(ZOOM, {}, { iff: 1 });
  console.log(`cycles quarter compose=${compose.cycles} blit=${blit.cycles} zoom=${zoom.cycles} (court only, pace 0) rst=${blit.rst08}/${blit.rst10} reads=${blit.reads.compose} c398=${blit.reads.c398}`);
  check('blit has no RST/DI and reads only the composed quarter',
    blit.rst08 === 0 && blit.rst10 === 0 && blit.di === 0 && blit.reads.c398 === 0 && blit.reads.compose === 16 * REPLAY_ROWS,
    `rst ${blit.rst08}/${blit.rst10} di ${blit.di} c398 ${blit.reads.c398} compose ${blit.reads.compose}`);
  check('quarter blit is under 400k cycles', blit.cycles < 400000, String(blit.cycles));
  check('court-only zoom stays under a million cycles', zoom.cycles < 1000000, `zoom ${zoom.cycles}`);
}

// Write-only cost of one source byte's four plane stores, ×96.
// SP walks down E300.. so it cannot smash the caller's stack at DFE0.
{
  let p = 0xb258;
  const emit = (...b) => { for (const x of b) wr(p++, x); };
  emit(0xed, 0x73, 0x50, 0xb2);       // ld (B250), sp
  emit(0x21, 0x00, 0xe3);             // ld hl, E300
  emit(0xf9);                         // ld sp, hl
  emit(0x26, 0xaa);                   // ld h, AA
  emit(0x2e, 0xaa);                   // ld l, AA
  emit(0x06, 96);
  emit(0xe5);                         // push hl  (vertical pair)
  emit(0xe5);                         // push hl
  emit(0x10, 0xfc);                   // djnz
  emit(0xed, 0x7b, 0x50, 0xb2);       // ld sp, (B250)
  emit(0xc9);
  const spc = call(0xb258, {}, { max: 100000 });
  p = 0xb280;
  emit(0x21, 0xdf, 0xe1);             // ld hl, E1DF
  emit(0x3e, 0xaa);
  emit(0x06, 96);
  emit(0x77, 0x2d, 0x77, 0x24, 0x77, 0x2c, 0x77, 0x25, 0x2d);
  emit(0x10, 0xf5);                   // djnz over the 9-byte body
  emit(0xc9);
  const dirc = call(0xb280, {}, { max: 100000 });
  console.log(`write-only 96 source bytes: SP ${spc.cycles} cycles, direct ${dirc.cycles} cycles`);
  check('SP write is not cheaper enough to justify borrowing SP',
    spc.cycles > 0 && dirc.cycles > 0 && spc.cycles * 2 > dirc.cycles,
    `${spc.cycles} vs ${dirc.cycles}`);
}

// Live match: space leaves the title, then "1" only once the menu pose is up.
{
  install();
  const menuBg = fs.readFileSync(path.join(ROOT, 'build/v06/menu_text_lo.bin'));
  const menuBgHi = fs.readFileSync(path.join(ROOT, 'build/v06/menu_text_hi.bin'));
  const expectedPairs = fs.readFileSync(path.join(ROOT, 'build/v06/expected_court_pairs.bin'));
  const courtPair = (col, y) => {
    // expected_court_pairs is indexed by court source row 0..111 (plane y-8).
    const i = ((y - 8) * 32 + col) * 2;
    return [expectedPairs[i], expectedPairs[i + 1]];
  };
  const hudDecor = decodeRle(path.join(ROOT, 'src/assets/hud_decor_v06.rle'), 32 * 72);
  const hudDecorHi = decodeRle(path.join(ROOT, 'src/assets/hud_color_hi_v06.rle'), 32 * 72);
  let phase = 'title';
  let frame = 0;
  const clearKeys = () => { for (let i = 0; i < 8; i++) keyboard.matrix[i] = 0; };
  for (; frame < 2500 && phase !== 'ready'; frame++) {
    clearKeys();
    if (phase === 'title' && frame >= 8 && frame < 40) keyboard.matrix[7] = 0x80;
    if (phase === 'menu') keyboard.matrix[2] = 0x02;
    v06c.oneFrame();
    const y1 = rd(0x940d), y2 = rd(0x9427), ball = rd(0x93f3);
    const pc = cpu.pc & 0xffff;
    if (phase === 'title' && y1 === 0x6e && y2 === 0x6e && rd(0x940b) === 0x10) {
      // Game redraws items from row 64; chrome above that must stay intact.
      let menuArtOk = true;
      for (let col = 0; col < 32 && menuArtOk; col++) for (let y = 8; y < 56; y++) {
        const at = col * 256 + (0xdf - y);
        if (rd(0xe000 + at) !== menuBg[at] || rd(0xc000 + at) !== menuBgHi[at]) {
          menuArtOk = false; break;
        }
      }
      check('menu keeps the CPC text chrome in both planes', menuArtOk);
      phase = 'menu';
      console.log(`menu frame ${frame} pc=${pc.toString(16)} ascii=${rd(0x4110).toString(16)} hook=${rd(0x4141).toString(16)}`);
    } else if (phase === 'menu' && rd(0x93ea) !== 0) {
      phase = 'post';
      console.log(`left menu frame ${frame} pc=${pc.toString(16)} ea=${rd(0x93ea)} ascii=${rd(0x4110).toString(16)} row0=${rd(0x0f20).toString(16)}`);
    } else if (phase === 'menu' && (frame % 40) === 0) {
      console.log(`menu wait frame ${frame} ascii=${rd(0x4110).toString(16)} row0=${rd(0x0f20).toString(16)} sns=${rd(0x4104).toString(16)} y=${y1},${y2}`);
    } else if (phase === 'post' && ball && y1 && y2 && y1 !== y2 && y1 !== 0x6e) {
      phase = 'ready';
      console.log(`match frame ${frame} pc=${pc.toString(16)} y1=${y1} y2=${y2} ball=${ball} x=${rd(0x93f4)}`);
    }
  }
  console.log(`match scan frames=${frame} phase=${phase} pc=${(cpu.pc & 0xffff).toString(16)} y1=${rd(0x940d)} y2=${rd(0x9427)} ball=${rd(0x93f3)}`);
  if (phase === 'ready') {
    let hudDecorOk = true, hudWhy = '', n = 0;
    for (let col = 0; col < 32 && hudDecorOk; col++) for (let e = 0x20; e < 0x68; e++, n++) {
      const lowRequired = hudDecor[n];
      const lowGot = rd(0xe000 + col * 256 + e), highGot = rd(0xc000 + col * 256 + e);
      const oldHigh = hudDecorHi[n];
      const white = lowRequired & ~oldHigh, salmon = lowRequired & oldHigh;
      const blue = (~lowRequired) & oldHigh & 0xff;
      if ((lowGot & (white | salmon)) !== (white | salmon) ||
          (highGot & white) !== 0 || (highGot & salmon) !== salmon ||
          ((lowGot | highGot) & blue) !== 0) {
        hudDecorOk = false; hudWhy = `col=${col} e=${e.toString(16)} got=${lowGot.toString(16)}/${highGot.toString(16)} asset=${lowRequired.toString(16)}/${oldHigh.toString(16)}`; break;
      }
    }
    check('match keeps the complete two-plane framed HUD', hudDecorOk, hudWhy);
    let crowdOk = true;
    // The pose can overlap rows 38-39. These stand pixels stay unobscured.
    for (let y = 19; y <= 37 && crowdOk; y++) for (let col = 4; col < 28; col++) {
      const [lo,hi] = courtPair(col,y);
      if (rd(planeAddr(col,y)) !== lo || rd(planeAddr(col,y)-0x2000) !== hi) {
        crowdOk=false;break;
      }
    }
    check('match keeps the original CPC spectator stand in both planes',crowdOk);
    let bannerOk = true;
    // Court source rows 40..54 publish at screen y 48..62.
    for (let y = 48; y <= 54 && bannerOk; y++) for (const col of [6, 14, 22]) {
      const [lo, hi] = courtPair(col, y);
      if (rd(planeAddr(col, y)) !== lo || rd(planeAddr(col, y) - 0x2000) !== hi) {
        bannerOk = false; break;
      }
    }
    check('match keeps VECTOR boards from the packed court etalon', bannerOk);
    const floorLow = rd(planeAddr(16, 110));
    check('court uses the CPC blue pen behind white line art',
      rd(planeAddr(16, 110) - 0x2000) === 0 && floorLow !== 0xff);
    if (process.env.V06_CAPTURE) writeColorPpm(process.env.V06_CAPTURE);
    const half = (rd(0x9400) & 0x80) ? 1 : 0;
    const hashWin = () => {
      let h = 0;
      for (let i = 0; i < 96; i++) for (let c = 0; c < 16; c++)
        h = (h + rd(visibleLowAddr(c + (half ? 16 : 0), 0xcf - i))) >>> 0;
      return h;
    };
    call(0x01e6, {}, { max: 500000 });
    const courtHash = hashWin();
    call(0x9385, {}, { max: 4000000 });
    wr(0xa8f9, half ? 0x10 : 0);
    wr(0x0f18, 0); wr(0x0f15, 0);
    wr(PACE_N, 0);
    const hud = [], hudHi = [];
    for (let e = 0x20; e < 0x28; e++) {
      hud.push(rd(0xe000 + e)); hudHi.push(rd(0xc000 + e));
    }
    const objects = rd(0x0f80);
    const liveEnd = [rd(0x0f69), rd(0x0f6a)];   // see streamEnd above
    const t = call(ZOOM, {}, { iff: 1, max: 8000000 });
    wr(0x0f69, liveEnd[0]); wr(0x0f6a, liveEnd[1]);
    const z = snapZoom();
    call(SYM.COURT_TO_PLANES, {}, { max: 4000000 });
    call(SYM.COLOR_FRAME_END, {}, { max: 4000000 });
    const drawn = hashWin() !== courtHash;
    const bad = zoomVsWindow(z, half);
    check('live match frame zooms players and the ball',
      bad.length === 0 && drawn && t.rst08 === 0 && t.rst10 === 0,
      bad[0] || `drawn=${drawn} objects=${objects} rst=${t.rst08}/${t.rst10} half=${half} cyc ${t.cycles}`);
    call(ZOOM, {}, { max: 4000000 });
    call(DONE, { a: 1 }, { max: 4000000 });
    let hudOk = true;
    for (let i = 0; i < hud.length; i++) if (rd(0xe020 + i) !== hud[i]) hudOk = false;
    let hudColorOk = true;
    for (let i = 0; i < hudHi.length; i++) if (rd(0xc020 + i) !== hudHi[i]) hudColorOk = false;
    const courtColor = rd(planeAddr(16,100)-0x2000) === courtPair(16,100)[1];
    check('return from the live zoom restores HUD and the court top',
      hudOk && hudColorOk && courtColor && rd(planeAddr(0, 0)) === 0 && rd(planeAddr(31, 7)) === 0 && rd(0x0f18) === 0 && rd(0x0fef) === 0,
      `hud=${hudOk}/${hudColorOk} courtColor=${courtColor} top=${rd(planeAddr(0, 0)).toString(16)} captured=${rd(0x0f18)} snapped=${rd(0x0fef)}`);
    call(SYM.TITLE_SNAP, {}, { max: 2000000 });
    const vis = rd(planeAddr(0, 8));
    check('menu flag after the restored court (the court stays)',
      rd(0x0fef) === 1 && vis === courtPair(0,8)[0] && rd(planeAddr(0, 0)) === 0,
      `snap=${rd(0x0fef)} vis=${vis.toString(16)}`);
  } else {
    check('live match frame zooms players and the ball', false, `phase ${phase}`);
  }
}

console.log(fails ? `\n${fails} FAILED` : '\nALL PASSED');
process.exit(fails ? 1 : 0);
