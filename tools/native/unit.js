#!/usr/bin/env node
/**
 * A2 module check: the hand i8080 code of a module (cfg/native_modules.json,
 * built into build/i8080/basket-i8080.full.bin) against the JS model, from
 * the same states: entry snapshots taken while the model replays the goldens,
 * plus random mutations of the player / ball state.
 *
 *   node tools/native/unit.js <module> [mutations per snapshot, 20] [seed]
 *
 * Both run with every platform call logged and returned at once. Compared:
 *  - the module's outputs (cfg "out": a b c d e h l ix iy cf zf; default none),
 *  - memory: every data byte (not code of either image, not the runtime cells,
 *    not the dead stack), Z80 code addresses in data mapped to i8080 ones,
 *  - platform calls: targets and the registers in cfg "pargs" (default a bc de hl ix iy).
 * Also the i8080 T-states of the module per call (mean), for the A2 gate.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const zlib = require('zlib');
const { Machine, Mismatch, hx } = require('./machine');

const ROOT = path.join(__dirname, '../..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const NAME = process.argv[2];
let TRIALS = process.argv[3] !== undefined ? +process.argv[3] : 20;
let seed = +process.argv[4] || 1;
const rnd = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x80000000; };
const CFG = JSON.parse(fs.readFileSync(path.join(ROOT, 'cfg/native_modules.json'), 'utf8'));
const MOD = CFG[NAME];
if (!MOD) { console.error('modules: ' + Object.keys(CFG).filter((k) => k[0] !== '_').join(' ')); process.exit(2); }
if (MOD.mutate === false) TRIALS = 0;            // e.g. the ISR: ix/iy point anywhere
const ENTRIES = MOD.entries.map((h) => parseInt(h, 16));
// "from": capture points whose state also runs every entry (e.g. the walk
// step 9C83 for procedures it jumps to)
const FROM = (MOD.from || []).map((h) => parseInt(h, 16));
const OUT = MOD.out || [];
const PARGS = MOD.pargs || ['a', 'bc', 'de', 'hl', 'ix', 'iy'];
const PLAT = JSON.parse(fs.readFileSync(path.join(ROOT, 'cfg/platform_args.json'), 'utf8'));
const pargsOf = (t) => PLAT[hx(t)] || PARGS;
const pick = (r, k) => (k === 'b' || k === 'c' || k === 'd' || k === 'e' || k === 'h' || k === 'l'
  ? (r[{ b: 'bc', c: 'bc', d: 'de', e: 'de', h: 'hl', l: 'hl' }[k]] >> ('bdh'.includes(k) ? 8 : 0)) & 0xff : r[k]);
const { procs } = require(path.join(ROOT, 'src/model'));

// ---- images and maps (as tools/block_equiv.js) -------------------------------------------
const MAP = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/i8080/labels.json'), 'utf8'));
const MAPI = {}; for (const [z, n] of Object.entries(MAP.map)) MAPI[parseInt(z, 16)] = parseInt(n, 16);
const imgZ = fs.readFileSync(path.join(ROOT, 'build/v06/basket.full.bin'));
const imgI = fs.readFileSync(path.join(ROOT, 'build/i8080/basket-i8080.full.bin'));
const codeZ = new Uint8Array(0x10000), insnZ = new Uint8Array(0x10000);
for (const [lo, n] of JSON.parse(fs.readFileSync(path.join(ROOT, 'build/v06/disasm_v06_code.json'), 'utf8'))) {
  insnZ[lo] = 1; for (let a = lo; a < lo + n; a++) codeZ[a] = 1;
}
const usedI = new Uint8Array(0x10000);
for (const [lo, hi] of MAP.used) for (let a = parseInt(lo, 16); a <= parseInt(hi, 16); a++) usedI[a] = 1;
for (const [lo, hi] of MAP.data_fixed) for (let a = parseInt(lo, 16); a <= parseInt(hi, 16); a++) usedI[a] = 0;
const gameI = Uint8Array.from(usedI);                        // i8080 game code: placed spans + RST slots
for (const slot of Object.keys(MAP.rst)) for (let k = 0; k < 3; k++) gameI[parseInt(slot, 16) + k] = 1;
const RT = 0x9300, RT_END = 0x932A;
const isCodeAddr = (w) => insnZ[w] && MAPI[w] !== undefined;
const DP_COST = 0x0fe4;
function i8080Mem(snap) {
  const m = Uint8Array.from(snap);
  const splash = (a) => a >= 0x1B40 && a < 0x2500;
  for (let a = 0; a < 0x10000; a++) if ((imgZ[a] !== imgI[a] && !splash(a)) || codeZ[a] || usedI[a]) m[a] = imgI[a];
  for (let a = 0; a < 0x10000; a++) {
    if (snap[a] === imgZ[a]) continue;
    if (codeZ[a] && MAPI[a] !== undefined) { m[MAPI[a]] = snap[a]; continue; }
    const tbl = a >= 0x3C1F && a < 0x3C50 && (a - 0x3C1F) % 3 === 0;
    const gfx = (a >= 0x2000 && a < 0x2500) || (a >= 0xB498 && a < 0xBC00) || a >= 0xC000;
    const state = a >= 0x93D0 && a < 0x9460;     // ball/player blocks: mutated bytes may look like JP/CALL nn
    if (!gfx && !state && !codeZ[a] && !usedI[a] && a > 0 && a < 0xffff && (tbl || a - 1 === 0x4141 || snap[a - 1] === 0xC3 || snap[a - 1] === 0xCD)) {
      const w = snap[a] | snap[a + 1] << 8;
      if (isCodeAddr(w)) { m[a] = MAPI[w] & 0xff; m[a + 1] = MAPI[w] >> 8; a++; }
    }
  }
  return m;
}
const eqw = (z, i) => z === i || (isCodeAddr(z) && MAPI[z] === i) ||
  [1, 2, 3].some((k) => isCodeAddr(z - k) && MAPI[z - k] !== undefined && MAPI[z - k] + k === i);

// ---- bare i8080 core ------------------------------------------------------------------------
const g = {}; for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g; g.console = { log: () => {}, error: console.error, warn: () => {} };
const c = vm.createContext(g);
vm.runInContext(fs.readFileSync(path.join(V06, 'i8080-js/i8080.js'), 'utf8'), c, { filename: 'i8080.js' });
const IM = new Uint8Array(0x10000);
const cpu = new c.I8080({ read: (a) => IM[a & 0xffff], write: (a, v) => { IM[a & 0xffff] = v & 0xff; } },
  { input: () => 0xff, output: () => {}, interrupt: () => {} });
// "cells": Z80 addresses (SMC operands) the hand code keeps in its own symbols
const LST = fs.readFileSync(path.join(ROOT, 'build/i8080/game.lst'), 'utf8');
const symAt = (n) => { const m = new RegExp('^' + n + '\\s+= \\$([0-9A-F]{4})', 'm').exec(LST); if (!m) throw new Error('no symbol ' + n); return parseInt(m[1], 16); };
const CELLS = Object.entries(CFG).filter(([k]) => k[0] !== '_')
  .flatMap(([, m]) => Object.entries(m.cells || {}).map(([z, n]) => [parseInt(z, 16), symAt(n), n]));
// "smcw": Z80 operand words holding a code address (a CALL patched at run
// time) -> the symbol+offset of the same operand in the hand code
const symOff = (n) => { const [b, o] = n.split('+'); return symAt(b) + (+o || 0); };
const SMCW = Object.entries(CFG).filter(([k]) => k[0] !== '_')
  .flatMap(([, m]) => Object.entries(m.smcw || {}).map(([z, n]) => [parseInt(z, 16), symOff(n), n]));
const RET = 0xFFF0;
function runI(snap, entry) {
  IM.set(i8080Mem(snap.mem));
  for (const [z, i] of CELLS) IM[i] = snap.mem[z];
  for (const [z, i] of SMCW) {
    const w = snap.mem[z] | snap.mem[z + 1] << 8, v = MAPI[w] !== undefined ? MAPI[w] : w;
    IM[i] = v & 0xff; IM[i + 1] = v >> 8;
  }
  const st = snap.r, sp = st.sp;
  IM[sp] = RET & 0xff; IM[sp + 1] = RET >> 8;
  const r = cpu.regs; r[0] = st.b; r[1] = st.c; r[2] = st.d; r[3] = st.e; r[4] = st.h; r[5] = st.l; r[7] = st.a;
  cpu.cf = st.f & 1; cpu.zf = (st.f >> 6) & 1; cpu.sf = st.f >> 7; cpu.pf = (st.f >> 2) & 1;
  cpu.sp = sp; cpu.pc = entry; cpu.iff = false;
  IM[RT] = st.ix & 0xff; IM[RT + 1] = st.ix >> 8; IM[RT + 2] = st.iy & 0xff; IM[RT + 3] = st.iy >> 8;
  const log = []; let n = 0, t = 0;
  while (!((cpu.pc & 0xffff) === RET && (cpu.sp & 0xffff) === ((sp + 2) & 0xffff))) {
    if (++n > 2e6) return null;
    const pc = cpu.pc & 0xffff;
    if (!gameI[pc]) {                                       // platform: log, then RET
      log.push([pc, { a: r[7], bc: r[0] << 8 | r[1], de: r[2] << 8 | r[3], hl: r[4] << 8 | r[5],
        ix: IM[RT] | IM[RT + 1] << 8, iy: IM[RT + 2] | IM[RT + 3] << 8 }]);
      cpu.pc = IM[cpu.sp & 0xffff] | IM[(cpu.sp + 1) & 0xffff] << 8; cpu.sp = (cpu.sp + 2) & 0xffff;
      continue;
    }
    const before = cpu.cycles || 0;
    const ret = cpu.instruction();
    t += (cpu.vcycles || ret || ((cpu.cycles || 0) - before) || 0);
  }
  return { r: { a: r[7], b: r[0], c: r[1], d: r[2], e: r[3], h: r[4], l: r[5], cf: +!!cpu.cf, zf: +!!cpu.zf,
    ix: IM[RT] | IM[RT + 1] << 8, iy: IM[RT + 2] | IM[RT + 3] << 8 }, mem: IM.slice(), log, t, sp };
}
// ---- the model, free -------------------------------------------------------------------------
const EMPTY = { ev: [], mem0: Buffer.alloc(0xC000).toString('base64'), scenario: {} };
function runM(snap) {
  const m = new Machine(EMPTY, { procs, free: true });
  m.mem.set(snap.mem); Object.assign(m.r, snap.r);
  m.call(snap.pc);
  const r = m.r;
  return { r: { ...r, cf: r.f & 1, zf: (r.f >> 6) & 1 }, mem: m.mem, log: m.log.map(([t, v]) => [t, {
    a: v[0], bc: v[2] << 8 | v[3], de: v[4] << 8 | v[5], hl: v[6] << 8 | v[7], ix: v[16], iy: v[17] }]) };
}

// ---- snapshots ---------------------------------------------------------------------------------
const GOLDENS = (process.env.GOLDENS || '1p_chase,2p_random,fouls_end,search_1011,1p_nba_mix,names_long,menu_music').split(',');
const PER = +(process.env.PER || 12);
const snaps = [];
for (const gname of GOLDENS) {
  const tr = JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(ROOT, 'research/golden', gname + '.json.gz'))));
  const m = new Machine(tr, { procs });
  const seen = {}, got = {};
  const orig = m.runProc.bind(m);
  m.runProc = (pc) => {
    if (ENTRIES.includes(pc) || FROM.includes(pc)) {
      seen[pc] = (seen[pc] || 0) + 1;
      if ((got[pc] || 0) < PER && seen[pc] % 23 === 1) {
        got[pc] = (got[pc] || 0) + 1;
        const st = { g: gname, r: { ...m.r }, mem: m.mem.slice() };
        if (ENTRIES.includes(pc)) snaps.push({ pc, ...st });
        if (FROM.includes(pc)) for (const e of ENTRIES) {
          const mem = st.mem.slice();
          for (const b of [st.r.ix, st.r.iy]) if (!mem[(b - 4) & 0xffff]) mem[(b - 4) & 0xffff] = 1;
          snaps.push({ pc: e, ...st, mem });
        }
      }
    }
    return orig(pc);
  };
  m.run();
}
function mutate(mem, r) {
  for (const base of [r.ix, r.iy]) {
    const k = Math.floor(rnd() * 4);
    for (let i = 0; i < k; i++) {
      const dd = -7 + Math.floor(rnd() * 0x1A), a = (base + dd) & 0xffff;
      if (dd === -4) { mem[a] = 1 + Math.floor(rnd() * 0x1F); continue; }   // action step counter, >= 1 in play
      if (rnd() < 0.7) mem[a] ^= 1 << Math.floor(rnd() * 8); else mem[a] = Math.floor(rnd() * 256);
    }
  }
  for (const base of [r.ix, r.iy]) if (!mem[(base - 4) & 0xffff]) mem[(base - 4) & 0xffff] = 1;   // a shot reads 943A[(ix-4)-1]
  if (rnd() < 0.5) mem[0x93EB] ^= 1 << Math.floor(rnd() * 8);
  if (rnd() < 0.3) { mem[0x93F3] = 0x40 + Math.floor(rnd() * 0x30); mem[0x93F4] = Math.floor(rnd() * 0x74); }
  if (rnd() < 0.3) { mem[0x93F1] = Math.floor(rnd() * 0x40); mem[0x93F2] = Math.floor(rnd() * 0x74); }
}

// ---- compare -------------------------------------------------------------------------------------
let runs = 0, ok = 0, bad = 0, skip = 0, tsum = 0, tn = 0;
const fails = [];
for (const s of snaps) {
  for (let t = 0; t <= TRIALS; t++) {
    const snap = t ? { ...s, mem: s.mem.slice() } : s;
    if (t) mutate(snap.mem, s.r);
    runs++;
    let mr;
    try { mr = runM(snap); } catch (e) { if (e instanceof Mismatch || /not modelled/.test(e.message)) { skip++; continue; } throw e; }
    const ir = runI(snap, MAPI[s.pc]);
    if (!ir) { bad++; fails.push(`${hx(s.pc)} (${s.g}) trial ${t}: i8080 did not return`); continue; }
    tsum += ir.t; tn++;
    const d = [];
    for (const k of OUT) {
      const mv = k.length === 2 && k !== 'cf' && k !== 'zf' && k !== 'ix' && k !== 'iy' ? (mr.r[k[0]] << 8 | mr.r[k[1]]) : mr.r[k];
      const iv = k.length === 2 && k !== 'cf' && k !== 'zf' && k !== 'ix' && k !== 'iy' ? (ir.r[k[0]] << 8 | ir.r[k[1]]) : ir.r[k];
      if (!(mv === iv || eqw(mv, iv))) d.push(`${k} ${hx(mv, 2)}/${hx(iv, 2)}`);
    }
    for (let a = 0; a < 0x10000 && d.length < 10; a++) {
      if (codeZ[a] || usedI[a] || (a >= RT && a < RT_END)) continue;
      if (a >= 0xBC00 && a < ir.sp + 2) continue;
      if (a === DP_COST || a === DP_COST + 1) continue;
      const zv = mr.mem[a], iv = ir.mem[a];
      if (zv === iv) continue;
      const before = i8080Mem(snap.mem)[a];
      if (iv === before && snap.mem[a] === zv) continue;                  // untouched (static image difference)
      if (a < 0xffff && eqw(zv | mr.mem[a + 1] << 8, iv | ir.mem[a + 1] << 8)) { a++; continue; }
      d.push(`(${hx(a)}) ${hx(zv, 2)}/${hx(iv, 2)}`);
    }
    for (const [z, i, n] of CELLS) if (mr.mem[z] !== ir.mem[i]) d.push(`${n} ${hx(mr.mem[z], 2)}/${hx(ir.mem[i], 2)}`);
    for (const [z, i, n] of SMCW) {
      const zw = mr.mem[z] | mr.mem[z + 1] << 8, iw = ir.mem[i] | ir.mem[i + 1] << 8;
      if (!eqw(zw, iw)) d.push(`${n} ${hx(zw)}/${hx(iw)}`);
    }
    if (mr.log.length !== ir.log.length) d.push(`platform calls ${mr.log.length}/${ir.log.length}`);
    else for (let i = 0; i < mr.log.length; i++) {
      const [tz, rz] = mr.log[i], [ti, ri] = ir.log[i];
      const pb = pargsOf(tz).filter((k) => !eqw(pick(rz, k), pick(ri, k)));
      if (tz !== ti || pb.length) { d.push(`platform call ${i} ${hx(tz)}/${hx(ti)} ${pb.map((k) => `${k} ${hx(pick(rz, k))}/${hx(pick(ri, k))}`).join(' ')}`); break; }
    }
    if (d.length) { bad++; if (fails.length < 15) fails.push(`${hx(s.pc)} (${s.g}) trial ${t}: model/i8080 ${d.join(' ')}`); } else ok++;
  }
}
for (const f of fails) console.log('  ' + f);
console.log(`UNIT ${NAME}: snapshots ${snaps.length}, runs ${runs}, same ${ok}, different ${bad}, skipped ${skip}; i8080 ${tn ? (tsum / tn).toFixed(0) : '-'} T per call`);
process.exit(bad ? 1 : 0);
