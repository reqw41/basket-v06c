#!/usr/bin/env node
/**
 * i8080 image smoke run (headless vector06js, i8080 core; CPU=z80 for the
 * Z80 reference): node tools/run_i8080.js [rom]   env NF, SEED
 * Reports phases, game iterations, executed bytes of cleared Z80 code
 * (stale entries) and of the video planes. Former header:
 * Execution coverage for the disassembler (headless vector06js).
 *   node tools/collect_exec_v06.js [rom] out.bin     env SEED, NF, MODE=1p|2p
 * Random keyboard play from title through a match; writes a 64 KiB map,
 * non-zero = an instruction started there. PROF_OUT=file: per-PC counts and
 * cycles plus the number of game iterations (8554) during the match.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = path.resolve(process.argv[2] || path.join(ROOT, 'build/i8080/basket-i8080.rom'));
const MAP = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/i8080/labels.json'), 'utf8'));
const IS8080 = process.env.CPU !== "z80";
const ITER_PC = IS8080 ? parseInt(MAP.map['8554'], 16) : 0x8554;

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
  ...(process.env.CPU === 'z80' ? ['Z80_v06.js', 'z80_adapter.js'] : []),
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
  if (cpu.getState) {
    const st = cpu.getState();
    st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1;
    cpu.setState(st);
  } else { cpu.iff = false; }
  cpu.pc = 0x0100; cpu.sp = 0xe000;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  const exec = new Uint8Array(0x10000);
  const count = new Float64Array(0x10000), cyc = new Float64Array(0x10000);
  global.PROF = { count, cyc, iters: 0 };
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    const p = cpu.pc & 0xffff; exec[p] = 1; count[p]++;
    if (p === ITER_PC && global.PROF.match) global.PROF.iters++;   // game main-loop iteration
    if (global.STEP) global.STEP(p);
    if (global.HOOK && WATCH[p]) global.HOOK(p);
    const r = oi(); cyc[p] += cpu.vcycles || r || 0; return r; };
  return { memory, keyboard, cpu, v06c, exec };
}

const emu = boot();
const rd = a => emu.memory.read(a & 0xffff, false);
const keys = (row, mask) => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; if (mask) emu.keyboard.matrix[row] = mask; };
// Cleared Z80 code bytes that no i8080 span covers: executing one is a stale entry.
const stale = new Uint8Array(0x10000);
if (IS8080) {
  const used = new Uint8Array(0x10000);
  for (const [lo, hi] of MAP.used) for (let a = parseInt(lo, 16); a <= parseInt(hi, 16); a++) used[a] = 1;
  for (const [lo, hi] of MAP.data_fixed || []) for (let a = parseInt(lo, 16); a <= parseInt(hi, 16); a++) used[a] = 0;
  const z = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/v06/disasm_v06_code.json'), 'utf8'));
  for (const [lo, n] of z) for (let a = lo; a < lo + n; a++) if (!used[a]) stale[a] = 1;
}
const hits = new Map(); let firstStale = null, firstPlane = null;
const RING = new Uint32Array(512); let ri = 0; const SEEN = new Uint8Array(0x10000); const FIRSTS = [];
global.STEP = (p) => {
  RING[ri++ & 511] = p | ((emu.cpu.sp & 0xffff) << 16) | (emu.cpu.iff ? 0x8000 : 0) * 0;
  if (process.env.IFFLOG) { const f = !!emu.cpu.iff; if (f !== global.LASTIFF) { (global.IFFT = global.IFFT || []).push(p.toString(16) + (f ? '+EI' : '-DI')); if (global.IFFT.length > 40) global.IFFT.shift(); global.LASTIFF = f; } }
  if (process.env.FIRST && !SEEN[p]) { SEEN[p] = 1; FIRSTS.push(p); }
  if (stale[p] && !firstStale) firstStale = { pc: p, frame: global.FRAME, sp: emu.cpu.sp & 0xffff };
  if (p >= 0xC000 && !firstPlane) firstPlane = { pc: p, frame: global.FRAME };
  const sp = emu.cpu.sp & 0xffff;
  if (process.env.SPCHECK && global.PROF.boot && emu.cpu.iff && (sp > 0xC000 || sp < 0xB800) && !firstPlane) firstPlane = { pc: p, frame: global.FRAME, why: 'sp ' + sp.toString(16) };
  if (p === parseInt(MAP.map['84D0'], 16)) global.PROF.boot = true;
};
let rnd = +(process.env.SEED || 12345); const rand = () => (rnd = (rnd * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff; let cur = 0, hold = 0, phase = 'title';
const phases = {};
for (let frame = 0; frame < +(process.env.NF || 3000); frame++) {
  global.FRAME = frame;
  keys(0, 0);
  if (phase === 'title' && frame >= 8 && frame < 40) keys(7, 0x80);
  if (phase === 'menu') keys(2, 0x02);
  if (phase === 'match') { const x = rd(0x940d), y = rd(0x940e);
    if (hold-- <= 0) { hold = 5 + Math.floor(rand() * 30); cur = Math.floor(rand() * 7); }
    if (cur < 3) { if (x > 0x5a) keys(0, 0x10); else if (x < 0x50) keys(0, 0x40); else if (y > 0x0c) keys(0, 0x20); else keys(7, 0x80); }
    else { const m = [[0, 0x10], [0, 0x40], [0, 0x20], [7, 0x80]][cur - 3]; keys(m[0], m[1]); } }
  emu.v06c.oneInterrupt(false);   // one TV frame (oneFrame skips frames by wall-clock time: not deterministic)
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) { phase = 'menu'; phases.menu = frame; }
  else if (phase === 'menu' && rd(0x0fed) === 1) { phase = 'match'; phases.match = frame; global.PROF.match = true; }
  if (process.env.DUMP && process.env.DUMP.split(',').map(Number).includes(frame)) {
    const lo = Buffer.alloc(0x2000), hi = Buffer.alloc(0x2000);
    for (let i = 0; i < 0x2000; i++) { lo[i] = rd(0xe000 + i); hi[i] = rd(0xc000 + i); }
    fs.writeFileSync(`${process.env.DUMP_DIR || '.'}/f${frame}-lo.bin`, lo); fs.writeFileSync(`${process.env.DUMP_DIR || '.'}/f${frame}-hi.bin`, hi);
  }
  if (firstStale || firstPlane) break;
}
const out = { cpu: IS8080 ? 'i8080' : 'z80', phases, iters: global.PROF.iters, pc: (emu.cpu.pc & 0xffff).toString(16),
  stale: firstStale && { pc: firstStale.pc.toString(16), frame: firstStale.frame, sp: firstStale.sp.toString(16) },
  plane: firstPlane && { pc: firstPlane.pc.toString(16), frame: firstPlane.frame } };
console.log(JSON.stringify(out));
if (process.env.IFFLOG) console.log((global.IFFT || []).join(' '));
if (process.env.FIRST) {
  const rev = {}; for (const [z, n] of Object.entries(MAP.map)) rev[parseInt(n, 16)] = 'Z_' + z;
  console.log(FIRSTS.map(p => p.toString(16) + (rev[p] ? '=' + rev[p] : '')).join(' '));
}
if (process.env.TRACE && (out.stale || out.plane)) {
  const rev = {}; for (const [z, n] of Object.entries(MAP.map)) rev[parseInt(n, 16)] = 'Z_' + z;
  let syms = {}; try { syms = require('./v06syms').SYMS; } catch (e) {}
  const name = {}; for (const [n, a] of Object.entries(syms)) if (!(a in name)) name[a] = n;
  const lines = [];
  for (let k = 0; k < 512; k++) { const v = RING[(ri + k) & 511]; const pc = v & 0xffff;
    lines.push(`${pc.toString(16).padStart(4, '0')} sp=${(v >>> 16).toString(16)} ${rev[pc] || name[pc] || ''}`); }
  console.log(lines.slice(-+(process.env.TRACE)).join('\n'));
}
if (process.argv[3]) fs.writeFileSync(process.argv[3], Buffer.from(emu.exec));
if (process.env.PROF_OUT) {
  const P = global.PROF, pc = {};
  for (let a = 0; a < 0x10000; a++) if (P.count[a]) pc[a] = [P.count[a], P.cyc[a]];
  fs.writeFileSync(process.env.PROF_OUT, JSON.stringify({ iters: P.iters, pc }));
}
process.exit(out.stale || out.plane || !out.iters ? 1 : 0);
