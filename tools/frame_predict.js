#!/usr/bin/env node
/**
 * Frame predictor: every byte of the court on screen against a frame built
 * independently from what the game asked to draw (headless vector06js).
 *
 *   node tools/frame_predict.js [rom] [dump_dir]
 *   env SEED (12345), NF (3000), CPU (z80 | i8080, default z80), SHOW (15)
 *
 * Diagnostics: dump_dir gets planes + prediction of each differing publish
 * (0000 low plane, 2000 high, 4000 expected pairs); EV=<frame> logs frame
 * begin/end with the object list; WATCHW=<lo>,<hi>,<frame> logs writes and
 * the writer PC; DIAG=1 counts differing bytes that equal the previous
 * frame; CLASSES=1 prints newly differing bytes per publish with the
 * objects covering them; PATCH="addr:hex ..." pokes bytes after loading.
 *
 * The game draws a frame as COLOR_MATCH_PREP (begin), one COLOR_SPRITE call
 * per object with BLIT_Y, BLIT_X, BLIT_SRC, then COLOR_FRAME_END (publish).
 * The predictor records those calls and, when the publish ends (cfp_done),
 * composes the expected court rows 0..111 from scratch:
 *
 *   court etalon (build/v06/expected_court_pairs.bin, or the stamped one
 *   while BG_FETCH points at the CPC stamp), then each recorded sprite in
 *   call order, decoded from its record (tools/pack_sprite_mirrors.py
 *   format) with the CPC rule: opaque = p0|p1, low plane = p1, high = p0.
 *
 * None of the renderer's own state (dirty lists, caches, staged stream) is
 * used, so restore, skip-unchanged, reorder and clip bugs all show up as a
 * byte that differs. Only live-match publishes outside the replay are
 * checked. Exit 1 on any differing publish or when none was checked.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = path.resolve(process.argv[2] || path.join(ROOT, 'build/v06/basket.rom'));
const OUT = process.argv[3];
const Z80 = (process.env.CPU || 'z80') === 'z80';
const { sym } = require('./v06syms');

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
g.console = console;
const ctx = vm.createContext(g);
for (const f of [
  'i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js',
  'src/fili.js', 'src/ay.js', 'src/fd1793.js', 'src/fddimage.js', 'src/i8253.js',
  'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  ...(Z80 ? ['Z80_v06.js', 'z80_adapter.js'] : []),
]) vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

// Adapter entries (same addresses in the Z80 and the i8080 image).
const PREP = sym('COLOR_MATCH_PREP'), SPRITE = sym('COLOR_SPRITE'), DONE = sym('cfp_done');
const BLIT_Y = sym('BLIT_Y'), BLIT_X = sym('BLIT_X'), BLIT_SRC = sym('BLIT_SRC');
const BG_FETCH = sym('BG_FETCH');
const COURT_SYNCED = 0x0FEE, MATCH_FLAG = 0x0FED, REPLAY = 0x93D1;

function boot() {
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
  if (base === 0x100) for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
  if (Z80) {
    const st = cpu.getState();
    st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1;
    cpu.setState(st);
  }
  cpu.pc = 0x0100; cpu.sp = 0xe000;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  for (const pa of (process.env.PATCH || '').split(' ').filter(Boolean)) {   // PATCH="addr:hex ..." experiments
    const [a, h] = pa.split(':'), at = parseInt(a, 16);
    Buffer.from(h, 'hex').forEach((b, i) => memory.write(at + i, b, false));
  }
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () { const p = cpu.pc & 0xffff; if (HOOKS[p]) HOOKS[p](); return oi(); };
  return { memory, keyboard, cpu, v06c };
}

const HOOKS = {};
const emu = boot();
if (process.env.WATCHW) {   // WATCHW=addr,addr2,from_frame: log writers
  const [w0, w1, wf] = process.env.WATCHW.split(',').map((x) => parseInt(x, 16));
  const ow = emu.memory.write.bind(emu.memory);
  emu.memory.write = function (a, v, s) {
    if (a >= w0 && a <= w1 && frame >= wf) console.log(`F${frame} W ${a.toString(16)}=${(v & 255).toString(16)} pc=${(emu.cpu.pc & 0xffff).toString(16)} old=${emu.memory.read(a, false).toString(16)}`);
    return ow(a, v, s);
  };
}
const rd = (a) => emu.memory.read(a & 0xffff, false);
const rw = (a) => rd(a) | rd(a + 1) << 8;
const S8 = (x) => (x & 0x80 ? x - 256 : x);
const E0 = fs.readFileSync(path.join(ROOT, 'build/v06/expected_court_pairs.bin'));
const E1 = fs.readFileSync(path.join(ROOT, 'build/v06/expected_stamped_court_pairs.bin'));
const REV = new Uint8Array(256);
for (let x = 0; x < 256; x++) { let r = 0; for (let b = 0; b < 8; b++) if (x & 1 << b) r |= 0x80 >> b; REV[x] = r; }

// Canvas row y of the record at ptr: [plane0 bytes, plane1 bytes] (stride each).
function spriteRow(ptr, y) {
  const w = rd(ptr + 1), t = rd(ptr + 2), keep = rd(ptr + 3), st = (w + 7) >> 3;
  const top = t & 0x7f, mir = t & 0x80;
  const p0 = new Array(st).fill(0), p1 = new Array(st).fill(0);
  if (y < top || y >= top + keep) return [p0, p1];
  const rows = mir ? rw(ptr + 4) : ptr + 4, at = rows + (y - top) * 2 * st;
  for (let i = 0; i < st; i++) {
    if (mir) { p0[i] = REV[rd(at + st - 1 - i)]; p1[i] = REV[rd(at + 2 * st - 1 - i)]; }
    else { p0[i] = rd(at + i); p1[i] = rd(at + st + i); }
  }
  return [p0, p1];
}

const shiftPlane = (p, s) => {
  if (!s) return p.slice();
  const out = [];
  let carry = 0;
  for (const b of p) { out.push((b >> s | carry) & 0xff); carry = b << (8 - s) & 0xff; }
  out.push(carry);
  return out;
};

// Expected court rows 0..111 as [lo, hi] pairs, (row * 32 + col) * 2.
function predict(list) {
  const E = Buffer.from(rw(BG_FETCH + 1) !== sym('COURT_TILE_PAIR') ? E1 : E0);
  for (const s of list) {
    const h = rd(s.src), x = S8(s.x), s2 = (x & 3) * 2, col0 = x >> 2;
    const y0 = S8(s.synced ? s.y : (s.y - 7) & 0xff);
    for (let y = 0; y < h; y++) {
      const r = y0 + y;
      if (r < 0 || r >= 112) continue;
      const [a0, a1] = spriteRow(s.src, y), q0 = shiftPlane(a0, s2), q1 = shiftPlane(a1, s2);
      for (let j = 0; j < q0.length; j++) {
        const c = col0 + j;
        if (c < 0 || c >= 32) continue;
        const k = (r * 32 + c) * 2, m = ~(q0[j] | q1[j]) & 0xff;
        E[k] = E[k] & m | q1[j];
        E[k + 1] = E[k + 1] & m | q0[j];
      }
    }
  }
  return E;
}

let frame = 0, phase = 'title', list = [], checked = 0, bad = 0, shown = 0, stamped = 0, replays = 0, inReplay = 0;
const SHOW = +(process.env.SHOW || 15);
if (OUT) fs.mkdirSync(OUT, { recursive: true });
let prev = [], pdiff = new Set();
const EV = process.env.EV ? +process.env.EV : Infinity;
const objs = (l) => l.map((s) => `${s.src.toString(16)}@${S8(s.x)},${S8(s.y)}`).join(' ');
HOOKS[PREP] = () => { prev = list; list = []; if (frame >= EV) console.log(`F${frame} PREP`); };
HOOKS[sym('COLOR_MENU_PREP')] = HOOKS[PREP];
HOOKS[sym('COLOR_FRAME_END')] = () => { if (frame >= EV) console.log(`F${frame} END n=${list.length} ${objs(list)}`); };
// BEAM=1: tearing. A copied row is "ahead" when written before the beam
// shows it this frame (raster line < 80 + row) and "behind" otherwise; a box
// with rows on both sides is shown torn for one frame.
const beam = { boxes: 0, torn: 0, worst: '' };
let box = null;
const beamRow = () => {
  const line = emu.v06c.filler ? emu.v06c.filler.raster_line : 0, row = 0xd7 - (emu.cpu.getState ? emu.cpu.getState().e : emu.cpu.regs[3]);
  if (!box) return;
  if (line < 80 + row) box.ahead++; else box.behind++;
  if (box.first === undefined) box.first = line; box.last = line; box.rows = (box.rows || 0) + 1;
};
const fit = {}, gaps = {}, starts = {}, waits = []; let waitAt = null; let lastBox = null;   // BEAM=2: raster lines per copied row, by box width

const beamEnd = () => {
  if (!box) return;
  beam.boxes++;
  if (process.env.BEAM === '2') {
    if (lastBox && lastBox.f === frame && box.first > lastBox.last) { const g = box.first - lastBox.last; gaps[g] = (gaps[g] || 0) + 1; }
    else starts[box.first] = (starts[box.first] || 0) + 1;
  }
  lastBox = { f: frame, last: box.last };
  if (box.rows > 8) { const f = fit[box.w] || (fit[box.w] = [0, 0]); f[0] += box.last - box.first; f[1] += box.rows - 1; }
  if (box.ahead && box.behind) { beam.torn++; if (!beam.worst) beam.worst = `F${frame} box ${JSON.stringify(box)}`; if (process.env.BEAMLOG) console.log(`torn F${frame} ${JSON.stringify(box)}`); }
  box = null;
};
if (process.env.BEAM) {
  HOOKS[sym('PUBLISH_RECT')] = () => { beamEnd(); box = { r: rd(0x0f1b), w: rd(0x0f1c), h: rd(0x0f1d), line: emu.v06c.filler.raster_line, ahead: 0, behind: 0 }; };
  HOOKS[sym('pr_row')] = beamRow;
  // BEAM=2: the behind-the-beam wait, raster lines per wait line.
  HOOKS[sym('dic_line')] = () => { if (!waitAt) waitAt = { w: rd(0x0f01), line: emu.v06c.filler.raster_line }; };
  HOOKS[sym('dic_now')] = () => { if (waitAt) { waits.push(((emu.v06c.filler.raster_line - waitAt.line) / waitAt.w).toFixed(3)); waitAt = null; } };
}
// HITS=name,name: count how often each adapter label runs (debugging).
const hits = {};
for (const n of (process.env.HITS || '').split(',').filter(Boolean)) { hits[n] = 0; const a = sym(n), h = HOOKS[a]; HOOKS[a] = () => { hits[n]++; if (h) h(); }; }
HOOKS[SPRITE] = () => {
  list.push({ src: rw(BLIT_SRC), x: rd(BLIT_X), y: rd(BLIT_Y), synced: rd(COURT_SYNCED) });
};
// Menu publishes: the menu players stand on the blue panel (pen 0 in both
// planes; the menu always restored solid blue under them), then the
// sprites. Checked: the bytes under the old and the new sprite rectangles.
let mchecked = 0, mbad = 0;
const menuBg = () => [0, 0];
function menuCheck() {
  mchecked++;
  const cells = new Map();
  const rect = (s) => {
    const x = S8(s.x), col0 = x >> 2, w = (rd(s.src + 1) + 7 >> 3) + 1, r0 = S8((s.y - 7) & 0xff);
    for (let r = r0; r < r0 + rd(s.src); r++) for (let c = col0; c < col0 + w; c++) {
      const e = 0xd7 - r;
      if (c >= 0 && c < 32 && e >= 0 && e < 256) cells.set(c * 256 + e, menuBg(c, e));
    }
  };
  prev.forEach(rect); list.forEach(rect);
  for (const s of list) {
    const h = rd(s.src), x = S8(s.x), s2 = (x & 3) * 2, col0 = x >> 2, y0 = S8((s.y - 7) & 0xff);
    for (let y = 0; y < h; y++) {
      const [a0, a1] = spriteRow(s.src, y), q0 = shiftPlane(a0, s2), q1 = shiftPlane(a1, s2);
      for (let j = 0; j < q0.length; j++) {
        const v = cells.get((col0 + j) * 256 + 0xd7 - (y0 + y));
        if (!v) continue;
        const m = ~(q0[j] | q1[j]) & 0xff;
        v[0] = v[0] & m | q1[j]; v[1] = v[1] & m | q0[j];
      }
    }
  }
  const diff = [];
  for (const [a, v] of cells) if (rd(0xe000 + a) !== v[0] || rd(0xc000 + a) !== v[1]) diff.push(`c${a >> 8}y${0xdf - (a & 255)}`);
  if (!diff.length) return;
  mbad++;
  if (process.env.MDIAG && shown < 2) for (const [a, v] of [...cells].filter(([a, v]) => rd(0xe000 + a) !== v[0] || rd(0xc000 + a) !== v[1]).slice(0, 12)) console.log(`  c${a >> 8} y${0xdf - (a & 255)} screen ${rd(0xe000 + a).toString(16)}/${rd(0xc000 + a).toString(16)} want ${v[0].toString(16)}/${v[1].toString(16)} bg ${menuBg(a >> 8, a & 255).map((x) => x.toString(16)).join('/')}`);
  if (shown++ < SHOW) console.log(`menu F${frame} n=${list.length} prev=${prev.length} differ ${diff.length}: ${diff.slice(0, 10).join(' ')} | ${objs(list)}`);
}
HOOKS[DONE] = () => {
  if (phase === 'menu' && !rd(COURT_SYNCED) && rd(0x0fef)) return menuCheck();
  if (phase !== 'match' || rd(REPLAY) || !rd(COURT_SYNCED)) return;
  checked++;
  if (rw(BG_FETCH + 1) !== sym('COURT_TILE_PAIR')) stamped++;
  const E = predict(list), diff = [];
  for (let r = 0; r < 112; r++) for (let c = 0; c < 32; c++) {
    const a = c * 256 + 0xd7 - r, lo = rd(0xe000 + a), hi = rd(0xc000 + a), k = (r * 32 + c) * 2;
    if (lo !== E[k] || hi !== E[k + 1]) diff.push(`c${c}r${r}`);
  }
  const fresh = diff.filter((d) => !pdiff.has(d));
  pdiff = new Set(diff);
  if (process.env.CLASSES) {   // one line per publish: counts, diff owners
    const own = new Set();
    for (const d of fresh) {
      const [c, r] = d.slice(1).split('r').map(Number);
      const hit = list.map((s, i) => [s, i]).filter(([s]) => { const x = S8(s.x) >> 2, y = S8(s.synced ? s.y : s.y - 7), w = (rd(s.src + 1) + 7 >> 3) + (s.x & 3 ? 1 : 0); return c >= x && c < x + w && r >= y && r < y + rd(s.src); });
      own.add(hit.length ? hit.map(([s, i]) => `${i}h${rd(s.src)}`).join('+') : 'bg');
    }
    if (fresh.length) console.log(`CLASS F${frame} n${fresh.length} ${prev.length}->${list.length} [${list.map((s) => rd(s.src)).join(',')}] ${[...own].sort().join(' ')}`);
  }
  if (!diff.length) return;
  bad++;
  if (shown++ < SHOW) {
    let stale = 0;
    if (process.env.DIAG) { const P = predict(prev); for (const d of diff) { const [c, r] = d.slice(1).split('r').map(Number), a = c * 256 + 0xd7 - r, k = (r * 32 + c) * 2; if (rd(0xe000 + a) === P[k] && rd(0xc000 + a) === P[k + 1]) stale++; } }
    console.log(`F${frame} n=${list.length} differ ${diff.length}${process.env.DIAG ? ` (as previous frame ${stale})` : ''}: ${diff.slice(0, 10).join(' ')} | ${objs(list)}`);
  }
  if (OUT) {
    const buf = Buffer.alloc(0x4000 + 112 * 64);
    for (let i = 0; i < 0x2000; i++) { buf[i] = rd(0xe000 + i); buf[0x2000 + i] = rd(0xc000 + i); }
    E.copy(buf, 0x4000);
    fs.writeFileSync(path.join(OUT, `f${String(frame).padStart(5, '0')}.bin`), buf);
  }
};

const keys = (row, mask) => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; if (mask) emu.keyboard.matrix[row] = mask; };
let rnd = +(process.env.SEED || 12345);
const rand = () => (rnd = (Math.imul(rnd, 1103515245) + 12345) & 0x7fffffff) / 0x7fffffff;
let cur = 0, hold = 0;
for (; frame < +(process.env.NF || 3000); frame++) {
  keys(0, 0);
  if (phase === 'title' && frame >= 8 && frame < 40) keys(7, 0x80);
  if (phase === 'menu' && frame >= +(process.env.MENU || 0)) keys(2, 0x02);
  if (phase === 'match') {
    const x = rd(0x940d), y = rd(0x940e);
    if (hold-- <= 0) { hold = 5 + Math.floor(rand() * 30); cur = Math.floor(rand() * 7); }
    if (cur < 3) { if (x > 0x5a) keys(0, 0x10); else if (x < 0x50) keys(0, 0x40); else if (y > 0x0c) keys(0, 0x20); else keys(7, 0x80); }
    else { const m = [[0, 0x10], [0, 0x40], [0, 0x20], [7, 0x80]][cur - 3]; keys(m[0], m[1]); }
  }
  emu.v06c.oneFrame();
  if (rd(REPLAY) && !inReplay) replays++;
  inReplay = rd(REPLAY);
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  else if (phase === 'menu' && rd(MATCH_FLAG) === 1) phase = 'match';
}
if (process.env.BEAM) { beamEnd(); console.log(`beam: ${beam.boxes} boxes, ${beam.torn} torn ${beam.worst}`); }
if (process.env.BEAM === '2') console.log('behind waits (lines per wait line):', waits.length, [...new Set(waits)].join(' '));
if (process.env.BEAM === '2') console.log('gaps (lines from the last row of a box to the first of the next):', JSON.stringify(gaps), 'batch first rows at lines:', JSON.stringify(starts));
if (process.env.BEAM === '2') for (const w of Object.keys(fit)) console.log(`fit w=${w} rows ${fit[w][1]} cycles/row ${(fit[w][0] * 192 / fit[w][1]).toFixed(0)}`);
if (process.env.HITS) console.log('hits', JSON.stringify(hits));
console.log(`menu publishes ${mchecked}, differing ${mbad}`);
console.log(`publishes ${checked} (stamped ${stamped}, replays ${replays}), differing ${bad}`);
console.log(bad || mbad || !(checked + mchecked) ? 'FRAME_PREDICT_FAIL' : 'FRAME_PREDICT_PASS');
process.exit(bad || mbad || !(checked + mchecked) ? 1 : 0);
