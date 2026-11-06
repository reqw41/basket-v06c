#!/usr/bin/env node
/**
 * Regression: idle menu must stay responsive.
 *
 * COLOR_FRAME_END once overlapped NORMALIZE_FIND_PAIR at 0B10. Menu early
 * exit then fell into NORMALIZE, ran DIRTY_RESTORE with IX=0 (rect from
 * address 0), and stomped the RET at PLAYER_BACKGROUND_ROW (then 1ACC). Dirty
 * count exploded and the menu hung.
 *
 *   node tools/test_menu_hang.js [path/to.rom]
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = path.resolve(process.argv[2] || path.join(ROOT, 'build/v06/basket.rom'));

const RET_AT_BACKGROUND_ROW = require('./v06syms').sym('PLAYER_BACKGROUND_ROW_END') - 1;   // its RET
const DIRTY_COUNT = 0x0f80;
const MENU_IDLE_FRAMES = 240;

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

const rom = fs.readFileSync(ROM);
const romRet = rom[RET_AT_BACKGROUND_ROW - 0x100];
if (romRet !== 0xc9) fail(`ROM RET at 1ACC is ${romRet.toString(16)}, want c9`);

const emu = boot();
const rd = (a) => emu.memory.read(a & 0xffff, false);
const keys = (row, mask) => {
  for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0;
  if (mask) emu.keyboard.matrix[row] = mask;
};

let phase = 'title';
let menuAt = -1;
let maxDirty = 0;

for (let frame = 0; frame < 120 + MENU_IDLE_FRAMES; frame++) {
  keys(0, 0);
  if (phase === 'title' && frame >= 8 && frame < 100) keys(7, 0x80);
  emu.v06c.oneFrame();

  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) {
    phase = 'menu';
    menuAt = frame;
  }
  if (phase !== 'menu') continue;

  const ret = rd(RET_AT_BACKGROUND_ROW);
  if (ret !== 0xc9) {
    fail(`frame ${frame}: PLAYER_BACKGROUND_ROW RET stomped to ${ret.toString(16)} (menu hang)`);
  }
  const dirty = rd(DIRTY_COUNT);
  if (dirty > maxDirty) maxDirty = dirty;
  if (dirty > 32) {
    fail(`frame ${frame}: DIRTY_COUNT=${dirty} (menu hang / list smash)`);
  }
  if (frame === menuAt + MENU_IDLE_FRAMES) break;
}

if (menuAt < 0) fail('never reached menu');

// Menu must still accept Start (key "1") and leave for the match.
phase = 'start';
let matchAt = -1;
for (let frame = 0; frame < 400; frame++) {
  keys(2, 0x02);
  emu.v06c.oneFrame();
  if (rd(RET_AT_BACKGROUND_ROW) !== 0xc9) {
    fail(`start frame ${frame}: RET stomped while leaving menu`);
  }
  if (rd(DIRTY_COUNT) > 32) {
    fail(`start frame ${frame}: DIRTY_COUNT=${rd(DIRTY_COUNT)} while leaving menu`);
  }
  // Match clears TITLE_SNAPPED and sets MATCH_MODE (0FED).
  if (rd(0x0fef) === 0 && rd(0x0fed) === 1) {
    matchAt = frame;
    break;
  }
}
if (matchAt < 0) fail('menu did not enter match after Start');

console.log(
  `OK menu hang: idle ${MENU_IDLE_FRAMES}f maxDirty=${maxDirty}, match at +${matchAt}`
);
