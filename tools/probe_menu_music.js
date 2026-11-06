#!/usr/bin/env node
/** Menu music pace: note writes / WRTPSG vs frame time. */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

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
g.console = { log: () => {}, debug: () => {}, error: console.error, warn: () => {} };
const ctx = vm.createContext(g);
for (const f of [
  'i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js',
  'src/fili.js', 'src/ay.js', 'src/fd1793.js', 'src/fddimage.js', 'src/i8253.js',
  'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  'Z80_v06.js', 'z80_adapter.js',
]) vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

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
for (let i = 0; i < file.length; i++) memory.write(0x100 + i, file[i], false);
for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
let st = cpu.getState();
Object.assign(st, { pc: 0x100, sp: 0xe000, iff1: 0, iff2: 0, halted: false, imode: 1 });
cpu.setState(st); cpu.pc = 0x100; cpu.sp = 0xe000;
timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);

const rd = (a) => memory.read(a & 0xffff, false);
const keys = (r, m) => { for (let i = 0; i < 8; i++) keyboard.matrix[i] = 0; if (m) keyboard.matrix[r] = m; };

// BIOS WRTPSG at 0093 → jp BIOS_WRTPSG; hook the jp target entry
const wrtpsg = 0x0093;
const sndTick = (() => {
  const t = fs.readFileSync(path.join(ROOT, 'build/v06/glue.lst'), 'utf8');
  const m = t.match(/^V_SND_TICK\s*=\s*\$([0-9A-Fa-f]+)/m);
  return m ? parseInt(m[1], 16) : 0x0787;
})();
const musicPlayer = 0xab28;

let frame = 0;
const bins = []; // per 30-frame window after menu
let wrt = 0;
let ticks = 0;
let music = 0;
let periodWrites = 0;
let lastDiv = [0, 0, 0];

const oi = cpu.instruction.bind(cpu);
cpu.instruction = function () {
  const pc = this.pc & 0xffff;
  if (pc === wrtpsg) {
    st = cpu.getState();
    wrt++;
    const reg = st.a & 0x0f;
    if (reg <= 5) periodWrites++;
  }
  if (pc === sndTick) ticks++;
  if (pc === musicPlayer) music++;
  return oi();
};

let phase = 'title';
let menuAt = -1;
for (frame = 0; frame < 400; frame++) {
  keys(0, 0);
  if (phase === 'title' && frame >= 8 && frame < 100) keys(7, 0x80);
  // stay on menu: no match start
  v06c.oneFrame();
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) {
    phase = 'menu';
    menuAt = frame;
    console.log('menu@', frame);
  }
  if (phase === 'menu' && menuAt >= 0 && (frame - menuAt) % 30 === 0 && frame > menuAt) {
    const divs = [0, 1, 2].map((ch) => rd(0x0f40 + ch * 2) | (rd(0x0f41 + ch * 2) << 8));
    bins.push({
      f: frame - menuAt,
      wrt,
      ticks,
      music,
      periodWrites,
      dirty: rd(0xf80),
      fee: rd(0xfee),
      fef: rd(0xfef),
      divs,
    });
    wrt = 0;
    ticks = 0;
    music = 0;
    periodWrites = 0;
  }
  if (phase === 'menu' && frame - menuAt > 240) break;
}

console.log(JSON.stringify(bins, null, 2));
const rates = bins.map((b) => b.periodWrites);
console.log(
  'periodWrites/30f:',
  rates.join(','),
  'ratio late/early',
  rates.length > 2 ? (rates[rates.length - 1] / Math.max(1, rates[1])).toFixed(2) : 'n/a'
);
console.log(
  'WRTPSG/30f:',
  bins.map((b) => b.wrt).join(','),
  'V_SND_TICK/30f:',
  bins.map((b) => b.ticks).join(','),
  'music/30f:',
  bins.map((b) => b.music).join(',')
);
