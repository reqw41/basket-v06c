#!/usr/bin/env node
/**
 * Live checks for dunk rim-frame changes, NORMALIZE_OLD bit7, and stand
 * colours after sprite overlay / replay return.
 *
 *   node tools/test_dunk_anim.js [rom]
 */
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = path.resolve(process.argv[2] || path.join(ROOT, 'build/v06/basket.rom'));
const COURT_SHA = '5c5f0a541dfd9a07b5f57323a4fab739bd96b78f9a53c1477dda2d43396e35d8';

const g = {};
for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g;
function fcx() {
  return {
    createImageData: (w, h) => ({ data: new Uint8ClampedArray((w || 1) * (h || 1) * 4), width: w, height: h }),
    putImageData: () => {}, drawImage: () => {}, getImageData: () => ({ data: new Uint8ClampedArray(4) }),
    fillRect: () => {}, save: () => {}, restore: () => {}, scale: () => {}, setTransform: () => {},
  };
}
function fc() { return { width: 0, height: 0, style: {}, getContext: () => fcx() }; }
g.document = { createElement: () => fc(), getElementById: () => fc() };
g.requestAnimationFrame = () => 0;
g.setTimeout = () => 0;
g.print = () => {};
g.console = { log: () => {}, debug: () => {}, error: console.error, warn: console.warn };
const ctx = vm.createContext(g);
for (const f of [
  'i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js',
  'src/fili.js', 'src/ay.js', 'src/fd1793.js', 'src/fddimage.js', 'src/i8253.js',
  'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  'Z80_v06.js', 'z80_adapter.js',
]) vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

function boot(romPath) {
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
  v06c.dbg = null;
  v06c.check_breakpoint = () => false;
  const file = new Uint8Array(fs.readFileSync(romPath));
  const base = file.length === 65536 ? 0 : 0x100;
  for (let i = 0; i < file.length && base + i < 0x10000; i++) memory.write(base + i, file[i], false);
  if (base === 0x100) for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
  const st = cpu.getState();
  st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1;
  cpu.setState(st); cpu.pc = 0x0100; cpu.sp = 0xe000;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  return { memory, keyboard, cpu, v06c, io };
}

function call(cpu, memory, addr) {
  const wr = (a, v) => memory.write(a & 0xffff, v, false);
  const st = cpu.getState();
  st.pc = addr; st.sp = 0xbf00;
  cpu.setState(st); cpu.pc = addr; cpu.sp = 0xbf00;
  wr(0xbf00, 0); wr(0xbf01, 0);
  let n = 0;
  while (n++ < 50000) {
    if ((cpu.pc & 0xffff) === 0) return;
    cpu.instruction();
  }
  throw new Error(`call ${addr.toString(16)} timeout`);
}

let fails = 0;
function check(name, ok, why) {
  if (ok) console.log(`PASS ${name}`);
  else { console.error(`FAIL ${name}${why ? ': ' + why : ''}`); fails++; }
}

// --- NORMALIZE_OLD must not re-apply new bit7 onto old slots for player heights
{
  const emu = boot(ROM);
  const rd = a => emu.memory.read(a & 0xffff, false);
  const wr = (a, v) => emu.memory.write(a & 0xffff, v, false);
  wr(0xfee, 1); wr(0xb258, 2);
  wr(0xb259, 1); wr(0xb25a, 2); wr(0xb25b, 3); wr(0xb25c, 4);
  wr(0xb25d, 5); wr(0xb25e, 6); wr(0xb25f, 7); wr(0xb260, 8);
  wr(0xf80, 2);
  wr(0xf81, 10); wr(0xf82, 20); wr(0xf83, 0x80 | 3); wr(0xf84, 32);
  wr(0xf85, 11); wr(0xf86, 21); wr(0xf87, 0x80 | 3); wr(0xf88, 32);
  call(emu.cpu, emu.memory, 0x17b5);
  check('NORMALIZE_OLD clears bit7 without copying player unchanged onto old slots',
    !(rd(0xb25b) & 0x80) && !(rd(0xb25f) & 0x80) && rd(0xb25b) === 3 && rd(0xb25f) === 7,
    `got ${rd(0xb25b).toString(16)}/${rd(0xb25f).toString(16)}`);
}

// Independent CPC Mode1 stand pens (rows 16..37, cols 4..27) for live compare.
const cpcBank = fs.readFileSync(path.join(ROOT, 'src/assets/cpc_court_mode1.bin'));
check('CPC court etalon sha', crypto.createHash('sha256').update(cpcBank).digest('hex') === COURT_SHA);
function cpcPen(sourceRow, x) {
  // Court source row y>=8 comes from CPC bank row (y-8). Screen plane y = source+8.
  const value = cpcBank[(sourceRow - 8) * 64 + (x >> 2)];
  const q = x & 3;
  return ((value >> (7 - q)) & 1) | (((value >> (3 - q)) & 1) << 1);
}
const remap = [0, 2, 1, 3];
function expectPair(screenY, col) {
  const sourceRow = screenY - 8;
  let lo = 0, hi = 0;
  for (let x = 0; x < 8; x++) {
    const pen = remap[cpcPen(sourceRow, col * 8 + x)];
    const bit = 0x80 >> x;
    if (pen & 1) lo |= bit;
    if (pen & 2) hi |= bit;
  }
  return [lo, hi];
}
function planeAddr(col, y) { return 0xe000 + col * 256 + ((0xdf - y) & 0xff); }

const emu = boot(ROM);
const rd = a => emu.memory.read(a & 0xffff, false);
const keys = (row, mask) => {
  for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0;
  if (mask) emu.keyboard.matrix[row] = mask;
};

let phase = 'title';
let matchAt = 0;
let scoreAt = -1;
let zoomAt = -1;
let replayDone = false;
const hoopPtrs = new Set();
let rimChanges = 0;
let prevRim = null;
let standOkBefore = false;
let standOkAfterMove = false;
let standOkAfterReplay = false;

function standBandOk() {
  // Centre spectator band: away from dunk-side players/hoops, still has pink.
  for (let y = 19; y <= 37; y++) {
    for (let col = 10; col < 22; col++) {
      const [lo, hi] = expectPair(y, col);
      if (rd(planeAddr(col, y)) !== lo || rd(planeAddr(col, y) - 0x2000) !== hi) return false;
    }
  }
  return true;
}

function standBandHasCrowdColour() {
  // After replay require CPC Mode1 pens, not menu-invert mono.
  // Centre-band etalon is ~[454,81,907,382] (hi<<1|lo); one mid pen is <100.
  const counts = [0, 0, 0, 0];
  for (let y = 19; y <= 37; y++) {
    for (let col = 10; col < 22; col++) {
      const lo = rd(planeAddr(col, y)), hi = rd(planeAddr(col, y) - 0x2000);
      for (let bit = 0; bit < 8; bit++) {
        const pen = (((hi >> (7 - bit)) & 1) << 1) | ((lo >> (7 - bit)) & 1);
        counts[pen]++;
      }
    }
  }
  return counts[0] > 100 && counts[3] > 100 && counts[1] > 50 && counts[2] > 100
      && counts[1] + counts[2] > 900;
}

function rimCrop() {
  const pens = [];
  for (let y = 16; y < 48; y++) {
    for (let x = 8; x < 40; x++) {
      const col = x >> 3, bit = 7 - (x & 7);
      const addr = col * 256 + (0xdf - y);
      const lo = rd(0xe000 + addr), hi = rd(0xc000 + addr);
      pens.push((((lo >> bit) & 1) << 1) | ((hi >> bit) & 1));
    }
  }
  return Buffer.from(pens);
}

for (let frame = 0; frame < 4500; frame++) {
  keys(0, 0);
  if (phase === 'title' && frame >= 8 && frame < 40) keys(7, 0x80);
  if (phase === 'menu') keys(2, 0x02);
  if (phase === 'match' || phase === 'scored') {
    const x = rd(0x940d), y = rd(0x940e);
    if (x > 0x5a) keys(0, 0x10);
    else if (x < 0x50) keys(0, 0x40);
    else if (y > 0x0c) keys(0, 0x20);
    else keys(7, 0x80);
  }
  emu.v06c.oneFrame();
  const y1 = rd(0x940d), y2 = rd(0x9427);
  if (phase === 'title' && y1 === 0x6e && y2 === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  else if (phase === 'menu' && rd(0x0fed) === 1) { phase = 'match'; matchAt = frame; }

  if (phase === 'match' && !standOkBefore && rd(0xfee) === 1 && rd(0xfef) === 0) {
    standOkBefore = standBandOk();
  }
  if (phase === 'match' && standOkBefore && !standOkAfterMove && frame - matchAt >= 180
      && rd(0xfee) === 1 && rd(0xfef) === 0) {
    standOkAfterMove = standBandOk();
  }

  if (phase !== 'match' && phase !== 'scored') continue;
  const sc = rd(0x9400) & 7;
  if (sc && scoreAt < 0) { scoreAt = frame; phase = 'scored'; }
  if (rd(0x93d1) && zoomAt < 0) zoomAt = frame;
  if (zoomAt >= 0 && rd(0x93d1) === 0 && rd(0x0fed) === 1 && !replayDone) {
    replayDone = true;
    // Court tiles republish over a few frames after zoom exits.
    for (let settle = 0; settle < 30 && !standOkAfterReplay; settle++) {
      standOkAfterReplay = standBandHasCrowdColour();
      if (!standOkAfterReplay) emu.v06c.oneFrame();
    }
    break;
  }
  if (scoreAt < 0) continue;
  if (frame - scoreAt > 500 && zoomAt < 0) break;
  // Court republish after each zoomed state costs extra frames beyond the
  // 14×32 IRQ pace; keep headroom so exit + stand restore are observed.
  if (zoomAt >= 0 && frame - zoomAt > 1600) break;

  const n = rd(0xf80);
  for (let i = 0; i < n; i++) {
    const ptr = rd(0xb2c5 + i * 4) | (rd(0xb2c6 + i * 4) << 8);
    // Right hoops are padded to the 24px MSX canvas; left stay 20 wide.
    if (ptr >= 0x4000 && rd(ptr) === 24 && (rd(ptr + 1) === 20 || rd(ptr + 1) === 24)) hoopPtrs.add(ptr);
  }
  const crop = rimCrop();
  if (prevRim) {
    for (let i = 0; i < crop.length; i++) if (crop[i] !== prevRim[i]) rimChanges++;
  }
  prevRim = crop;
}

check('match stands match CPC Mode1 before sprites cover them', standOkBefore);
check('match stands survive player motion overlays', standOkAfterMove);
check('score enters dunk/score path', scoreAt >= 0, `scoreAt=${scoreAt}`);
check('rim/net animation changes visible pixels during score', rimChanges >= 200, `rimChanges=${rimChanges}`);
check('hoop source frames cycle during score', hoopPtrs.size >= 2,
  `ptrs=${[...hoopPtrs].map(p => p.toString(16)).join(',')}`);
check('replay zoom runs after type-4 dunk', zoomAt >= 0, `zoomAt=${zoomAt}`);
check('replay returns and restores CPC stand colours', replayDone && standOkAfterReplay,
  `replayDone=${replayDone} stands=${standOkAfterReplay}`);

console.log(fails ? `\n${fails} FAILED` : '\nALL dunk/stand checks passed');
process.exit(fails ? 1 : 0);
