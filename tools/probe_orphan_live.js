#!/usr/bin/env node
/** Trace ORPHAN_PREFIX_RESTORE → DIRTY_RESTORE during match. */
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

const log = [];
let traceOrphan = false;
const oi = cpu.instruction.bind(cpu);
cpu.instruction = function () {
  st = cpu.getState();
  const pc = st.pc & 0xffff;
  if (traceOrphan && pc >= 0x1480 && pc <= 0x14e0) {
    log.push({
      ev: 'pc',
      pc: pc.toString(16),
      a: st.a & 255,
      b: st.b & 255,
      c: st.c & 255,
      sp: st.sp & 0xffff,
    });
  }
  if (traceOrphan && (pc < 0x1480 || pc > 0x14e0) && pc !== 0x04a4) {
    log.push({ ev: 'left', pc: pc.toString(16), a: st.a & 255, b: st.b & 255, c: st.c & 255, sp: st.sp & 0xffff });
    traceOrphan = false;
  }
  if (pc === 0x1480) {
    if (rd(0xb258) > rd(0xf80)) traceOrphan = true;
    const oc = rd(0xb258);
    const nc = rd(0xf80);
    const old = [];
    for (let i = 0; i < oc; i++) {
      const b = 0xb259 + i * 4;
      old.push({ i, col: rd(b), row: rd(b + 1), w: rd(b + 2), h: rd(b + 3) });
    }
    const code = [];
    for (let a = 0x1764; a < 0x17a1; a++) code.push(rd(a).toString(16).padStart(2, '0'));
    log.push({
      ev: 'orphanEnter',
      oc,
      nc,
      rows: rd(0xf5f),
      fee: rd(0xfee),
      iff: st.iff1,
      f80: rd(0xf80),
      code: code.join(''),
      old,
    });
  }
  // Early exits / key points inside orphan
  if (pc === 0x1768) log.push({ ev: 'retZ_fee', a: st.a & 255, flags: st.flags, f: st.f });
  if (pc === 0x176e) log.push({ ev: 'retC_old', a: st.a & 255, flags: st.flags, f: st.f, cy: !!(st.f & 1), cy2: !!(st.flags & 1) });
  if (pc === 0x176f) log.push({ ev: 'afterRetC', a: st.a & 255 });
  if (pc === 0x1781) log.push({ ev: 'retZ_diff', a: st.a & 255, b: st.b & 255, c: st.c & 255, f: st.f });
  if (pc === 0x1782) log.push({ ev: 'retC_diff', a: st.a & 255, b: st.b & 255, c: st.c & 255, f: st.f });
  if (pc === 0x1783) log.push({ ev: 'doRestore', a: st.a & 255, b: st.b & 255, c: st.c & 255 });
  if (pc === 0x04a4) {
    st = cpu.getState();
    log.push({
      ev: 'restore',
      a: st.a & 255,
      ix: (st.ix & 0xffff).toString(16),
      oc: rd(0xb258),
      nc: rd(0xf80),
    });
  }
  if (pc === 0x17a0) log.push({ ev: 'orphanRet' });
  return oi();
};

let phase = 'title';
let matchAt = -1;
for (let f = 0; f < 450; f++) {
  keys(0, 0);
  if (phase === 'title' && f >= 8 && f < 100) keys(7, 0x80);
  if (phase === 'menu') keys(2, 0x02);
  if (phase === 'match' && f - matchAt > 40 && f - matchAt < 220) keys(4, 0x20);
  v06c.oneFrame();
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  if (phase === 'menu' && rd(0xfef) === 0 && rd(0xfed) === 1) {
    matchAt = f;
    phase = 'match';
  }
  if (phase === 'match' && f - matchAt > 280) break;
}

const shrink = log.filter((x) => x.ev === 'orphanEnter' && x.oc > x.nc);
console.log('shrink enters', shrink.length);
if (shrink.length) {
  const idx = log.indexOf(shrink[0]);
  const slice = log.slice(idx, idx + 40);
  for (const e of slice) console.log(JSON.stringify(e));
}
console.log('restore a>1', JSON.stringify(log.filter((x) => x.ev === 'restore' && x.a > 1)));
