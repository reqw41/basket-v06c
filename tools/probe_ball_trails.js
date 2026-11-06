#!/usr/bin/env node
/**
 * Probe: free-ball ink left on court after publish (Vector-06C).
 *
 * Samples at COLOR_FRAME_END boundaries (not raw oneFrame), because DIRTY_LIST
 * is filled across multiple hardware frames before publish.
 *
 *   node tools/probe_ball_trails.js [rom]
 */
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
g.console = { log: () => {}, debug: () => {}, error: console.error, warn: console.warn };
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
  return { memory, keyboard, cpu, v06c, io };
}

const emu = boot();
const rd = (a) => emu.memory.read(a & 0xffff, false);
const wr = (a, v) => emu.memory.write(a & 0xffff, v & 0xff, false);
const keys = (row, mask) => {
  for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0;
  if (mask) emu.keyboard.matrix[row] = mask;
};

function findPattern(bytes) {
  outer: for (let a = 0x100; a < 0x10000 - bytes.length; a++) {
    for (let i = 0; i < bytes.length; i++) if (rd(a + i) !== bytes[i]) continue outer;
    return a;
  }
  return 0;
}

const dirtyRestoreAddr = findPattern([0xb7, 0xc8, 0x32, 0x5f, 0x0f]);
// COLOR_FRAME_END: push af/bc/de/hl/ix/iy; di  near the cfp CSPR_UNCHANGED=1 site
const csprUnchangedStore = findPattern([0x3e, 0x01, 0x32, 0x6b, 0x0f, 0xdd, 0xe5]);
const colorFrameEnd = csprUnchangedStore ? csprUnchangedStore - (0xa4a - 0xa16) : 0;
// Verify: 0xa16 should be F5 C5 D5 E5 DD E5 FD E5 F3
let cfe = 0;
for (let a = 0x800; a < 0xc00; a++) {
  if (
    rd(a) === 0xf5 && rd(a + 1) === 0xc5 && rd(a + 2) === 0xd5 && rd(a + 3) === 0xe5 &&
    rd(a + 4) === 0xdd && rd(a + 5) === 0xe5 && rd(a + 6) === 0xfd && rd(a + 7) === 0xe5 &&
    rd(a + 8) === 0xf3
  ) {
    cfe = a;
    break;
  }
}
console.log(`DIRTY_RESTORE @ ${dirtyRestoreAddr.toString(16)} COLOR_FRAME_END @ ${cfe.toString(16)} (hint ${colorFrameEnd.toString(16)})`);

function readRects(base, count) {
  const out = [];
  for (let i = 0; i < count; i++) {
    const a = base + i * 4;
    out.push({
      i,
      col: rd(a),
      row: rd(a + 1),
      w: rd(a + 2) & 0x7f,
      bit7: (rd(a + 2) >> 7) & 1,
      h: rd(a + 3),
    });
  }
  return out;
}

function prefixBalls(rects, count) {
  const n = Math.max(0, count - 4);
  return rects.slice(0, n).filter((r) => r.h > 0 && r.h < 16 && r.w > 0);
}

function coveredBy(col, row, rects) {
  for (const r of rects) {
    if (!r.w || !r.h) continue;
    if (col >= r.col && col < r.col + r.w && row >= r.row && row < r.row + r.h) return true;
  }
  return false;
}

const courtCache = new Map();
function courtPair(col, row) {
  const key = (row << 5) | col;
  if (courtCache.has(key)) return courtCache.get(key);
  const src = 0x2500 + row * 32 + col;
  const cpu = emu.cpu;
  const saved = cpu.getState();
  const savedPc = cpu.pc;
  const savedSp = cpu.sp;
  const scratch = [0x0f59, 0x17b4, 0x17f5, 0x17f6].map((a) => [a, rd(a)]);
  const rowCache = [];
  for (let a = 0x1774; a < 0x1774 + 64; a++) rowCache.push(rd(a));
  const sp = 0xbe00;
  cpu.setState(Object.assign({}, saved, {
    pc: 0x1800, sp, h: (src >> 8) & 0xff, l: src & 0xff, iff1: 0, iff2: 0, halted: false,
  }));
  cpu.pc = 0x1800;
  cpu.sp = sp;
  wr(sp, 0); wr(sp + 1, 0);
  let n = 0;
  while (n++ < 20000 && (cpu.pc & 0xffff) !== 0) cpu.instruction();
  const out = { lo: cpu.getState().a & 0xff, hi: rd(0x0f59) };
  cpu.setState(saved);
  cpu.pc = savedPc;
  cpu.sp = savedSp;
  for (const [a, v] of scratch) wr(a, v);
  for (let i = 0; i < rowCache.length; i++) wr(0x1774 + i, rowCache[i]);
  courtCache.set(key, out);
  return out;
}

function planePair(col, row) {
  const e = (0xd7 - row) & 0xff;
  return { lo: rd(0xe000 + col * 256 + e), hi: rd(0xc000 + col * 256 + e) };
}

function summarizeRects(rects) {
  return rects.map((r) => `${r.i}:${r.col},${r.row} ${r.w}x${r.h}${r.bit7 ? '*' : ''}`).join(' | ');
}

function leftoverInk(rect, coverRects) {
  const leftovers = [];
  for (let dy = 0; dy < rect.h; dy++) {
    for (let dx = 0; dx < rect.w; dx++) {
      const col = rect.col + dx;
      const row = rect.row + dy;
      if (row < 8 || row >= 120 || col < 0 || col >= 32) continue;
      if (coveredBy(col, row, coverRects)) continue;
      const got = planePair(col, row);
      const exp = courtPair(col, row);
      if (got.lo !== exp.lo || got.hi !== exp.hi) leftovers.push({ col, row, got, exp });
    }
  }
  return leftovers;
}

let phase = 'title';
let matchAt = -1;
let frameIdx = 0;
let publishes = 0;
const trails = [];
const moves = [];

// cfp_done: ei / pop iy / ... / ret  (after prefix restore+blit)
const cfpDone = findPattern([0xfb, 0xfd, 0xe1, 0xdd, 0xe1, 0xe1, 0xd1, 0xc1, 0xf1, 0xc9]);
console.log(`cfp_done @ ${cfpDone.toString(16)}`);

let inCFE = false;
let restoreLog = [];
let pendingCheck = null;

const instruction = emu.cpu.instruction.bind(emu.cpu);
emu.cpu.instruction = function () {
  const pc = this.pc & 0xffff;

  if (pc === cfe && rd(0x0fee) === 1) {
    // Do not reset inCFE/restoreLog on re-entry while a publish is suspended
    // across halt; only arm a new pending check when idle.
    if (!inCFE) {
      inCFE = true;
      restoreLog = [];
    }
    const count = rd(0x0f80);
    const oldCount = rd(0xb258);
    const entryDirty = readRects(0x0f81, count);
    const entryOld = readRects(0xb259, oldCount);
    const entryOldBalls = prefixBalls(entryOld, oldCount);
    const newBalls = prefixBalls(entryDirty, count);
    const moved = entryOldBalls.filter(
      (ob) => !newBalls.some((b) => b.col === ob.col && b.row === ob.row && b.w === ob.w && b.h === ob.h)
    );
    pendingCheck = {
      count,
      oldCount,
      moved,
      newBalls,
      dirtyPrefix: entryDirty.slice(0, Math.max(0, count - 4)),
      oldPrefix: entryOld.slice(0, Math.max(0, oldCount - 4)),
      rowsAfterSetup: null,
      orphanCount: Math.max(0, Math.max(0, oldCount - 4) - Math.max(0, count - 4)),
    };
  }

  if (inCFE && pc === dirtyRestoreAddr) {
    const ix = this.ix & 0xffff;
    const a = this.a & 0xff;
    const rects = [];
    for (let i = 0; i < a; i++) {
      const base = ix + i * 4;
      rects.push({
        col: rd(base), row: rd(base + 1),
        w: rd(base + 2) & 0x7f, bit7: (rd(base + 2) >> 7) & 1, h: rd(base + 3),
      });
    }
    restoreLog.push({
      ix: ix.toString(16),
      a,
      rects,
      fromOld: ix >= 0xb259 && ix < 0xb259 + 27 * 4,
      pub: rd(0x0f6c),
      rows: rd(0x0f5f),
    });
  }

  // After PLAYER_SCENE_SETUP returns into cps_normal, CSPR_ROWS is prefix length.
  if (inCFE && pc === 0x3fb3 && pendingCheck) {
    pendingCheck.rowsAfterSetup = rd(0x0f5f);
  }

  if (inCFE && pc === cfpDone) {
    publishes++;
    if (pendingCheck && pendingCheck.moved.length && rd(0x0fed) === 1) {
      const cover = readRects(0x0f81, rd(0x0f80));
      for (const ob of pendingCheck.moved) {
        const left = leftoverInk(ob, cover);
        const aligned = pendingCheck.dirtyPrefix[ob.i];
        const restored = restoreLog.some((r) =>
          r.rects.some((x) => x.col === ob.col && x.row === ob.row && x.w === ob.w && x.h === ob.h)
        );
        const ev = {
          publish: publishes,
          matchFrame: frameIdx - matchAt,
          oldBall: ob,
          newBalls: pendingCheck.newBalls,
          alignedNew: aligned || null,
          bit7AtIndex: aligned ? aligned.bit7 : null,
          orphanIndex: ob.i >= pendingCheck.dirtyPrefix.length,
          restored,
          restoreCount: restoreLog.length,
          restoreLog,
          leftoverBytes: left.length,
          leftoverSample: left.slice(0, 3),
          dirtyPrefix: summarizeRects(pendingCheck.dirtyPrefix),
          oldPrefix: summarizeRects(pendingCheck.oldPrefix),
          counts: `${pendingCheck.count}/${pendingCheck.oldCount}`,
          rowsAfterSetup: pendingCheck.rowsAfterSetup,
        };
        moves.push(ev);
        if (left.length) trails.push(ev);
      }
    }
    inCFE = false;
    pendingCheck = null;
  }

  return instruction();
};

for (frameIdx = 0; frameIdx < 700; frameIdx++) {
  keys(0, 0);
  if (phase === 'title' && frameIdx >= 8 && frameIdx < 100) keys(7, 0x80);
  if (phase === 'menu') keys(2, 0x02);
  if (phase === 'match' && frameIdx - matchAt > 40 && frameIdx - matchAt < 200) keys(4, 0x20);
  emu.v06c.oneFrame();
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  if (phase === 'menu' && rd(0x0fef) === 0 && rd(0x0fed) === 1) {
    matchAt = frameIdx;
    phase = 'match';
    console.log(`match@${frameIdx}`);
  }
  if (phase === 'match' && (frameIdx - matchAt) % 30 === 0) {
    console.log(
      `f+${frameIdx - matchAt} publishes=${publishes} moves=${moves.length} trails=${trails.length} ` +
        `cnt=${rd(0x0f80)}/${rd(0xb258)}`
    );
  }
  if (trails.length >= 6) break;
  if (phase === 'match' && frameIdx - matchAt > 350) break;
}

console.log('\n=== summary ===');
console.log(`publishes=${publishes} ball-move publishes=${moves.length} trails=${trails.length}`);
const restored = moves.filter((m) => m.restored);
const unrestored = moves.filter((m) => !m.restored);
const orphans = moves.filter((m) => m.orphanIndex || (m.counts && m.counts.split('/')[0] !== m.counts.split('/')[1]));
console.log(`moves with matching DIRTY_RESTORE rect: ${restored.length}; without: ${unrestored.length}`);
console.log(`moves with count shrink / orphan index: ${moves.filter((m) => m.orphanIndex).length}`);
console.log(`restoreCounts on moves: ${moves.slice(0, 12).map((m) => m.restoreCount).join(',')}`);
for (const t of (trails.length ? trails : moves).slice(0, 5)) {
  console.log(JSON.stringify(t, null, 2));
}
if (!moves.length) console.log('No post-publish ball moves observed.');

// Hypothesis check: every trail should be orphan-old-prefix (count shrink).
if (trails.length) {
  const allOrphan = trails.every((t) => t.orphanIndex && t.restoreCount === 0);
  console.log(`\nHYPOTHESIS orphan-prefix-no-restore: ${allOrphan ? 'CONFIRMED' : 'MIXED'}`);
}
