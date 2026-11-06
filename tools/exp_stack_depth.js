#!/usr/bin/env node
/**
 * Measure SP low-water during title→menu→1P match (keyboard only).
 * Reports min SP, depth from GAME_STACK (C000), IRQ nesting samples.
 * Does not modify the ROM. Unverified paths are listed in the JSON.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = path.resolve(process.argv[2] || path.join(ROOT, 'build/v06/basket.rom'));
const OUT = process.argv[3] ? path.resolve(process.argv[3]) : null;
const STACK_TOP = 0xc000;
const STACK_FLOOR = 0xbc00;

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
g.console = { log() {}, debug() {}, warn: console.warn, error: console.error };
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

const romBuf = fs.readFileSync(ROM);
const sha = crypto.createHash('sha256').update(romBuf).digest('hex');

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

const file = new Uint8Array(romBuf);
const base = file.length === 65536 ? 0 : 0x100;
for (let i = 0; i < file.length && base + i < 0x10000; i++) memory.write(base + i, file[i], false);
if (base === 0x100) {
  for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
}
{
  const st = cpu.getState();
  st.pc = 0x0100; st.sp = STACK_TOP; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 0;
  st.a = st.b = st.c = st.d = st.e = st.h = st.l = 0;
  cpu.setState(st);
  cpu.pc = 0x0100;
  cpu.sp = STACK_TOP;
  cpu.iff = false;
}
timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);

const rd = a => memory.read(a & 0xffff, false);
let minSp = STACK_TOP;
let maxDepth = 0;
let inIrq = false;
let irqEnterSp = 0;
let maxIrqExtra = 0;
let irqEntries = 0;
const oi = cpu.instruction.bind(cpu);
cpu.instruction = function () {
  const pc = cpu.pc & 0xffff;
  const spBefore = cpu.sp & 0xffff;
  if (pc === 0x0038 && !inIrq) {
    inIrq = true;
    irqEnterSp = spBefore;
    irqEntries++;
  }
  const r = oi();
  const sp = cpu.sp & 0xffff;
  if (sp < minSp) minSp = sp;
  const depth = (STACK_TOP - sp) & 0xffff;
  if (depth > maxDepth && depth < 0x8000) maxDepth = depth;
  if (inIrq) {
    const extra = (irqEnterSp - sp) & 0xffff;
    if (extra < 0x8000 && extra > maxIrqExtra) maxIrqExtra = extra;
    // IRQ done when we return to caller stack level
    if (sp >= irqEnterSp) inIrq = false;
  }
  return r;
};

let phase = 'title';
let frame = 0;
let matchStart = 0;
const digitMask = 0x02;
const clearKeys = () => { for (let i = 0; i < 8; i++) keyboard.matrix[i] = 0; };

for (; frame < 1200; frame++) {
  clearKeys();
  if (phase === 'title' && frame >= 8 && frame < 40) keyboard.matrix[7] = 0x80;
  if (phase === 'menu') keyboard.matrix[2] = digitMask;
  if (phase === 'match' || phase === 'ready') {
    const step = Math.floor((frame - matchStart) / 40) % 6;
    if (step === 0) keyboard.matrix[0] = 0x20;
    else if (step === 1) keyboard.matrix[0] = 0x40;
    else if (step === 2) keyboard.matrix[0] = 0x80;
    else if (step === 3) keyboard.matrix[0] = 0x10;
    else if (step === 4) keyboard.matrix[7] = 0x80;
    else keyboard.matrix[0] = 0x40;
  }
  v06c.oneFrame();
  const y1 = rd(0x940d), y2 = rd(0x9427), ball = rd(0x93f3);
  const matchMode = rd(0x0fed);
  if (phase === 'title' && y1 === 0x6e && y2 === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  else if (phase === 'menu' && matchMode === 1) { phase = 'match'; matchStart = frame; }
  else if (phase === 'match' && ball && y1 && y2 && y1 !== y2 && y1 !== 0x6e) phase = 'ready';
  if (phase === 'ready' && frame > matchStart + 200) break;
}

const report = {
  rom_sha256: sha,
  scenario: 'title_menu_1p_ready',
  frames: frame,
  phase,
  stack_top: STACK_TOP,
  stack_floor_current: STACK_FLOOR,
  stack_capacity_current: STACK_TOP - STACK_FLOOR,
  stack_capacity_target: 1024,
  min_sp: minSp,
  max_depth_bytes: maxDepth,
  headroom_current: minSp - STACK_FLOOR,
  headroom_target_1024: 1024 - maxDepth,
  irq_entries: irqEntries,
  max_irq_extra_bytes: maxIrqExtra,
  unverified_paths: [
    "natural dunk replay (match_replay FAIL on full profile)",
    "ESC→menu (match_1p_esc FAIL)",
    "2P simultaneous input",
    "nested IRQ while already in IRQ (iff gating assumed)",
    "SP-based blit experiments must not borrow this stack budget",
  ],
  note: "Depth sampled every instruction on one 1P path only.",
};

const text = JSON.stringify(report, null, 2);
if (OUT) fs.writeFileSync(OUT, text + '\n');
console.log(
  `stack: phase=${phase} frames=${frame} minSP=${minSp.toString(16)} ` +
  `depth=${maxDepth} headroom_cur=${report.headroom_current} ` +
  `irqExtraMax=${maxIrqExtra} irqEntries=${irqEntries}`
);
console.log(text);
