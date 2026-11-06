#!/usr/bin/env node
/**
 * Regression: moving player body/head pairs must reach the visible planes whole.
 * Boots through the real title/menu path and drives the player from the keyboard.
 *
 * Original harness context:
 *   node tools/test_game_flow.js path/to.rom
 *
 * Does not write PC, SP, or game flags. Keyboard only.
 * Replay: steer into the dunk window (8F0F) so the game sets 93D3 and,
 * on a type-4 score (9400 & 7 == 4), enters A82C by itself.
 * Menu exit: the game wants SHIFT+CTRL+ESC (L_8685 / D5DE).
 */
'use strict';
const fs = require('fs');
const { sym } = require('./v06syms');
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
  return { memory, keyboard, cpu, v06c, exec, io };
}

const emu = boot();
const write=emu.memory.write.bind(emu.memory);
emu.memory.write=function(a,v,...args){
  if((a>=0x2500&&a<0x3300)||(a>=0x1600&&a<0x1710))throw new Error(`write into static court at ${a.toString(16)}, PC ${emu.cpu.pc.toString(16)}`);
  return write(a,v,...args);
};
const rd = a => emu.memory.read(a & 0xffff, false);
// Runtime sprite bank: record address -> index (offset table at 7760).
const recordIndex = new Map();
for (let i = 0; i < 75; i++) recordIndex.set(0x415a + (rd(0x7760 + i * 2) | (rd(0x7761 + i * 2) << 8)), i);
const keys = (row, mask) => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; if (mask) emu.keyboard.matrix[row] = mask; };
// Observe staged source poses at the public frame end, before any output.
// The displayed raster must contain a complete recent pose, even if preparing
// its successor spans several hardware frames. Do not read VRAM for the check.
const poses = [[], []];
const instruction = emu.cpu.instruction.bind(emu.cpu);
let snapshots = 0, maxPairBytes = 0, unpaired = false, unpairedSkipped = 0, pairPending = false;
const staged = new Map();   // record,X,Y,rect -> staged pixels (unchanged objects are not restaged)
emu.cpu.instruction = function () {
  // Menu and match: at dp_compose STAGE_SLOTS has staged, from SS_BASE on,
  // every object a damage box touches (damage_publish.asm). The others
  // (bit 7 of the rectangle width) did not change and touch no box: their
  // pixels are the ones last staged for the same record, X and Y.
  const pc = this.pc & 65535;
  if (pc === sym('dp_compose') && (rd(0xfee) ? [5,6,7,8].includes(rd(0xf80)) : rd(0xf80) === 4)) {
    let src = rd(0xf76) | (rd(0xf77) << 8);
    const pair = [new Map(), new Map()];
    const foreground = new Set();
    const count = rd(0xf80);
    // Slots are in the game's draw order: players are records 0..61 of the
    // bank (hoops 62..71, ball 72..74), each a run of body+head; two players
    // drawn back to back make a run of four. Frames with a one-record pose
    // (a foul) are not pair frames.
    const owners = new Map(); let player = 0, run = [];
    const isPlayer = (slot) => { const a = 0xb2c5 + slot * 4, p = rd(a) | (rd(a + 1) << 8); return recordIndex.get(p) < 62; };
    for (let slot = 0; slot <= count; slot++) {
      if (slot < count && isPlayer(slot)) { run.push(slot); continue; }
      if (run.length === 2 || run.length === 4) for (let i = 0; i < run.length; i += 2) { owners.set(run[i], player); owners.set(run[i + 1], player); player++; }
      else if (run.length) player = 99;
      run = [];
    }
    // A one-record pose (shot, foul) is not staged as body+head pairs: no
    // pose to compare until the next pair frame.
    if (player !== 2) { if (rd(0xfee)) { unpaired = true; pairPending = false; } return instruction(); }
    pairPending = unpaired;     // checks resume once this pair frame is on the planes
    for (let slot = 0; slot < count; slot++) {
      const a = 0xf81 + slot * 4, x = rd(a) * 8, y = rd(a + 1) + 8;
      const w = rd(a + 2), h = rd(a + 3);
      const m = 0xb2c5 + slot * 4, key = [rd(m), rd(m + 1), rd(m + 2), rd(m + 3), rd(a), rd(a + 1), w & 127, h].join(',');
      let px = staged.get(key);
      if (!(w & 128)) {
        px = [];
        for (let row = 0; row < h; row++) for (let col = 0; col < w; col++) {
          const p0 = rd(src++), p1 = rd(src++);
          for (let bit = 0; bit < 8; bit++) {
            const pen = ((p0 >> (7-bit)) & 1) * 2 + ((p1 >> (7-bit)) & 1);
            if (pen) px.push([(y+row)*256+x+col*8+bit, pen]);
          }
        }
        staged.set(key, px);
      } else if (!px) throw new Error(`slot ${slot} not staged and never staged before (${key})`);
      for (const [xy, pen] of px) {
        if (owners.has(slot)) pair[owners.get(slot)].set(xy, pen);
        else foreground.add(xy);
      }
    }
    // The later player's opaque pixels legitimately cover the earlier one.
    // Still require every exposed pixel of each complete staged body/head.
    for (const xy of pair[1].keys()) pair[0].delete(xy);
    // Non-player objects (hoops, ball) may cover a player with opaque pixels;
    // transparent pixels never do.
    for(const xy of foreground){pair[0].delete(xy);pair[1].delete(xy);}
    for (let n = 0; n < 2; n++) { poses[n].push(pair[n]); if (poses[n].length > 4) poses[n].shift(); }
    snapshots++;
  }
  if (pc === sym('cfp_done') && pairPending) { unpaired = false; pairPending = false; }
  // Bounds of the actual shared-buffer write are checked on every publish.
  if (pc === sym('PUBLISH_RECT')) {
    const bytes = rd(0xf1c) * rd(0xf1d) * 2;
    maxPairBytes = Math.max(maxPairBytes, bytes);
    const capacity = 1280;
    if (bytes > capacity) throw new Error(`player buffer exceeds 2000..24FF: ${bytes}`);
  }
  return instruction();
};
function rasterHasPose(pose) {
  for (const [xy, pen] of pose) {
    const x = xy % 256, y = Math.floor(xy / 256);
    const at = (48+y)*576 + 32 + x*2;
    const want = emu.io.Palette[pen];
    if (emu.v06c.bmp[at] !== (want >>> 0) || emu.v06c.bmp[at+1] !== (want >>> 0)) return false;
  }
  return pose.size > 0;
}
let phase = 'title', match = 0, checked = 0, menuChecked = 0, failures = [];
for (let f = 0; f < 640; f++) {
  keys(0, 0);
  if (phase === 'title' && f >= 8 && f < 40) keys(7, 0x80);
  if (phase === 'menu' && f >= 190) keys(2, 0x02);
  if (phase === 'move') keys(4, f-match < 240 ? 0x40 : 0x80);
  emu.v06c.oneFrame();
  const y1 = rd(0x940d), y2 = rd(0x9427);
  if (phase === 'title' && y1 === 0x6e && y2 === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  else if (phase === 'menu' && rd(0x0fed) === 1) { phase = 'move'; match = f; }
  if (phase === 'menu' && f >= 105 && f < 190) {
    for (let n = 0; n < 2; n++) if (!poses[n].some(rasterHasPose)) failures.push(`menu frame ${f} player ${n+1}: incomplete body/head pose`);
    menuChecked++;
  }
  // Replay epilogue clears the object list while the zoomed image remains.
  const replayEpilogue = rd(0xf80) === 0 && emu.cpu.pc >= 0xa82c && emu.cpu.pc < 0xaa00;
  if (phase === 'move' && f-match >= 110 && !replayEpilogue && unpaired) unpairedSkipped++;
  else if (phase === 'move' && f-match >= 110 && !replayEpilogue) {
    for (let n = 0; n < 2; n++) if (!poses[n].some(rasterHasPose)) failures.push(`frame ${f-match} player ${n+1}: raster has no complete body/head pose`);
    checked++;
  }
}
// One-record poses (shots, fouls) are skipped; how many depends on the tempo.
if (checked < 250 || checked + unpairedSkipped < 300 || menuChecked < 70 || failures.length) {
  console.error(`FAIL raster player motion: checked=${checked}, skipped=${unpairedSkipped}, snapshots=${snapshots}, menu=${menuChecked} ${failures.slice(0, 8).join(', ')}`);
  process.exit(1);
}
console.log(`PASS raster player motion: ${menuChecked} menu frames + ${checked} match frames (${unpairedSkipped} with a one-record pose skipped), both directions, ${snapshots} staged sets; largest pair buffer ${maxPairBytes}/1280 bytes`);
