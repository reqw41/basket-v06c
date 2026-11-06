#!/usr/bin/env node
/**
 * Trace CALL/JP by hooking memory reads - logs when PC enters E/F000+ ranges.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = process.argv[2] || path.join(ROOT, 'build/v06/basket.rom');
const FRAMES = Number(process.argv[3] || 100);

// Browser stubs
global.window = global;
global.document = {
  createElement: () => fc(),
  getElementById: () => fc(),
};
function fcx() {
  return {
    createImageData: (w, h) => ({ data: new Uint8ClampedArray((w||1)*(h||1)*4), width: w, height: h }),
    putImageData: () => {}, drawImage: () => {}, getImageData: () => ({ data: new Uint8ClampedArray(4) }),
    fillRect: () => {}, save: () => {}, restore: () => {}, scale: () => {}, setTransform: () => {},
  };
}
function fc() {
  return { width: 0, height: 0, style: {}, getContext: () => fcx() };
}
global.requestAnimationFrame = () => 0;
global.setTimeout = () => 0;
global.print = () => {};
global.console.debug = () => {};

const g = {};
for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g;
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
const loadBase = file.length === 65536 ? 0 : 0x100;
for (let i = 0; i < file.length && loadBase + i < 0x10000; i++)
  memory.write(loadBase + i, file[i], false);
if (memory.detach_boot) memory.detach_boot();
// Absolute memory image for static scans
const rom = new Uint8Array(65536);
for (let a = 0; a < 65536; a++) rom[a] = memory.read(a, false);

cpu.pc = 0x0100;
cpu.sp = 0x7f00;
cpu.iff = false;
timer.Write(3, 0x36);
timer.Write(3, 0x76);
timer.Write(3, 0xb6);

// Track bad PC entries by looking at the game's CALL instructions statically
// Scan ROM for CALL/JP to BIOS ranges
console.log('=== Static scan of CALL/JP targets ===');
const biosCallSites = [];
const biosJpSites = [];

for (let addr = 0x1000; addr < 0x6900; addr++) {
  const op = rom[addr];
  const b1 = rom[addr + 1] || 0;
  const b2 = rom[addr + 2] || 0;
  const target = b1 | (b2 << 8);
  
  // CALL nn (CD)
  if (op === 0xCD) {
    if ((target < 0x0200 && target >= 0x0020) || target >= 0xE000) {
      biosCallSites.push({ addr, target, type: 'CALL' });
    }
  }
  // CALL cc,nn (C4/CC/D4/DC/E4/EC/F4/FC)
  if ((op & 0xC7) === 0xC4) {
    if ((target < 0x0200 && target >= 0x0020) || target >= 0xE000) {
      biosCallSites.push({ addr, target, type: `CALL.${['NZ','Z','NC','C','PO','PE','P','M'][(op >> 3) & 7]}` });
    }
  }
  // JP nn (C3)
  if (op === 0xC3) {
    if ((target < 0x0200 && target >= 0x0020) || target >= 0xE000) {
      biosJpSites.push({ addr, target, type: 'JP' });
    }
  }
  // JP cc,nn (C2/CA/D2/DA/E2/EA/F2/FA)
  if ((op & 0xC7) === 0xC2) {
    if ((target < 0x0200 && target >= 0x0020) || target >= 0xE000) {
      biosJpSites.push({ addr, target, type: `JP.${['NZ','Z','NC','C','PO','PE','P','M'][(op >> 3) & 7]}` });
    }
  }
}

// Group by target
const targetMap = new Map();
for (const site of [...biosCallSites, ...biosJpSites]) {
  const entry = targetMap.get(site.target) || [];
  entry.push(site);
  targetMap.set(site.target, entry);
}

// Known stubs
const knownStubs = new Set([
  0x006C, 0x0090, 0x0093, 0x00A2, 0x00D5, 0x00D8, 0x0135, 0x0138, 0x0141, 0x0024,
  // Low RST handlers (covered by glue.asm)
  0x0000, 0x0008, 0x0010, 0x0018, 0x0020, 0x0028, 0x0030, 0x0038,
  // High stubs from build_v06_rom.py
  0xE702, 0xE64B, 0xE72B, 0xED0C, 0xED37, 0xED5B, 0xEFFF, 0xF001, 0xF111,
  0xF210, 0xF31F, 0xF35B, 0xF917, 0xFA32, 0xFE00, 0xFE2F, 0xFF00, 0xFF09,
  0xFF0F, 0xFF17, 0xFF18, 0xFF28, 0xFF80, 0xFFAB, 0xFFD7, 0xFFFF,
]);

// Sort by target address
const sorted = [...targetMap.entries()].sort((a, b) => a[0] - b[0]);

console.log('\n--- Low BIOS (0020-01FF) ---');
for (const [target, sites] of sorted) {
  if (target >= 0x0020 && target < 0x0200) {
    const stubbed = knownStubs.has(target) ? '✓' : '✗';
    const callers = sites.map(s => `${s.addr.toString(16)}(${s.type})`).join(', ');
    console.log(`  ${target.toString(16).padStart(4, '0')} [${stubbed}]: ${callers}`);
  }
}

console.log('\n--- High BIOS (E000-FFFF) ---');
for (const [target, sites] of sorted) {
  if (target >= 0xE000) {
    const stubbed = knownStubs.has(target) ? '✓' : '✗';
    const callers = sites.map(s => `${s.addr.toString(16)}(${s.type})`).join(', ');
    console.log(`  ${target.toString(16).padStart(4, '0')} [${stubbed}]: ${callers}`);
  }
}

// Also show targets in adapter range (0200-0FFF) that might be unrelocated internal calls
console.log('\n--- Adapter range calls (0200-0FFF) ---');
for (const [target, sites] of sorted) {
  if (target >= 0x0200 && target < 0x1000) {
    const callers = sites.map(s => `${s.addr.toString(16)}(${s.type})`).join(', ');
    console.log(`  ${target.toString(16).padStart(4, '0')}: ${callers}`);
  }
}

// Now run simulation and track SP
console.log('\n=== Running simulation ===');
const spSamples = [];
let frame = 0;

for (let f = 0; f < FRAMES; f++) {
  frame = f;
  v06c.oneFrame();
  const pc = cpu.pc & 0xffff;
  const sp = cpu.sp & 0xffff;
  
  spSamples.push({ frame: f, pc, sp });
  
  if (f % 25 === 0) {
    console.log(`frame ${f}: pc=${pc.toString(16).padStart(4,'0')} sp=${sp.toString(16).padStart(4,'0')}`);
  }
}

// Find SP anomalies
console.log('\n=== SP drift analysis ===');
let minSp = 0x7f00, maxSp = 0x7f00;
for (const s of spSamples) {
  if (s.sp < minSp) minSp = s.sp;
  if (s.sp > maxSp) maxSp = s.sp;
}
console.log(`SP range: ${minSp.toString(16)} - ${maxSp.toString(16)} (delta ${maxSp - minSp})`);

// Check final PC distribution
console.log('\nFinal PC:', (cpu.pc & 0xffff).toString(16));
console.log('Final SP:', (cpu.sp & 0xffff).toString(16));

// Dump VDP state
const vdpRegs = [];
for (let i = 0; i < 8; i++) vdpRegs.push(memory.read(0x0f00 + i, false).toString(16).padStart(2, '0'));
console.log('VDP regs:', vdpRegs.join(' '));

// Check nametable
let ntNz = 0;
for (let a = 0x9800; a < 0x9b00; a++) {
  if (memory.read(a, false)) ntNz++;
}
console.log(`Nametable non-zero: ${ntNz}/768`);
