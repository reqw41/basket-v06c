#!/usr/bin/env node
/**
 * Fixed controls (joy_p.asm NATIVE_PADS), headless:
 *   1 PLAYER:  joystick «П», cursor keys and SPACE steer player 1;
 *   2 PLAYERS: joystick «П» = player 1, cursor keys + SPACE = player 2;
 *   ВК pauses (match clock stands), a key resumes, АР2 in the pause leaves;
 *   the old letter keys (1 Q D F Z) steer nobody.
 * Checks the control bytes PAD_P1/PAD_P2 (AC4D/AC4E: up 01, down 03,
 * left 04, right 0C, fire 10) and that player 1 really walks.
 *   node tools/test_joy_p.js [path/to.rom]     JOYDEAD=1: port 6 silent (negative control)
 *   CPU=i8080 node tools/test_joy_p.js build/i8080/basket-i8080.rom   the i8080 image
 * Does not write PC, SP, or game flags. Keyboard and port 6 only.
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
  ...(process.env.CPU === 'i8080' ? [] : ['Z80_v06.js', 'z80_adapter.js']),
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
  if (process.env.CPU !== 'i8080') {        // CPU=i8080: the recompiled image on the i8080 core
    const st = cpu.getState();
    st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1;
    cpu.setState(st);
  }
  cpu.pc = 0x0100; cpu.sp = 0xe000;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  const exec = new Uint8Array(0x10000);
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () { exec[cpu.pc & 0xffff] = 1; return oi(); };
  return { memory, keyboard, cpu, v06c, exec, io };
}

let emu, rd, joy = 0;
function start(players) {
  emu = boot();
  rd = a => emu.memory.read(a & 0xffff, false);
  joy = 0;
  const ioIn = emu.io.input.bind(emu.io);
  emu.io.input = p => ((p & 0xff) === 6 ? (process.env.JOYDEAD === '1' ? 0xff : (~joy) & 0xff) : ioIn(p));
  let phase = 'title';
  for (let frame = 0; frame < 2000 && phase !== 'match'; frame++) {
    clear();
    if (phase === 'title' && frame >= 8 && frame < 40) emu.keyboard.matrix[7] = 0x80;
    if (phase === 'menu') emu.keyboard.matrix[2] = players === 1 ? 0x02 : 0x04;   // digit 1 / 2
    emu.v06c.oneFrame();
    if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
    else if (phase === 'menu' && rd(0x0fed) === 1) phase = 'match';
  }
  if (phase !== 'match') { console.log(`FAIL: no match (${players}P)`); process.exit(1); }
  if ((rd(0x93ea) !== 0) !== (players === 1)) { console.log(`FAIL: menu did not choose ${players}P`); process.exit(1); }
  clear(); for (let i = 0; i < 150; i++) emu.v06c.oneFrame();
}
const clear = () => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; joy = 0; };
const PAD = [0xac4d, 0xac4e];
const hex = v => v.toString(16).padStart(2, '0');
const match = (got, want) => want.every((w, i) => w === null || got[i] === w);
let fail = 0;
function pads(name, press, want) {
  clear(); press();
  let got = null;
  for (let i = 0; i < 30; i++) {             // the game reads once per game frame
    emu.v06c.oneFrame(); got = PAD.map(rd);
    if (match(got, want)) break;
  }
  const ok = match(got, want);
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}: P1 ${hex(got[0])} P2 ${hex(got[1])} (want ${want.map(w => w === null ? '--' : hex(w)).join(' ')})`);
  if (!ok) fail++;
}
const J = v => () => { joy = v; };
const K = (row, m) => () => { emu.keyboard.matrix[row] = m; };
const LETTERS = [['1', 2, 0x02], ['Q', 6, 0x02], ['D', 4, 0x10], ['F', 4, 0x40], ['Z', 7, 0x04]];

// --- one player ---
start(1);
for (const [name, press, v] of [
  ['joy up', J(0x04), 0x01], ['joy down', J(0x08), 0x03], ['joy left', J(0x02), 0x04], ['joy right', J(0x01), 0x0c],
  ['joy fire 1', J(0x40), 0x10], ['joy fire 2', J(0x80), 0x10], ['joy up+down', J(0x0c), 0x00],
  ['cursor up', K(0, 0x20), 0x01], ['cursor down', K(0, 0x80), 0x03], ['cursor left', K(0, 0x10), 0x04],
  ['cursor right', K(0, 0x40), 0x0c], ['space', K(7, 0x80), 0x10],
]) pads(`1P ${name}`, press, [v, null]);
for (const [k, row, m] of LETTERS) pads(`1P letter ${k} steers nobody`, K(row, m), [0x00, null]);
// Integration: player 1 walks with the joystick and the cursor keys (940E is
// the court axis), and no longer with the letters.
function walk(press, n) { const x0 = rd(0x940e); for (let i = 0; i < n; i++) { clear(); press(); emu.v06c.oneFrame(); } return rd(0x940e) - x0; }
{
  let ready = false;                         // tip-off / after a score: steering ignored
  for (let i = 0; i < 600 && !ready; i += 20) {
    const x0 = rd(0x940e);
    for (let k = 0; k < 20; k++) { clear(); joy = (i / 20) & 1 ? 0x02 : 0x01; emu.v06c.oneFrame(); }
    ready = rd(0x940e) !== x0;
  }
  if (!ready) { console.log('FAIL warm-up: player 1 never moved'); process.exit(1); }
}
for (const [name, press, sign] of [
  ['joy right', J(0x01), +1], ['joy left', J(0x02), -1],
  ['cursor right', K(0, 0x40), +1], ['cursor left', K(0, 0x10), -1],
]) {
  const dx = walk(press, 60);
  const ok = Math.sign(dx) === sign;
  console.log(`${ok ? 'ok  ' : 'FAIL'} 1P walk ${name}: dx=${dx}`);
  if (!ok) fail++;
}

// --- two players ---
start(2);
for (const [name, press, want] of [
  ['joy up', J(0x04), [0x01, 0x00]], ['joy right', J(0x01), [0x0c, 0x00]], ['joy fire', J(0x40), [0x10, 0x00]],
  ['cursor up', K(0, 0x20), [0x00, 0x01]], ['cursor down', K(0, 0x80), [0x00, 0x03]],
  ['cursor left', K(0, 0x10), [0x00, 0x04]], ['cursor right', K(0, 0x40), [0x00, 0x0c]],
  ['space', K(7, 0x80), [0x00, 0x10]],
]) pads(`2P ${name}`, press, want);
for (const [k, row, m] of LETTERS) pads(`2P letter ${k} steers nobody`, K(row, m), [0x00, 0x00]);

// --- pause: ВК pauses (match clock 4111 stops), a key resumes, ВК + АР2 leaves ---
function frames(n, press) { for (let i = 0; i < n; i++) { clear(); if (press) press(); emu.v06c.oneFrame(); } }
const clock = () => rd(0x4111) | rd(0x4112) << 8;
function check(name, ok, info) { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${info ? ': ' + info : ''}`); if (!ok) fail++; }
{
  frames(12, K(0, 0x04)); frames(20);                         // ВК held over a game iteration (~8 frames on the i8080)
  const c0 = clock(); frames(100); const c1 = clock();
  check('ВК pauses (match clock stands)', c1 === c0, `clock ${c0} -> ${c1}`);
  check('pause keeps the match', rd(0x0fed) === 1);
  frames(6, K(7, 0x80)); frames(20);                          // SPACE resumes
  const c2 = clock(); frames(100); const c3 = clock();
  check('a key resumes', c3 !== c2, `clock ${c2} -> ${c3}`);
  frames(12, K(0, 0x04)); frames(20);                         // ВК again
  frames(6, K(1, 0x04));                                      // АР2 in the pause
  let left = false;
  for (let i = 0; i < 300 && !left; i++) { frames(1); left = rd(0x0fed) !== 1; }
  check('АР2 in the pause leaves the match', left);
}
console.log(fail ? `JOY_P_FAIL ${fail}` : 'JOY_P_PASS');
process.exit(fail ? 1 : 0);
