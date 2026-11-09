#!/usr/bin/env node
/**
 * block_equiv: game procedures of the translated i8080 image against the Z80
 * reference, from real call states.
 *   node tools/block_equiv.js        env NF (frames, 2500), K (snapshots per procedure, 4), SEED
 * A Z80 run (title, menu, random match play) snapshots registers and memory
 * at the first K entries of every CALL target of the game. Each snapshot is
 * replayed to its return on a bare Z80 core (reference image state) and on a
 * bare i8080 core (same state; the static image differences, i.e. the
 * recompiled code, RST slots and adapter operands, taken from the i8080
 * image; runtime-modified words that hold Z80 code addresses mapped).
 * Compared after the return: A BC DE HL SP (a Z80 code address equals its
 * i8080 address), IX/IY (z80_ix/z80_iy cells), memory outside code with the
 * same mapping. Carry/zero differences are listed apart (callers may not
 * read them). Procedures that wait for an interrupt time out on both cores.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = path.join(ROOT, 'build/v06/basket.rom');
const MAP = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/i8080/labels.json'), 'utf8'));
const IS8080 = false;
const ITER_PC = IS8080 ? parseInt(MAP.map['8554'], 16) : 0x8554;

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
  if (cpu.getState) {
    const st = cpu.getState();
    st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1;
    cpu.setState(st);
  } else { cpu.iff = false; }
  cpu.pc = 0x0100; cpu.sp = 0xe000;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  const exec = new Uint8Array(0x10000);
  const count = new Float64Array(0x10000), cyc = new Float64Array(0x10000);
  global.PROF = { count, cyc, iters: 0 };
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    const p = cpu.pc & 0xffff; exec[p] = 1; count[p]++;
    if (p === ITER_PC && global.PROF.match) global.PROF.iters++;   // game main-loop iteration
    if (global.STEP) global.STEP(p);
    if (global.HOOK && WATCH[p]) global.HOOK(p);
    const r = oi(); cyc[p] += cpu.vcycles || r || 0; return r; };
  return { memory, keyboard, cpu, v06c, exec };
}


const MAPI = {}; for (const [z, n] of Object.entries(MAP.map)) MAPI[parseInt(z, 16)] = parseInt(n, 16);
const imgZ = fs.readFileSync(path.join(ROOT, 'build/v06/basket.full.bin'));
const imgI = fs.readFileSync(path.join(ROOT, 'build/i8080/basket-i8080.full.bin'));
// DP_COST (0FE4, word) ends a publish as DP_START, the copy start of that
// CPU (build_i8080_rom.py writes the i8080 timing): equal when each image
// holds its own DP_START.
const DP_COST = 0x0fe4, DP_START = require('./v06syms').SYMS.DP_START;
const ownStart = (img, mem) => mem[DP_COST] === img[DP_START] && mem[DP_COST + 1] === img[DP_START + 1];
const codeZ = new Uint8Array(0x10000), insnZ = new Uint8Array(0x10000);
for (const [lo, n] of JSON.parse(fs.readFileSync(path.join(ROOT, 'build/v06/disasm_v06_code.json'), 'utf8'))) {
  insnZ[lo] = 1; for (let a = lo; a < lo + n; a++) codeZ[a] = 1;
}
const usedI = new Uint8Array(0x10000);
for (const [lo, hi] of MAP.used) for (let a = parseInt(lo, 16); a <= parseInt(hi, 16); a++) usedI[a] = 1;
for (const [lo, hi] of MAP.data_fixed) for (let a = parseInt(lo, 16); a <= parseInt(hi, 16); a++) usedI[a] = 0;   // data stays
const asm = fs.readFileSync(path.join(ROOT, 'disasm/v06/game.asm'), 'utf8');
const targets = new Set();
for (const m of asm.matchAll(/\tcall (?:\w+,)?Z_([0-9A-F]{4})/g)) targets.add(parseInt(m[1], 16));
const ONLY = process.env.ONLY ? new Set(process.env.ONLY.split(',').map((x) => parseInt(x, 16))) : null;
const K = +(process.env.K || 4);

// --- capture
const emu = boot();
const rd = a => emu.memory.read(a & 0xffff, false);
const keys = (row, mask) => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; if (mask) emu.keyboard.matrix[row] = mask; };
const snaps = []; const taken = {};
global.STEP = (p) => {
  if (!targets.has(p) || (ONLY && !ONLY.has(p)) || (taken[p] || 0) >= K) return;
  if (global.FRAME < (taken['f' + p] || 0)) return;
  taken[p] = (taken[p] || 0) + 1; taken['f' + p] = global.FRAME + 40;   // spread over the run
  const st = emu.cpu.getState();
  const mem = new Uint8Array(0x10000); for (let a = 0; a < 0x10000; a++) mem[a] = rd(a);
  snaps.push({ p, frame: global.FRAME, st: JSON.parse(JSON.stringify(st)), mem });
};
let rnd = +(process.env.SEED || 12345); const rand = () => (rnd = (rnd * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff; let cur = 0, hold = 0, phase = 'title';
for (let frame = 0; frame < +(process.env.NF || 2500); frame++) {
  global.FRAME = frame;
  keys(0, 0);
  if (phase === 'title' && frame >= 8 && frame < 40) keys(7, 0x80);
  if (phase === 'menu') keys(2, 0x02);
  if (phase === 'match') { const x = rd(0x940d), y = rd(0x940e);
    if (hold-- <= 0) { hold = 5 + Math.floor(rand() * 30); cur = Math.floor(rand() * 7); }
    if (cur < 3) { if (x > 0x5a) keys(0, 0x10); else if (x < 0x50) keys(0, 0x40); else if (y > 0x0c) keys(0, 0x20); else keys(7, 0x80); }
    else { const m = [[0, 0x10], [0, 0x40], [0, 0x20], [7, 0x80]][cur - 3]; keys(m[0], m[1]); } }
  emu.v06c.oneFrame();
  if (phase === 'title' && rd(0x940d) === 0x6e && rd(0x9427) === 0x6e && rd(0x940b) === 0x10) phase = 'menu';
  else if (phase === 'menu' && rd(0x0fed) === 1) phase = 'match';
}

// --- replay on bare cores
function core(z80) {
  const g = {};
  for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
  g.window = g; g.console = { log: () => {}, error: console.error, warn: () => {} };
  const c = vm.createContext(g);
  for (const f of ['i8080-js/i8080.js', ...(z80 ? ['Z80_v06.js', 'z80_adapter.js'] : [])])
    vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), c, { filename: f });
  const mem = new Uint8Array(0x10000);
  const memory = { read: (a) => mem[a & 0xffff], write: (a, v) => { mem[a & 0xffff] = v & 0xff; } };
  const io = { input: () => 0xff, output: () => {}, interrupt: () => {} };
  return { cpu: new c.I8080(memory, io), mem, z80 };
}
const Z = core(true), I = core(false);
const RT = 0x9300, RET = 0xFFF0, LIMIT = +(process.env.LIMIT || 300000);
// LD A,R: the Z80 run records each value; il_rnd (z80_r + 9Dh) gets the same
// series on the i8080 (pitfall 8: fix the R series on both images).
const IL_RND = parseInt(/^il_rnd\s+= \$([0-9A-F]{4})/m.exec(fs.readFileSync(path.join(ROOT, 'build/i8080/game.lst'), 'utf8'))[1], 16);
const Z80_R = RT + 20; let rseries = [], rpos = 0;
const isCodeAddr = (w) => insnZ[w] && MAPI[w] !== undefined;
function i8080Mem(snap) {
  const m = Uint8Array.from(snap);
  // 1B40..24FF holds the splash animation in the image (its adapter operands
  // differ per image) and is cleared on Space: at run time it is RAM.
  const splash = (a) => a >= 0x1B40 && a < 0x2500;
  for (let a = 0; a < 0x10000; a++) if ((imgZ[a] !== imgI[a] && !splash(a)) || codeZ[a] || usedI[a]) m[a] = imgI[a];
  // runtime-modified bytes: SMC in Z80 code moves with its instruction;
  // RAM words holding Z80 code addresses take the i8080 address
  for (let a = 0; a < 0x10000; a++) {
    if (snap[a] === imgZ[a]) continue;
    if (codeZ[a] && MAPI[a] !== undefined) { m[MAPI[a]] = snap[a]; continue; }
    // only JP/CALL built in RAM (C3/CD before the word), the ISR vector 4142
    // and the 3C1E dispatch list (flag, procedure) built by 94B0
    const tbl = a >= 0x3C1F && a < 0x3C50 && (a - 0x3C1F) % 3 === 0;
    // graphics (box/replay buffer 2000..24FF, staged stream B498..BBFF,
    // planes C000..FFFF): pixel bytes, never a JP/CALL
    const gfx = (a >= 0x2000 && a < 0x2500) || (a >= 0xB498 && a < 0xBC00) || a >= 0xC000;
    if (!gfx && !codeZ[a] && !usedI[a] && a > 0 && a < 0xffff && (tbl || a - 1 === 0x4141 || snap[a - 1] === 0xC3 || snap[a - 1] === 0xCD)) {
      const w = snap[a] | snap[a + 1] << 8;
      if (isCodeAddr(w)) { m[a] = MAPI[w] & 0xff; m[a + 1] = MAPI[w] >> 8; a++; }
    }
  }
  return m;
}
function run(c, mem, entry, st) {
  c.mem.set(mem);
  const sp = st.sp; c.mem[sp] = RET & 0xff; c.mem[sp + 1] = RET >> 8;
  const cpu = c.cpu;
  if (c.z80) {
    const s = cpu.getState(); Object.assign(s, st); s.pc = entry; s.iff1 = 0; s.iff2 = 0; s.halted = false; cpu.setState(s);
  } else {
    const r = cpu.regs; r[0] = st.b; r[1] = st.c; r[2] = st.d; r[3] = st.e; r[4] = st.h; r[5] = st.l; r[7] = st.a;
    cpu.cf = st.flags.C ? 1 : 0; cpu.zf = st.flags.Z ? 1 : 0; cpu.sf = st.flags.S ? 1 : 0; cpu.pf = st.flags.P ? 1 : 0;
    cpu.sp = sp; cpu.pc = entry; cpu.iff = false;
    c.mem[RT] = st.ix & 0xff; c.mem[RT + 1] = st.ix >> 8; c.mem[RT + 2] = st.iy & 0xff; c.mem[RT + 3] = st.iy >> 8;
  }
  let n = 0;
  if (c.z80) rseries = []; else rpos = 0;
  while (!((cpu.pc & 0xffff) === RET && (cpu.sp & 0xffff) === ((sp + 2) & 0xffff)) && n++ < LIMIT) {
    const pc0 = cpu.pc & 0xffff;
    if (c.z80 && c.mem[pc0] === 0xED && c.mem[(pc0 + 1) & 0xffff] === 0x5F) { cpu.instruction(); rseries.push(cpu.getState().a); continue; }
    if (!c.z80 && pc0 === IL_RND && rpos < rseries.length) c.mem[Z80_R] = (rseries[rpos++] - 0x9D) & 0xff;
    if (!c.z80 && global.TRACEI > 0) { global.TRACEI--; console.log('  i', (cpu.pc & 0xffff).toString(16), 'a', cpu.regs[7].toString(16), 'hl', (cpu.regs[4] << 8 | cpu.regs[5]).toString(16), 'sp', (cpu.sp & 0xffff).toString(16)); }
    cpu.instruction();
  }
  if (n >= LIMIT) return null;
  if (c.z80) { const s = cpu.getState(); return { a: s.a, bc: s.b << 8 | s.c, de: s.d << 8 | s.e, hl: s.h << 8 | s.l, cf: +!!s.flags.C, zf: +!!s.flags.Z, ix: s.ix, iy: s.iy, n }; }
  const r = cpu.regs;
  return { a: r[7], bc: r[0] << 8 | r[1], de: r[2] << 8 | r[3], hl: r[4] << 8 | r[5], cf: +!!cpu.cf, zf: +!!cpu.zf,
    ix: c.mem[RT] | c.mem[RT + 1] << 8, iy: c.mem[RT + 2] | c.mem[RT + 3] << 8, n };
}
// A word equals when it is the same, or an address in relocated code: an
// instruction (its map entry) or a byte k = 1..3 into one (an operand that
// self-modifying code patches, e.g. the AE34 operand tables, DE past ldi).
const eqw = (z, i) => z === i || (isCodeAddr(z) && MAPI[z] === i) ||
  [1, 2, 3].some((k) => isCodeAddr(z - k) && MAPI[z - k] !== undefined && MAPI[z - k] + k === i);
// LOCKSTEP=<Z80 proc>: step both from the first snapshot; the i8080 runs to
// the image of each next Z80 PC; registers compared at every meeting point.
function lockstep(s) {
  const iEntry = MAPI[s.p];
  Z.mem.set(s.mem); I.mem.set(i8080Mem(s.mem));
  run(Z, s.mem, s.p, s.st); run(I, i8080Mem(s.mem), iEntry, s.st);   // warm: then restart by hand
  Z.mem.set(s.mem); I.mem.set(i8080Mem(s.mem));
  const sp = s.st.sp; Z.mem[sp] = RET & 0xff; Z.mem[sp + 1] = RET >> 8; I.mem[sp] = RET & 0xff; I.mem[sp + 1] = RET >> 8;
  const zc = Z.cpu, ic = I.cpu; const st = zc.getState(); Object.assign(st, s.st); st.pc = s.p; st.iff1 = 0; st.iff2 = 0; zc.setState(st);
  const r = ic.regs; r[0] = s.st.b; r[1] = s.st.c; r[2] = s.st.d; r[3] = s.st.e; r[4] = s.st.h; r[5] = s.st.l; r[7] = s.st.a;
  ic.cf = s.st.flags.C ? 1 : 0; ic.zf = s.st.flags.Z ? 1 : 0; ic.sp = sp; ic.pc = iEntry; ic.iff = false;
  I.mem[RT] = s.st.ix & 0xff; I.mem[RT + 1] = s.st.ix >> 8; I.mem[RT + 2] = s.st.iy & 0xff; I.mem[RT + 3] = s.st.iy >> 8;
  const hist = [];
  for (let k = 0; k < 200000; k++) {
    const zpc = zc.getState().pc & 0xffff;
    if (zpc === RET) { console.log('LOCKSTEP returned equal after', k, 'Z80 instructions'); return; }
    let target = MAPI[zpc];
    if (target === undefined && !codeZ[zpc]) target = zpc;            // adapter: the same code on both
    if (target === undefined) { console.log('Z80 pc', zpc.toString(16), 'has no i8080 image'); return; }
    let n = 0; while ((ic.pc & 0xffff) !== target && n++ < 5000) {
      if ((ic.pc & 0xffff) === IL_RND) I.mem[Z80_R] = (zc.getState().a - 0x9D) & 0xff;   // Z80 already did LD A,R
      ic.instruction();
    }
    if (n >= 5000) { console.log('i8080 never reached', target.toString(16), 'for Z80', zpc.toString(16)); console.log(hist.slice(-12).join('\n')); return; }
    const zs = zc.getState();
    const zv = [zs.a, zs.b << 8 | zs.c, zs.d << 8 | zs.e, zs.h << 8 | zs.l, zs.ix, zs.iy];
    const iv = [ic.regs[7], ic.regs[0] << 8 | ic.regs[1], ic.regs[2] << 8 | ic.regs[3], ic.regs[4] << 8 | ic.regs[5], I.mem[RT] | I.mem[RT + 1] << 8, I.mem[RT + 2] | I.mem[RT + 3] << 8];
    const names = ['a', 'bc', 'de', 'hl', 'ix', 'iy'];
    const bad = names.filter((x, j) => !(j === 0 ? zv[j] === iv[j] : eqw(zv[j], iv[j])));
    hist.push(`${zpc.toString(16)} z ${zv.map((v) => v.toString(16)).join(' ')} | i ${iv.map((v) => v.toString(16)).join(' ')} c${+!!zs.flags.C}/${+!!ic.cf} z${+!!zs.flags.Z}/${+!!ic.zf}`);
    if (bad.length) { console.log('DIVERGE at Z80', zpc.toString(16), bad.join(',')); console.log(hist.slice(-15).join('\n')); return; }
    zc.instruction();
  }
}
if (process.env.LOCKSTEP) { const want = parseInt(process.env.LOCKSTEP, 16); const s = snaps.find((x) => x.p === want && (!process.env.LSFRAME || x.frame === +process.env.LSFRAME)); if (s) lockstep(s); else console.log('no snapshot'); process.exit(0); }
// Reviewed differences (each with its reason); they are counted, not failed.
const ACCEPT = {
  0x9652: 'PUSH AF / POP DE at 9684/968B: E gets the flag byte, whose unused bits differ (Z80 F vs i8080 PSW); only D is read',
  0xAA7C: 'silent tune 7F49 copies 30 bytes from 0000 (RST slots differ) into voice states of voices that stay off',
  0xAA8F: 'same as AA7C (inner entry)',
  0x953B: 'JP (HL) trampoline: the snapshot holds a Z80 address in HL itself',
};
const res = { OK: 0, FLAGS: 0, DIFF: 0, ACCEPTED: 0, TIMEOUT: 0, ONE_TIMEOUT: 0 }; const bad = {};
for (const s of snaps) {
  const iEntry = MAPI[s.p];
  if (process.env.DEBUG && parseInt(process.env.DEBUG, 16) === s.p) {
    const im = i8080Mem(s.mem); const ix = s.st.ix;
    console.log('ix', ix.toString(16), 'z(ix+a)', s.mem[(ix + 10) & 0xffff].toString(16), 'i(ix+a)', im[(ix + 10) & 0xffff].toString(16), 'sp', s.st.sp.toString(16));
    global.TRACEI = 60;
  }
  const zr = run(Z, s.mem, s.p, s.st), ir = run(I, i8080Mem(s.mem), iEntry, s.st);
  let status;
  const diff = [];
  if (!zr || !ir) status = (!zr && !ir) ? 'TIMEOUT' : 'ONE_TIMEOUT';
  else {
    if (zr.a !== ir.a) diff.push(`a ${zr.a.toString(16)}/${ir.a.toString(16)}`);
    for (const k of ['bc', 'de', 'hl', 'ix', 'iy']) if (!eqw(zr[k], ir[k])) diff.push(`${k} ${zr[k].toString(16)}/${ir[k].toString(16)}`);
    for (let a = 0; a < 0x10000; a++) {
      if (codeZ[a] || usedI[a] || (a >= RT && a < RT + 0x20) || Z.mem[a] === I.mem[a]) continue;
      if (a >= 0xBC00 && a < s.st.sp + 2) continue;                       // scratch below the caller's stack
      if ((a === DP_COST || a === DP_COST + 1) && ownStart(imgZ, Z.mem) && ownStart(imgI, I.mem)) continue;
      if (imgZ[a] !== imgI[a] && Z.mem[a] === imgZ[a] && I.mem[a] === imgI[a]) continue;   // static image difference
      if (a < 0xffff && eqw(Z.mem[a] | Z.mem[a + 1] << 8, I.mem[a] | I.mem[a + 1] << 8)) { a++; continue; }
      if (a > 0 && eqw(Z.mem[a - 1] | Z.mem[a] << 8, I.mem[a - 1] | I.mem[a] << 8)) continue;
      diff.push(`mem ${a.toString(16)} ${Z.mem[a].toString(16)}/${I.mem[a].toString(16)}`); if (diff.length > 10) break;
    }
    status = diff.length ? 'DIFF' : (zr.cf !== ir.cf || zr.zf !== ir.zf) ? 'FLAGS' : 'OK';
    if (status === 'FLAGS') diff.push(`cf ${zr.cf}/${ir.cf} zf ${zr.zf}/${ir.zf}`);
  }
  if ((status === 'DIFF' || status === 'ONE_TIMEOUT') && ACCEPT[s.p]) status = 'ACCEPTED';
  res[status]++;
  if (status !== 'OK' && status !== 'TIMEOUT' && !bad[s.p + status]) {
    bad[s.p + status] = 1;
    console.log(`${s.p.toString(16).toUpperCase()} ${status} f${s.frame} ${diff.join(', ')}`);
  }
}
console.log('BLOCK_EQUIV', JSON.stringify({ snapshots: snaps.length, procs: Object.keys(taken).filter((k) => k[0] !== 'f').length, ...res }));
process.exit(res.DIFF || res.ONE_TIMEOUT ? 1 : 0);
