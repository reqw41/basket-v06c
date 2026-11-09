#!/usr/bin/env node
/**
 * Tempo of live play with the player running: Vector cycles per game
 * iteration, headless.
 *
 *   node tools/bench_play.js [rom]            Z80 image (build/v06/basket.rom)
 *   CPU=i8080 node tools/bench_play.js [rom]  i8080 image (build/i8080/basket-i8080.rom)
 *   N=150 (iterations measured), SKIP=10 (after the tip-off), JSON=1,
 *   PCDUMP=file: cycles by PC over the measured iterations (tools/prof_play.js)
 *
 * Inputs are given per game iteration, not per frame: at each entry to the
 * game loop 8554 player 1 gets the next cursor keys of a fixed plan (run
 * right, up, left, down; no fire), written to the keyboard matrix and to the
 * raw rows V_VROW that NATIVE_PADS reads in the same iteration. With the
 * deterministic RNG the game then walks the same states on any build, so two
 * builds compare cycle for cycle. `state` hashes the positions of both
 * players and the ball per iteration: equal hashes = the same scene.
 *
 * Only live play is measured: SKIP iterations after each tip-off (ball in
 * play, players apart) until N iterations; a basket (93D3, replay 93D1 or the
 * post-score wipe) pauses the count until the next tip-off, and the
 * iteration it falls into is dropped. Cycles are the
 * emulator's per-instruction cycles, so waits (HALT) count: cycles per
 * iteration = wall time. Hz = iterations per second of emulated time.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const I8080_IMAGE = process.env.CPU === 'i8080';
const ROM = path.resolve(process.argv[2] || path.join(ROOT, I8080_IMAGE ? 'build/i8080/basket-i8080.rom' : 'build/v06/basket.rom'));
const N = +(process.env.N || 150), SKIP = +(process.env.SKIP || 10);
const MAP = I8080_IMAGE ? JSON.parse(fs.readFileSync(path.join(ROOT, 'build/i8080/labels.json'))).map : null;
const at = (z) => (I8080_IMAGE ? parseInt(MAP[z], 16) : parseInt(z, 16));
const ITER = at('8554');
const WIPE = at('A0BF');

const g = {};
for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g;
const fcx = () => ({ createImageData: (w, h) => ({ data: new Uint8ClampedArray(4), width: 1, height: 1 }), putImageData() {}, drawImage() {},
  getImageData: () => ({ data: new Uint8ClampedArray(4) }), fillRect() {}, save() {}, restore() {}, scale() {}, setTransform() {} });
const fc = () => ({ width: 0, height: 0, style: {}, getContext: fcx });
g.document = { createElement: fc, getElementById: fc };
g.requestAnimationFrame = () => 0; g.setTimeout = () => 0; g.print = () => {};
g.console = { log: () => {}, debug: () => {}, error: console.error, warn: console.warn };
const ctx = vm.createContext(g);
for (const f of ['i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js', 'src/fili.js', 'src/ay.js', 'src/fd1793.js',
  'src/fddimage.js', 'src/i8253.js', 'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  ...(I8080_IMAGE ? [] : ['Z80_v06.js', 'z80_adapter.js'])])
  vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

const memory = new Memory(), keyboard = new Keyboard(), timer = new I8253(), ay = new AY(), floppy = new (Floppy().FD1793)();
const io = new IO(keyboard, timer, memory, ay, floppy); io.Palette = new Array(16).fill(0);
const tape = { advance() {}, sample: 0, reset() {}, stop() {}, sampleAt: () => 0 }; io.tape_player = tape;
const cpu = new I8080(memory, io), v06c = new Vector06c(cpu, memory, io, ay, tape);
v06c.tape_player = tape; v06c.bmp = new Uint32Array(576 * 288); v06c.displayFrame = () => {}; v06c.dbg = null; v06c.check_breakpoint = () => false;
const file = fs.readFileSync(ROM), base = file.length === 65536 ? 0 : 0x100;
for (let i = 0; i < file.length && base + i < 0x10000; i++) memory.write(base + i, file[i], false);
if (base) for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
if (!I8080_IMAGE) { const st = cpu.getState(); st.pc = 0x100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1; cpu.setState(st); }
cpu.pc = 0x100; cpu.sp = 0xe000;
timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
const rd = (a) => memory.read(a & 0xffff, false);
const wr = (a, v) => memory.write(a & 0xffff, v & 0xff, false);

// Player 1 plan, one entry per game iteration: Vector row 0 cursor masks.
const RIGHT = 0x40, LEFT = 0x10, UP = 0x20, DOWN = 0x80;
const PLAN = [];
for (const [m, n] of [[RIGHT, 14], [UP, 6], [LEFT, 14], [DOWN, 6], [RIGHT | UP, 8], [LEFT | DOWN, 8]]) for (let i = 0; i < n; i++) PLAN.push(m);
const V_VROW = 0x0F38;

let phase = 'title', k = -1, liveFrom = -1, inBasket = false, done = '';
let cyc = 0, iterStart = 0, frames = 0, totalCyc = 0, baskets = 0, lastLive = false;
const per = [], hash = crypto.createHash('sha256');
const pcc = process.env.PCDUMP ? new Float64Array(0x10000) : null;   // cycles by PC, live iterations only
const oi = cpu.instruction.bind(cpu);
const scoring = () => rd(0x93d3) || rd(0x93d1);
cpu.instruction = function () {
  const pc = cpu.pc & 0xffff;
  if (phase === 'play' && pc === ITER) {
    // the iteration that just ended counts if it was live from start to end
    if (lastLive && !inBasket) { per.push(cyc - iterStart); if (per.length >= N) done = 'n'; }
    k++;
    const mask = PLAN[k % PLAN.length];
    keyboard.matrix[0] = mask;
    wr(V_VROW, (~mask) & 0xff);
    const p1 = [rd(0x940d), rd(0x940e)], p2 = [rd(0x9427), rd(0x9428)], ball = rd(0x93f3);
    if (inBasket && !scoring()) { inBasket = false; liveFrom = -1; }
    if (!inBasket && liveFrom < 0 && ball && p1[0] && p2[0] && p1[0] !== p2[0] && p1[0] !== 0x6e) liveFrom = k + SKIP;
    lastLive = !inBasket && liveFrom >= 0 && k >= liveFrom;
    if (lastLive) hash.update(Buffer.from([...p1, ...p2, ball]));
    iterStart = cyc;
  }
  if (phase === 'play' && !inBasket && (pc === WIPE || scoring())) { inBasket = true; baskets++; lastLive = false; }
  const r = oi();
  const c = cpu.vcycles || r || 0;
  cyc += c; totalCyc += c;
  if (pcc && lastLive && !inBasket) pcc[pc] += c;
  return r;
};
for (let frame = 0; frame < 60000 && !done; frame++) {
  if (phase !== 'play') {
    for (let i = 0; i < 8; i++) keyboard.matrix[i] = 0;
    if (phase === 'title' && frame >= 8 && frame < 40) keyboard.matrix[7] = 0x80;
    if (phase === 'menu') keyboard.matrix[2] = 0x02;   // 1 PLAYER
  }
  v06c.oneFrame(); frames++;
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  else if (phase === 'menu' && rd(0x0fed) === 1) phase = 'play';
}
const cpf = totalCyc / frames;                   // cycles of one hardware frame
const hz = 3000000 / 59904;
const mean = per.reduce((a, b) => a + b, 0) / (per.length || 1);
const sorted = [...per].sort((a, b) => a - b);
const res = { cpu: I8080_IMAGE ? 'i8080' : 'z80', rom: path.basename(ROM), iterations: per.length, baskets, stop: done || 'frames',
  cyclesPerIter: Math.round(mean), medianCycles: sorted[sorted.length >> 1] || 0, framesPerIter: +(mean / cpf).toFixed(3),
  hz: +(hz * cpf / mean).toFixed(3), state: hash.digest('hex').slice(0, 16) };
if (process.env.JSON) res.perIter = per;
if (pcc) fs.writeFileSync(process.env.PCDUMP, JSON.stringify({ iters: per.length, pc: Array.from(pcc) }));
process.stdout.write(JSON.stringify(res) + '\n');
if (per.length < 30) process.exitCode = 1;
