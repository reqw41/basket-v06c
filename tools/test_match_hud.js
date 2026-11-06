#!/usr/bin/env node
/**
 * Regression: after menu→match, HUD_DECOR must replace menu residue.
 *
 * HUD_RLE_APPLY STOREs the packed frames (clears menu residue). Match text is
 * reprinted by HUD_TEXT_REFRESH after HUD_DECOR — scores are drawn before the
 * multi-frame unpack and would otherwise stay wiped.
 *
 *   node tools/test_match_hud.js [path/to.rom]
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = path.resolve(process.argv[2] || path.join(ROOT, 'build/v06/basket.rom'));

function decodeRle(file, n) {
  const b = fs.readFileSync(file);
  const o = new Uint8Array(n);
  let i = 0, j = 0;
  while (i < b.length && j < n) {
    const c = b[i++];
    if (c & 0x80) {
      let r = c & 0x7f;
      const v = b[i++];
      while (r-- && j < n) o[j++] = v;
    } else {
      let r = c;
      while (r-- && j < n && i < b.length) o[j++] = b[i++];
    }
  }
  return o;
}

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
g.console = { log: () => {}, warn: () => {}, error: () => {}, debug: () => {}, info: () => {} };
const ctx = vm.createContext(g);
for (const f of [
  'i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js',
  'src/fili.js', 'src/ay.js', 'src/fd1793.js', 'src/fddimage.js', 'src/i8253.js',
  'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  'Z80_v06.js', 'z80_adapter.js',
]) vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

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
  const st = cpu.getState();
  st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1;
  cpu.setState(st); cpu.pc = 0x0100; cpu.sp = 0xe000;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  return { memory, keyboard, cpu, v06c };
}

function fail(msg) {
  console.error('FAIL:', msg);
  process.exit(1);
}

const hudLo = decodeRle(path.join(ROOT, 'src/assets/hud_decor_v06.rle'), 32 * 72);
const hudHiRaw = decodeRle(path.join(ROOT, 'src/assets/hud_color_hi_v06.rle'), 32 * 72);
const emu = boot();
const rd = (a) => emu.memory.read(a & 0xffff, false);
const keys = (row, mask) => {
  for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0;
  if (mask) emu.keyboard.matrix[row] = mask;
};

let phase = 'title';
let matchAt = -1;
for (let frame = 0; frame < 500; frame++) {
  keys(0, 0);
  if (phase === 'title' && frame >= 8 && frame < 100) keys(7, 0x80);
  if (phase === 'menu') keys(2, 0x02);
  emu.v06c.oneFrame();
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) {
    phase = 'menu';
  }
  if (phase === 'menu' && rd(0x0fef) === 0 && rd(0x0fed) === 1) {
    matchAt = frame;
    phase = 'match';
    break;
  }
}
if (matchAt < 0) fail('never entered match');

// Same acceptance as test_replay_zoom: pens after HUD_DECOR remap.
let why = '';
outer: for (let col = 0, n = 0; col < 32; col++) {
  for (let e = 0x20; e < 0x68; e++, n++) {
    const lowRequired = hudLo[n];
    const oldHigh = hudHiRaw[n];
    const lowGot = rd(0xe000 + col * 256 + e);
    const highGot = rd(0xc000 + col * 256 + e);
    const white = lowRequired & ~oldHigh;
    const salmon = lowRequired & oldHigh;
    const blue = (~lowRequired) & oldHigh & 0xff;
    if (
      (lowGot & (white | salmon)) !== (white | salmon) ||
      (highGot & white) !== 0 ||
      (highGot & salmon) !== salmon ||
      ((lowGot | highGot) & blue) !== 0
    ) {
      why = `col=${col} e=${e.toString(16)} got=${lowGot.toString(16)}/${highGot.toString(16)} asset=${lowRequired.toString(16)}/${oldHigh.toString(16)}`;
      break outer;
    }
  }
}
if (why) fail(`match HUD broken after start: ${why}`);

// Hold a few frames — DIRTY_RESTORE must not strip the HUD band.
for (let i = 0; i < 45; i++) {
  keys(0, 0);
  emu.v06c.oneFrame();
}
why = '';
outer2: for (let col = 0, n = 0; col < 32; col++) {
  for (let e = 0x20; e < 0x68; e++, n++) {
    const lowRequired = hudLo[n];
    const oldHigh = hudHiRaw[n];
    const lowGot = rd(0xe000 + col * 256 + e);
    const highGot = rd(0xc000 + col * 256 + e);
    const white = lowRequired & ~oldHigh;
    const salmon = lowRequired & oldHigh;
    const blue = (~lowRequired) & oldHigh & 0xff;
    if (
      (lowGot & (white | salmon)) !== (white | salmon) ||
      (highGot & white) !== 0 ||
      (highGot & salmon) !== salmon ||
      ((lowGot | highGot) & blue) !== 0
    ) {
      why = `col=${col} e=${e.toString(16)} got=${lowGot.toString(16)}/${highGot.toString(16)}`;
      break outer2;
    }
  }
}
if (why) fail(`match HUD degraded after 45 frames: ${why}`);

// Match must keep running — STORE-shrunk HUD must not slide TILE_FAST_FILL
// off 8495 (call 8495 / patch 849B). Player coords are 940D/940E.
const p0 = { a: rd(0x940d), b: rd(0x940e), fee: rd(0x0fee), f80: rd(0x0f80) };
for (let i = 0; i < 200; i++) {
  keys(4, i < 120 ? 0x40 : 0x80); // same chords as test_player_motion
  emu.v06c.oneFrame();
}
const p1 = { a: rd(0x940d), b: rd(0x940e), fee: rd(0x0fee), f80: rd(0x0f80) };
if (p1.fee !== 1 || p1.f80 < 6) {
  fail(`match idle: fee=${p1.fee} f80=${p1.f80} (expected fee=1, sprites)`);
}
if (p1.a === p0.a && p1.b === p0.b) {
  fail(`match hung: player ${p0.a},${p0.b} stuck (TILE_FAST_FILL / frame path)`);
}

// Match-enter prints scoreboard glyphs, then FRAME_RESET → HUD_DECOR STORE.
// HUD_TEXT_REFRESH must put side-panel digits back.
let scoreInk = 0;
for (const col of [1, 2, 3, 4, 5, 8, 9, 10, 20, 21, 22, 27, 28, 29]) {
  for (let row = 0; row < 8; row++) {
    const y = 18 * 8 + row;
    const e = 0xd7 - y;
    if (rd(0xe000 + (0xe0 + col) * 256 + e)) scoreInk++;
  }
}
if (scoreInk < 16) {
  fail(`scoreboard empty: side-panel low ink=${scoreInk} (HUD_DECOR STORE wipe?)`);
}

console.log(
  `OK match HUD: start@${matchAt}, stable 45f, moved ${p0.a},${p0.b}→${p1.a},${p1.b} f80=${p1.f80} scoreInk=${scoreInk}`
);
