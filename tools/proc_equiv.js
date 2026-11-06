#!/usr/bin/env node
/**
 * Procedure equivalence: a Z80 game procedure on the Z80 core (reference
 * image build/v06/basket.full.bin) against its translation on the i8080 core
 * (build/i8080/basket-i8080.full.bin), with random registers.
 *
 *   node tools/proc_equiv.js 39A3 [more Z80 addresses]   env N (trials), SEED
 *   node tools/proc_equiv.js --calls                     every CALL target of the game
 *
 * Compared after the return: A B C D E H L, carry and zero, IX/IY (the
 * z80_ix/z80_iy cells on the i8080) and every memory byte outside code
 * (both images equal there before the call). Procedures that wait for an
 * interrupt or the hardware do not return within the step limit and are
 * reported as TIMEOUT, not as differences.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const MAP = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/i8080/labels.json'), 'utf8'));
const amap = {}; for (const [z, n] of Object.entries(MAP.map)) amap[parseInt(z, 16)] = parseInt(n, 16);
const RT = 0x9300;   // RT_VARS: z80_ix, z80_iy

function core(z80) {
  const g = {};
  for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
  g.window = g; g.console = { log: () => {}, error: console.error, warn: () => {} };
  const ctx = vm.createContext(g);
  for (const f of ['i8080-js/i8080.js', ...(z80 ? ['Z80_v06.js', 'z80_adapter.js'] : [])])
    vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
  const mem = new Uint8Array(0x10000);
  const memory = { read: (a) => mem[a & 0xffff], write: (a, v) => { mem[a & 0xffff] = v & 0xff; } };
  const io = { input: () => 0xff, output: () => {}, interrupt: () => {} };
  const cpu = new ctx.I8080(memory, io);
  return { cpu, mem, z80 };
}

const Z = core(true), I = core(false);
const imgZ = fs.readFileSync(path.join(ROOT, 'build/v06/basket.full.bin'));
const imgI = fs.readFileSync(path.join(ROOT, 'build/i8080/basket-i8080.full.bin'));
const same = new Uint8Array(0x10000);
const codeZ = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/v06/disasm_v06_code.json'), 'utf8'));
for (let a = 0; a < 0x10000; a++) same[a] = imgZ[a] === imgI[a] ? 1 : 0;
for (const [lo, n] of codeZ) for (let a = lo; a < lo + n; a++) same[a] = 0;
for (let a = RT; a < RT + 0x20; a++) same[a] = 0;
for (let a = 0xBE00; a < 0xC000; a++) same[a] = 0;           // stack
let rnd = +(process.env.SEED || 7);
const rand = () => ((rnd = (Math.imul(rnd, 1103515245) + 12345) & 0x7fffffff) >>> 16) & 0xff;
const RET = 0xFFF0, SP0 = 0xBF00, LIMIT = +(process.env.LIMIT || 400000);

function run(c, img, entry, r) {
  c.mem.set(img);
  c.mem[SP0] = RET & 0xff; c.mem[SP0 + 1] = RET >> 8;
  const cpu = c.cpu;
  if (c.z80) {
    const st = cpu.getState();
    Object.assign(st, { a: r.a, b: r.b, c: r.c, d: r.d, e: r.e, h: r.h, l: r.l, ix: r.ix, iy: r.iy,
      sp: SP0, pc: entry, iff1: 0, iff2: 0, halted: false });
    st.flags.C = r.cf; st.flags.Z = r.zf;
    cpu.setState(st);
  } else {
    cpu.regs[0] = r.b; cpu.regs[1] = r.c; cpu.regs[2] = r.d; cpu.regs[3] = r.e;
    cpu.regs[4] = r.h; cpu.regs[5] = r.l; cpu.regs[7] = r.a; cpu.cf = r.cf; cpu.zf = r.zf;
    cpu.sp = SP0; cpu.pc = entry; cpu.iff = false;
    c.mem[RT] = r.ix & 0xff; c.mem[RT + 1] = r.ix >> 8; c.mem[RT + 2] = r.iy & 0xff; c.mem[RT + 3] = r.iy >> 8;
  }
  let n = 0;
  while ((cpu.pc & 0xffff) !== RET && n++ < LIMIT) cpu.instruction();
  if ((cpu.pc & 0xffff) !== RET) return null;
  if (c.z80) {
    const st = cpu.getState();
    return { a: st.a, b: st.b, c: st.c, d: st.d, e: st.e, h: st.h, l: st.l, cf: +st.flags.C, zf: +st.flags.Z,
      ix: st.ix, iy: st.iy, sp: st.sp, steps: n };
  }
  return { a: cpu.regs[7], b: cpu.regs[0], c: cpu.regs[1], d: cpu.regs[2], e: cpu.regs[3], h: cpu.regs[4],
    l: cpu.regs[5], cf: +!!cpu.cf, zf: +!!cpu.zf, ix: c.mem[RT] | c.mem[RT + 1] << 8, iy: c.mem[RT + 2] | c.mem[RT + 3] << 8,
    sp: cpu.sp & 0xffff, steps: n };
}

function check(zaddr, trials) {
  const iaddr = amap[zaddr];
  if (iaddr === undefined) return { addr: zaddr, status: 'NOMAP' };
  let timeouts = 0;
  for (let t = 0; t < trials; t++) {
    const r = { a: rand(), b: rand(), c: rand(), d: rand(), e: rand(), h: rand(), l: rand(),
      ix: 0x4000 + rand(), iy: 0x4000 + rand(), cf: rand() & 1, zf: rand() & 1 };
    const z = run(Z, imgZ, zaddr, r), i = run(I, imgI, iaddr, r);
    if (!z || !i) { if (!z && !i) { timeouts++; continue; } return { addr: zaddr, status: 'ONE_TIMEOUT', z: !!z, i: !!i, r }; }
    const diff = [];
    for (const k of ['a', 'b', 'c', 'd', 'e', 'h', 'l', 'cf', 'zf', 'ix', 'iy', 'sp']) if (z[k] !== i[k]) diff.push(`${k} ${z[k].toString(16)}/${i[k].toString(16)}`);
    for (let a = 0; a < 0x10000; a++) if (same[a] && Z.mem[a] !== I.mem[a]) { diff.push(`mem ${a.toString(16)} ${Z.mem[a].toString(16)}/${I.mem[a].toString(16)}`); if (diff.length > 12) break; }
    if (diff.length) return { addr: zaddr, status: 'DIFF', trial: t, r, diff };
  }
  return { addr: zaddr, status: timeouts === trials ? 'TIMEOUT' : 'OK', timeouts };
}

let addrs = process.argv.slice(2).filter((x) => !x.startsWith('--')).map((x) => parseInt(x, 16));
if (process.argv.includes('--calls')) {
  const asm = fs.readFileSync(path.join(ROOT, 'disasm/v06/game.asm'), 'utf8');
  const set = new Set();
  for (const m of asm.matchAll(/\tcall (?:\w+,)?Z_([0-9A-F]{4})/g)) set.add(parseInt(m[1], 16));
  addrs = [...set].sort((a, b) => a - b);
}
const N = +(process.env.N || 50);
const res = { OK: 0, DIFF: 0, TIMEOUT: 0, ONE_TIMEOUT: 0, NOMAP: 0 };
for (const a of addrs) {
  const r = check(a, N);
  res[r.status]++;
  if (r.status !== 'OK' && r.status !== 'TIMEOUT' || process.env.VERBOSE) console.log(a.toString(16).toUpperCase(), JSON.stringify(r));
}
console.log('PROC_EQUIV', JSON.stringify(res));
process.exit(res.DIFF || res.ONE_TIMEOUT ? 1 : 0);
