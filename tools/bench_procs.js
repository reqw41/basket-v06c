#!/usr/bin/env node
/**
 * Inclusive cycles of adapter procedures (headless vector06js):
 *   node tools/bench_procs.js [rom]    env PROCS=A,B (names, tools/v06syms.js), NF, SEED
 * Random keyboard play from title through a match (as collect_exec_v06.js);
 * a call ends when SP rises above its entry SP. HALT and the NOISE_WAIT
 * vblank wait are not counted. Prints calls, cycles per call and per game
 * iteration (8554) during the match.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = path.resolve(process.argv[2] || path.join(ROOT, 'build/v06/basket.rom'));

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
  const exec = new Uint8Array(0x10000);
  const count = new Float64Array(0x10000), cyc = new Float64Array(0x10000);
  global.PROF = { count, cyc, iters: 0 };
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    const p = cpu.pc & 0xffff; exec[p] = 1; count[p]++;
    if (p === 0x8554 && global.PROF.match) global.PROF.iters++;   // game main-loop iteration
    if (global.BENCH) global.BENCH(p);
    if (global.HOOK && WATCH[p]) global.HOOK(p);
    const r = oi(); cyc[p] += cpu.vcycles || r || 0; return r; };
  return { memory, keyboard, cpu, v06c, exec };
}

const { sym, SYMS } = require('./v06syms');
const emu = boot();
const rd = a => emu.memory.read(a & 0xffff, false);
const keys = (row, mask) => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; if (mask) emu.keyboard.matrix[row] = mask; };
// Inclusive cycles of adapter procedures (entry until SP rises above the
// entry SP), minus HALT and the NOISE_WAIT vblank wait. Match phase only.
const NAMES = (process.env.PROCS || 'COLOR_SPRITE,COLOR_FRAME_END,BUFFER_PLAYERS,DIRTY_RESTORE').split(',');
const entry = {}; for (const n of NAMES) entry[sym(n)] = n;
const waitLo = sym('NOISE_WAIT'), waitHi = sym('SND_NOISE_SCAN');
const tot = {}, calls = {}; const frames = [];
let last = 0;
global.BENCH = (p) => {
  if (!global.PROF.match) return;
  const cy = global.PROF.cycAll || 0;
  const sp = emu.cpu.sp & 0xffff;
  while (frames.length && sp > frames[frames.length - 1].sp) {
    const f = frames.pop(); tot[f.n] = (tot[f.n] || 0) + (cy - f.c - f.w); calls[f.n] = (calls[f.n] || 0) + 1;
    for (const g of frames) g.w += 0;
  }
  if (entry[p] !== undefined) frames.push({ n: entry[p], sp, c: cy, w: 0 });
};
const oi2 = emu.cpu.instruction;
emu.cpu.instruction = function () {
  const p = emu.cpu.pc & 0xffff, op = rd(p);
  const r = oi2.call(this);
  const c = emu.cpu.vcycles || r || 0;
  global.PROF.cycAll = (global.PROF.cycAll || 0) + c;
  if (op === 0x76 || (p >= waitLo && p < waitHi)) for (const f of frames) f.w += c;
  return r;
};
let rnd = +(process.env.SEED || 12345); const rand = () => (rnd = (rnd * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff; let cur = 0, hold = 0, phase = 'title';
for (let frame = 0; frame < +(process.env.NF || 1500); frame++) {
  keys(0, 0);
  if (phase === 'title' && frame >= 8 && frame < 40) keys(7, 0x80);
  if (phase === 'menu') keys(2, 0x02);
  if (phase === 'match') { const x = rd(0x940d), y = rd(0x940e);
    if (hold-- <= 0) { hold = 5 + Math.floor(rand() * 30); cur = Math.floor(rand() * 7); }
    if (cur < 3) { if (x > 0x5a) keys(0, 0x10); else if (x < 0x50) keys(0, 0x40); else if (y > 0x0c) keys(0, 0x20); else keys(7, 0x80); }
    else { const m = [[0, 0x10], [0, 0x40], [0, 0x20], [7, 0x80]][cur - 3]; keys(m[0], m[1]); } }
  emu.v06c.oneFrame();
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  else if (phase === 'menu' && rd(0x0fed) === 1) { phase = 'match'; global.PROF.match = true; }
}
const out = { iters: global.PROF.iters };
for (const n of NAMES) out[n] = { calls: calls[n] || 0, per_call: calls[n] ? Math.round(tot[n] / calls[n]) : 0, per_iter: Math.round((tot[n] || 0) / Math.max(1, global.PROF.iters)) };
console.log(JSON.stringify(out));
