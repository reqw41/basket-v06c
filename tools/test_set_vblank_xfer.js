#!/usr/bin/env node
/**
 * Retired SET_VBLANK slot (A524) and the moved BIOS_CLICK, vs the etalon ROM.
 *   node tools/test_set_vblank_xfer.js
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const NEW = path.join(ROOT, 'build/v06/basket.rom');
const OLD = path.join(ROOT, 'build/v06/basket-etalon-54d6ee2d.rom');
const OLD_SLOT = 0x0665;
const NEW_SLOT = 0xA524;
const CLICK_OLD = 0x02A9;
const CLICK_NEW = 0xA52C;

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
]) {
  vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
}
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
  v06c.displayFrame = () => {};
  v06c.dbg = null;
  v06c.check_breakpoint = () => false;
  const file = new Uint8Array(fs.readFileSync(romPath));
  const base = file.length === 65536 ? 0 : 0x100;
  for (let i = 0; i < file.length && base + i < 0x10000; i++) memory.write(base + i, file[i], false);
  if (base === 0x100) {
    for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
  }
  const st = cpu.getState();
  st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1;
  cpu.setState(st);
  cpu.pc = 0x0100;
  cpu.sp = 0xe000;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  return { memory, cpu, v06c };
}

function callProc(emu, addr, setup) {
  const { memory, cpu } = emu;
  const RET = 0x0ff8;
  memory.write(RET, 0xc9, false);
  memory.write(0xbfee, RET & 0xff, false);
  memory.write(0xbfef, RET >> 8, false);
  if (setup) setup(memory);
  const st = cpu.getState();
  st.pc = addr;
  st.sp = 0xbfee;
  st.a = 0x5a; st.b = 0x11; st.c = 0x22; st.d = 0x33; st.e = 0x44; st.h = 0x55; st.l = 0x66;
  st.iff1 = 1; st.iff2 = 1; st.halted = false; st.imode = 1;
  if (st.flags) {
    st.flags.S = 1; st.flags.Z = 0; st.flags.H = 1; st.flags.P = 0; st.flags.N = 1; st.flags.C = 1;
  }
  cpu.setState(st);
  cpu.pc = addr;
  cpu.sp = 0xbfee;
  let cycles = 0;
  let steps = 0;
  const limit = 1000;
  while ((cpu.pc & 0xffff) !== RET) {
    if (steps++ >= limit) return { ok: false, error: 'limit', steps, cycles };
    cycles += cpu.instruction() || 0;
  }
  const after = cpu.getState();
  return {
    ok: true,
    cycles,
    steps,
    sp: cpu.sp & 0xffff,
    status: memory.read(0x0f08, false),
    a: after.a, b: after.b, c: after.c, d: after.d, e: after.e, h: after.h, l: after.l,
    flags: after.flags ? { ...after.flags } : null,
    iff: after.iff1,
  };
}

let fails = 0;
function check(name, ok, detail) {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`);
  if (!ok) fails++;
}

// SET_VBLANK (MSX VDP status emulation) is retired with the soft VDP:
// A524..A52B is zero padding and neither slot runs; no RST 08/10/20/28.
const live = boot(NEW);
const hitNew = new Set();
const hitRst = new Set();
const oi = live.cpu.instruction.bind(live.cpu);
live.cpu.instruction = function () {
  const pc = live.cpu.pc & 0xffff;
  if (pc >= NEW_SLOT && pc < NEW_SLOT + 8) hitNew.add(pc);
  if (pc === 0x08 || pc === 0x10 || pc === 0x20 || pc === 0x28) hitRst.add(pc);
  return oi();
};
for (let f = 0; f < 30; f++) live.v06c.oneFrame();
const slot = fs.readFileSync(NEW).slice(NEW_SLOT - 0x100, NEW_SLOT - 0x100 + 8);
check('A524..A52B is zero padding', slot.every(x => x === 0), slot.toString('hex'));
check('IRQ never enters the retired A524 slot', hitNew.size === 0,
  [...hitNew].map(x => x.toString(16)).join(','));
check('no VDP RST in 30 frames', hitRst.size === 0, [...hitRst].map(x => x.toString(16)).join(','));

const image = fs.readFileSync(NEW);
function findSig(sig, from) {
  const hits = [];
  for (let i = from; i + sig.length <= image.length; i++) {
    let ok = true;
    for (let k = 0; k < sig.length; k++) if (image[i + k] !== sig[k]) { ok = false; break; }
    if (ok) hits.push(i + (image.length === 65280 ? 0x100 : 0));
  }
  return hits;
}
const vbSig = Buffer.from([0xE5, 0x21, 0x08, 0x0F, 0xCB, 0xFE, 0xE1, 0xC9]);
// i8080 BIOS_CLICK (win_a524.asm): cp 1 / sbc a,a / inc a / out (0),a / ret
const ckSig = Buffer.from([0xFE, 0x01, 0x9F, 0x3C, 0xD3, 0x00, 0xC9]);
const vbHits = findSig(vbSig, 0);
const ckHits = findSig(ckSig, 0);
check('no SET_VBLANK body left in the image', vbHits.length === 0, vbHits.map(x => x.toString(16)).join(','));
check('BIOS_CLICK bytes only at A52C', ckHits.length === 1 && ckHits[0] === CLICK_NEW, ckHits.map(x => x.toString(16)).join(','));

function callClick(rom, aIn) {
  const emu = boot(rom);
  const { memory, cpu } = emu;
  const RET = 0x0ff8;
  const addr = rom === NEW ? CLICK_NEW : CLICK_OLD;
  memory.write(RET, 0xc9, false);
  memory.write(0xbfee, RET & 0xff, false);
  memory.write(0xbfef, RET >> 8, false);
  const st = cpu.getState();
  st.pc = addr; st.sp = 0xbfee;
  st.a = aIn; st.b = 1; st.c = 2; st.d = 3; st.e = 4; st.h = 5; st.l = 6;
  st.iff1 = 1; st.halted = false;
  cpu.setState(st);
  cpu.pc = addr; cpu.sp = 0xbfee;
  let cycles = 0, steps = 0;
  while ((cpu.pc & 0xffff) !== RET) {
    if (steps++ > 20) return { ok: false, cycles };
    cycles += cpu.instruction() || 0;
  }
  return { ok: true, cycles, a: cpu.getState().a, sp: cpu.sp & 0xffff, bc: cpu.getState().b };
}
const c0 = callClick(OLD, 0);
const c1 = callClick(NEW, 0);
const d0 = callClick(OLD, 0x5a);
const d1 = callClick(NEW, 0x5a);
console.log(`click A=0 cycles ${c0.cycles}/${c1.cycles} A=${c0.a}/${c1.a}`);
console.log(`click A!=0 cycles ${d0.cycles}/${d1.cycles} A=${d0.a}/${d1.a}`);
// Same port value as the etalon; the i8080 body has no branch, so cycles differ.
check('click A=0 matches', c0.ok && c1.ok && c0.a === 0 && c1.a === 0, `${c0.cycles}/${c1.cycles}`);
check('click A!=0 matches', d0.ok && d1.ok && d0.a === 1 && d1.a === 1, `${d0.cycles}/${d1.cycles}`);
check('click preserves B', d1.bc === 1);

console.log(fails ? `\n${fails} FAILED` : '\nALL PASSED');
process.exit(fails ? 1 : 0);
