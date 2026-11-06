#!/usr/bin/env node
/**
 * Port side of the MSX lockstep (tools/msx_lockstep.py drives it).
 *   node tools/port_lockstep.js <rom> <plan.json> <out.bin>   env CPU=z80|i8080
 * Title SPACE, menu "1", then at every game iteration (8554, its i8080
 * image on the i8080 core) during the match: the keys of plan.keys[k] go
 * into the Vector matrix and straight into the MSX shadow rows (so the game
 * sees them in this iteration, as on the MSX), and the state regions are
 * dumped in MSX coordinates. At the first match iteration the RNG state
 * 4114 is taken from plan.seed (the menu time differs between machines).
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


const PLAN = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const OUT = process.argv[4];
const emu = boot();
const rd = a => emu.memory.read(a & 0xffff, false);
const wr = (a, v) => emu.memory.write(a & 0xffff, v & 0xff, false);
const kb = (rows) => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; for (const [r, m] of rows) emu.keyboard.matrix[r] |= m; };
// key -> [vector row, mask], [msx row, mask]
// [Vector matrix row, mask] (fixed controls: cursor keys + SPACE), [MSX row, mask] (1 Q D F Z)
const V_VROW = 0x0F38;   // kbd.asm: raw Vector rows of the frame poll
const KEYS = { up: [[0, 0x20], [0, 0x02]], down: [[0, 0x80], [4, 0x40]], left: [[0, 0x10], [3, 0x02]],
  right: [[0, 0x40], [3, 0x08]], fire: [[7, 0x80], [5, 0x80]] };
const V_MSXROW = 0x0F20;
const REGIONS = PLAN.port_regions;          // [[portLo, len], ...] in MSX order
const dumps = [];
let k = -1, phase = 'title';
const RNG_PC = IS8080 ? parseInt(MAP.map['386E'], 16) : 0x386E;
const REVM = {}; if (IS8080) for (const [z, n] of Object.entries(MAP.map)) REVM[parseInt(n, 16)] = parseInt(z, 16);
const RNGLOG = [];
global.STEP = (p) => {
  if (process.env.RNGLOG && p === RNG_PC && k >= 0) {
    const sp = emu.cpu.sp & 0xffff; const ret = rd(sp) | rd(sp + 1) << 8;
    RNGLOG.push(`${k} ${(IS8080 ? (REVM[ret] ?? ret) : ret).toString(16)} ${(rd(0x4114) | rd(0x4115) << 8).toString(16)}`);
  }
  if (p !== ITER_PC || rd(0x0fed) !== 1) return;
  k++;
  if (k === 0) {
    // i8080: a word that already holds the recompiled image of the code
    // address the MSX has there is a code pointer: keep it.
    const at = new Map(PLAN.state.map(([a, v]) => [a, v]));
    const keep = new Set();
    if (IS8080) for (const [a, v] of at) {
      if (!at.has(a + 1)) continue;
      let w = v | at.get(a + 1) << 8; if (w >= 0xD09C && w < 0xDD18) w -= 0x9D98;
      const m = MAP.map[w.toString(16).toUpperCase().padStart(4, '0')];
      if (m && parseInt(m, 16) !== w && (rd(a) | rd(a + 1) << 8) === parseInt(m, 16)) { keep.add(a); keep.add(a + 1); }
    }
    for (const [a, v] of at) if (!keep.has(a)) wr(a, v);
    wr(0x4114, PLAN.seed & 0xff); wr(0x4115, PLAN.seed >> 8);
    if (keep.size) console.error('kept code pointers at', [...keep].filter((x, i) => i % 2 === 0).map((x) => x.toString(16)).join(' '));
  }
  if (k >= PLAN.keys.length) return;
  const keys = PLAN.keys[k];
  kb(keys.map((n) => KEYS[n][0]));
  for (let r = 0; r < 8; r++) {   // raw Vector rows as the frame poll would leave them:
    let v = 0xff;                 // NATIVE_PADS reads them in this iteration
    for (const n of keys) if (KEYS[n][0][0] === r) v &= ~KEYS[n][0][1];
    wr(V_VROW + r, v);
  }
  for (let r = 0; r < 9; r++) {
    let v = 0xff; for (const n of keys) if (KEYS[n][1][0] === r) v &= ~KEYS[n][1][1];
    wr(V_MSXROW + r, v);
    wr(0x4104 + r, v);            // the game's IRQ key snapshot, as on the MSX side
  }
  const parts = REGIONS.map(([lo, n]) => { const b = Buffer.alloc(n); for (let i = 0; i < n; i++) b[i] = rd(lo + i); return b; });
  dumps.push(Buffer.concat(parts));
};
for (let frame = 0; frame < +(process.env.NF || 60000) && k < PLAN.keys.length; frame++) {
  global.FRAME = frame;
  if (phase === 'title') kb(frame % 300 >= 8 && frame % 300 < 40 ? [[7, 0x80]] : []);
  if (phase === 'menu') kb([[2, 0x02]]);
  emu.v06c.oneFrame();
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  else if (phase === 'menu' && rd(0x0fed) === 1) phase = 'match';
}
fs.writeFileSync(OUT, Buffer.concat(dumps));
if (process.env.RNGLOG) fs.writeFileSync(process.env.RNGLOG, RNGLOG.join('\n') + '\n');
if (process.env.ENDHIST) {
  const rev = {}; for (const [z, n] of Object.entries(MAP.map)) rev[parseInt(n, 16)] = z;
  const h = new Map(); const oi = emu.cpu.instruction.bind(emu.cpu);
  emu.cpu.instruction = function () { const pc = emu.cpu.pc & 0xffff; h.set(pc, (h.get(pc) || 0) + 1); return oi(); };
  for (let f = 0; f < 3; f++) emu.v06c.oneFrame();
  console.log([...h.entries()].sort((a, b) => b[1] - a[1]).slice(0, 25).map(([pc, n]) => `${pc.toString(16)}${IS8080 && rev[pc] ? '=Z' + rev[pc] : ''}:${n}`).join(' '));
}
console.log(JSON.stringify({ cpu: IS8080 ? 'i8080' : 'z80', iterations: dumps.length, frame: global.FRAME, pc: (emu.cpu.pc & 0xffff).toString(16), sp: (emu.cpu.sp & 0xffff).toString(16), mode: rd(0x0fed) }));
