#!/usr/bin/env node
/**
 * Game-flow checks driven by the real control paths, on one ROM.
 *   node tools/test_game_flow.js path/to.rom
 *
 * Does not write PC, SP, or game flags. Keyboard only.
 * Replay: steer into the dunk window (8F0F) so the game sets 93D3 and,
 * on a type-4 score (9400 & 7 == 4), enters A82C by itself.
 * Menu exit: the game wants SHIFT+CTRL+ESC (L_8685 / D5DE).
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
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () { exec[cpu.pc & 0xffff] = 1; return oi(); };
  return { memory, keyboard, cpu, v06c, exec };
}

const emu = boot();
const rd = a => emu.memory.read(a & 0xffff, false);
const keys = (row, mask) => {
  for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0;
  if (mask) emu.keyboard.matrix[row] = mask;
};

let phase = 'title';
let frame = 0;
let matchAt = 0;
const cal = process.argv.includes('--cal');
const maxFrames = cal ? 900 : 4500;
let saw93d3 = 0;
let sawType4 = false;
let enteredZoom = false;
let replayEnded = false;
let spAtReplayEnd = null;
let hudSample = null;
let continued = false;
const zoomLo = 0x0867; // may move; also watch A8F4
let row6Stuck = null;

for (; frame < maxFrames; frame++) {
  keys(0, 0);
  if (phase === 'title' && frame >= 8 && frame < 40) keys(7, 0x80);
  if (phase === 'menu') keys(2, 0x02);
  if (phase === 'match') {
    const x = rd(0x940d);
    const y = rd(0x940e);
    const age = frame - matchAt;
    if (cal) {
      const slot = Math.floor(age / 40) % 5;
      const masks = [0x10, 0x40, 0x20, 0x80, 0];
      const rows = [0, 0, 0, 0, 7];
      if (slot === 4) keys(7, 0x80);
      else keys(0, masks[slot]);
      if (age % 40 === 39) {
        console.log(`cal slot ${slot} x=${x} y=${y} f=${rd(0x940c).toString(16)} x2=${rd(0x9427)} y2=${rd(0x9428)} f2=${rd(0x9426).toString(16)} j=${rd(0x9415)}`);
      }
    } else if (x > 0x5a) keys(0, 0x10);      // cursor left
    else if (x < 0x50) keys(0, 0x40);         // cursor right
    else if (y > 0x0c) keys(0, 0x20);         // cursor up
    else keys(7, 0x80);                       // SPACE: fire
    if (!cal && (frame % 60) === 0) {
      console.log(`f${frame} x=${x} y=${y} d3=${rd(0x93d3)} p400=${rd(0x9400).toString(16)} pc=${(emu.cpu.pc & 0xffff).toString(16)}`);
    }
  }
  emu.v06c.oneFrame();
  const matchMode = rd(0x0fed);
  const y1 = rd(0x940d), y2 = rd(0x9427);
  if (phase === 'title' && y1 === 0x6e && y2 === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  else if (phase === 'menu' && matchMode === 1) {
    phase = 'match';
    matchAt = frame;
    console.log(`match@${frame} x=${y1} axis2=${rd(0x940e)}`);
  }
  if (phase === 'match') {
    const d3 = rd(0x93d3);
    if (d3 > saw93d3) { saw93d3 = d3; console.log(`93D3=${d3} @${frame}`); }
    const sc = rd(0x9400) & 7;
    if (sc === 4 && !sawType4) { sawType4 = true; console.log(`type4 @${frame} d3=${rd(0x93d3)}`); }
    if (emu.exec[0xa8f4] || emu.exec[zoomLo]) {
      if (!enteredZoom) console.log(`zoom entry @${frame} d1=${rd(0x93d1)} d3=${rd(0x93d3)} sp=${(emu.cpu.sp & 0xffff).toString(16)}`);
      enteredZoom = true;
    }
    if (enteredZoom && rd(0x93d1) === 0 && !replayEnded) {
      replayEnded = true;
      spAtReplayEnd = emu.cpu.sp & 0xffff;
      hudSample = rd(0xe020);
      console.log(`replay end @${frame} sp=${spAtReplayEnd.toString(16)} hud0=${hudSample.toString(16)} x=${rd(0x940d)}`);
    }
    if (replayEnded && frame > 0 && rd(0x93d1) === 0 && rd(0x0fed) === 1) continued = true;
  }
  if (replayEnded && frame > 0 && continued && frame % 50 === 0) break;
}

// Verify the physical Vector modifiers and AP2 become the MSX exit chord.
keys(0, 0);
emu.keyboard.ss = true;
emu.keyboard.us = true;
emu.keyboard.matrix[1] = 0x04;
// Held like a person would: the IRQ scan can miss a frame that runs DI.
let row7Chord = 0xff, exitChordMapped = false;
for (let i = 0; i < 10 && !exitChordMapped; i++) {
  emu.v06c.oneFrame();
  row6Stuck = rd(0x0f26);
  row7Chord = rd(0x0f27);
  exitChordMapped = (row6Stuck & 0x03) === 0 && (row7Chord & 0x04) === 0;
}
const sha = crypto.createHash('sha256').update(fs.readFileSync(ROM)).digest('hex').slice(0, 16);
const report = {
  rom: sha,
  frames: frame,
  phase,
  saw93d3,
  sawType4,
  enteredZoom,
  replayEnded,
  spAtReplayEnd,
  continued,
  row6: row6Stuck,
  row7: row7Chord,
  exitChordMapped,
};
console.log(JSON.stringify(report));
process.exit(enteredZoom && replayEnded && continued && exitChordMapped ? 0 : 1);
