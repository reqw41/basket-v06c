#!/usr/bin/env node
/**
 * A1 synthetic check: procedure entry snapshots from the goldens, with bits of
 * the player / ball / match state flipped at random, run twice from the same
 * state - the bare Z80 core and the JS model - with every platform call logged
 * and returning at once. Compared: all registers with F, all memory (but the
 * dead stack), the platform call log (target and registers). Also reports
 * which of the instructions the goldens never ran (docs/native/COVERAGE.md)
 * the Z80 runs reached.
 *
 *   node tools/native/model_fuzz.js [trials per snapshot, default 40] [seed]
 */
'use strict';
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { Machine, Mismatch, hx } = require('./machine');

const ROOT = path.join(__dirname, '../..');
const { procs } = require(path.join(ROOT, 'src/model'));
const TRIALS = +process.argv[2] || 40;
let seed = +process.argv[3] || 1;
const rnd = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x80000000; };

// entries to snapshot (called with CALL in the model) and how many per golden
const TARGETS = [0x9C83, 0x9599, 0x958F, 0x9391, 0x8C77, 0xA82C, 0x84DF, 0x84D6, 0x97D6, 0x93A3, 0x9ED4, 0xA232, 0x8E5A, 0x9919];
const PER = 6;
const GOLDENS = ['1p_chase', '2p_random', 'fouls_end', 'search_1011', '1p_nba_mix', 'search_1124'];

// the instructions the goldens never ran
const missing = new Set();
const lines = {};
for (const l of fs.readFileSync(path.join(ROOT, 'disasm/v06/game.asm'), 'utf8').split('\n')) {
  const m = /^\t(\w+)\s*([^;]*?)\s*;\s*([0-9A-F]{4})\s/.exec(l);
  if (m && !['db', 'dw', 'ds'].includes(m[1])) lines[parseInt(m[3], 16)] = `${m[1]} ${m[2]}`.trim();
}
const MISS = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/native/missing.json'), 'utf8')).map((h) => parseInt(h, 16));
for (const a of MISS) missing.add(a);

// ---- snapshots ------------------------------------------------------------------------
const snaps = [];
for (const g of GOLDENS) {
  const tr = JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(ROOT, 'research/golden', g + '.json.gz'))));
  const m = new Machine(tr, { procs });
  const got = {};
  const seen = {};
  const orig = m.runProc.bind(m);
  m.runProc = (pc) => {
    if (TARGETS.includes(pc)) {
      seen[pc] = (seen[pc] || 0) + 1;
      if ((got[pc] || 0) < PER && seen[pc] % 37 === 1) {
        got[pc] = (got[pc] || 0) + 1;
        snaps.push({ pc, g, r: { ...m.r }, mem: m.mem.slice() });
      }
    }
    return orig(pc);
  };
  m.run();
}
console.log(`snapshots: ${snaps.length}`);

// ---- mutation ----------------------------------------------------------------------------
const AREAS = [[0x9404, 0x9438], [0x93EB, 0x9402], [0x93D2, 0x93DA], [0x9451, 0x9452], [0x93E5, 0x93E6]];
const HOT = [[0x9400, 7], [0x93EB, 7], [0x93EB, 2], [0x93D6, 0], [0x93D3, 0], [0x93D3, 1], [0x93E5, 7]];
for (const base of [0x940B, 0x9425]) for (const d of [-2, -1, 0, 1]) for (let b = 0; b < 8; b++) HOT.push([base + d, b]);
const POS = [0x940D, 0x940E, 0x9427, 0x9428, 0x93F1, 0x93F3, 0x93F4];
const SMALL = [0x9408, 0x9422, 0x9415, 0x942F, 0x9416, 0x9430, 0x9413, 0x942D, 0x9414, 0x942E];
function mutate(mem, pc) {
  if (pc === 0xA82C) { mem[0x4110] = 0x20; }            // the replay ends at once
  const k = 1 + Math.floor(rnd() * 4);
  for (let i = 0; i < k; i++) {
    const w = rnd();
    if (w < 0.45) { const [a, b] = HOT[Math.floor(rnd() * HOT.length)]; mem[a] ^= 1 << b; continue; }
    if (w < 0.65) { mem[POS[Math.floor(rnd() * POS.length)]] = 0x08 + Math.floor(rnd() * 0x70); continue; }
    if (w < 0.75) { mem[SMALL[Math.floor(rnd() * SMALL.length)]] = Math.floor(rnd() * 7); continue; }
    if (w < 0.8) {                                     // the net animation at its end
      mem[0x93EB] |= 0x04;
      for (let a = 0x93DC; a < 0x93E5; a++) if (mem[a] === 0xFF) { mem[0x93DA] = a & 0xff; mem[0x93DB] = a >> 8; break; }
      continue;
    }
    const [lo, hi] = AREAS[Math.floor(rnd() * AREAS.length)];
    const a = lo + Math.floor(rnd() * (hi - lo));
    if (rnd() < 0.3) mem[a] = Math.floor(rnd() * 256); else mem[a] ^= 1 << Math.floor(rnd() * 8);
  }
}

// ---- runs ----------------------------------------------------------------------------------
const EMPTY = { ev: [], mem0: Buffer.alloc(0xC000).toString('base64'), scenario: {} };
function runOne(snap, mem, useModel) {
  const m = new Machine(EMPTY, { procs: useModel ? procs : {}, free: true });
  m.mem.set(mem);
  Object.assign(m.r, snap.r);
  const hit = new Set();
  if (!useModel) {
    const ri = m.cpu.run_instruction.bind(m.cpu);
    m.cpu.run_instruction = () => { hit.add(m.cpu.pc); return ri(); };
  }
  m.call(snap.pc);
  return { m, hit };
}

// player-context procedures run from the walk snapshots (ix = player, iy = the other)
const PLAYER = [0x9C83, 0x8E5A, 0x8E73, 0x8F76, 0x9009, 0x9041, 0x90EF, 0x9DC2, 0x9391, 0x9ED4, 0x9E82, 0x97D6, 0x8C16, 0x9599];
function mutatePlayer(mem, r) {
  const k = 1 + Math.floor(rnd() * 5);
  for (let i = 0; i < k; i++) {
    const d = -7 + Math.floor(rnd() * 0x1A), a = (r.ix + d) & 0xffff;
    if (rnd() < 0.7) mem[a] ^= 1 << Math.floor(rnd() * 8); else mem[a] = rnd() < 0.5 ? Math.floor(rnd() * 8) : Math.floor(rnd() * 256);
  }
  if (rnd() < 0.5) { mem[(r.ix + 2) & 0xffff] = 0x40 + Math.floor(rnd() * 0x30); mem[(r.ix + 3) & 0xffff] = Math.floor(rnd() * 0x74); }
  if (rnd() < 0.3) mem[(r.ix + 1) & 0xffff] ^= 1;
  if (rnd() < 0.3) mutate(mem, 0);
}

let trials = 0, same = 0, skipped = 0, bad = 0;
const reached = new Set();
const fails = [];
// exact cases for the branches the random runs do not reach (absolute pokes; ix/iy set)
const P1 = 0x940B, P2 = 0x9425;
const CASES = [
  { pc: 0x9599, ix: P1, iy: P2, poke: (m) => { m[P1] |= 0x22; m[P1 + 1] |= 1; m[P1 - 1] &= ~6; } },           // 988F 9891
  { pc: 0x9599, ix: P1, iy: P2, poke: (m) => { m[P1] |= 0x22; m[P1 + 1] |= 1; m[P1 - 1] = (m[P1 - 1] & ~4) | 2; } },
  { pc: 0x9391, ix: P1, iy: P2, poke: (m) => { m[P1 + 1] &= ~1; m[P1 + 2] = 0x49; m[P1 + 3] = 0x22; m[0x93D6] = 0; } },   // 9A13
  { pc: 0x9391, ix: P2, iy: P1, poke: (m) => { m[P2 + 1] &= ~1; m[P2 + 2] = 0x4A; m[P2 + 3] = 0x23; m[0x93D6] = 0; } },
  { pc: 0xA232, ix: P1, iy: P2, poke: (m) => { m[0x93E5] = 0x80; m[0x9400] = 0x82; } },                         // A257
  ...Array.from({ length: 24 }, (_, k) => ({                                                                  // 8BE2
    pc: 0x8ADD, ix: P1, iy: P2,
    poke: (m) => { m[0x93F5] = 0x02; m[0x93EB] = 0x02 | (k & 1 ? 0x80 : 0); m[0x9408] = k % 2; m[0x9422] = k % 2;
      m[0x944D] = (k * 37) & 0xff; m[0x944E] = (k * 91) & 0x1f; m[0x944F] = 0x40 + k * 5; m[0x9450] = (k * 13) & 0x3f; m[0x93D9] = 2; },
  })),
];

const runs = [];
const base = snaps.find((s) => s.pc === 0x9C83);
for (const c of CASES) {
  const mem = base.mem.slice(); c.poke(mem);
  runs.push({ ...base, pc: c.pc, r: { ...base.r, ix: c.ix, iy: c.iy }, mem, exact: true });
}
for (const snap of snaps) {
  runs.push(snap);
  if (snap.pc === 0x9C83) for (const pc of PLAYER) if (pc !== 0x9C83) runs.push({ ...snap, pc, player: true });
}
for (const snap of runs) {
  for (let t = 0; t < (snap.exact ? 1 : TRIALS); t++) {
    const mem = snap.mem.slice();
    if (t) { if (snap.player || snap.pc === 0x9C83) mutatePlayer(mem, snap.r); else mutate(mem, snap.pc); }
    trials++;
    let z, j;
    try { z = runOne(snap, mem, false); } catch (e) { skipped++; continue; }
    try { j = runOne(snap, mem, true); } catch (e) {
      if (e instanceof Mismatch || /not modelled/.test(e.message)) { skipped++; continue; }
      throw e;
    }
    for (const a of z.hit) if (missing.has(a)) reached.add(a);
    const diffs = [];
    for (const n of ['a', 'f', 'b', 'c', 'd', 'e', 'h', 'l', 'a_', 'f_', 'b_', 'c_', 'd_', 'e_', 'h_', 'l_', 'ix', 'iy', 'sp', 'pc']) {
      if (z.m.r[n] !== j.m.r[n]) diffs.push(`${n} ${hx(j.m.r[n], 2)}/${hx(z.m.r[n], 2)}`);
    }
    for (let a = 0; a < 0x10000; a++) {
      if (a >= 0xBC00 && a < z.m.r.sp) continue;
      if (z.m.mem[a] !== j.m.mem[a]) { diffs.push(`(${hx(a)}) ${hx(j.m.mem[a], 2)}/${hx(z.m.mem[a], 2)}`); if (diffs.length > 8) break; }
    }
    if (z.m.log.length !== j.m.log.length) diffs.push(`platform calls ${j.m.log.length}/${z.m.log.length}`);
    else for (let i = 0; i < z.m.log.length; i++) {
      const [ta, ra] = j.m.log[i], [tb, rb] = z.m.log[i];
      if (ta !== tb || ra.some((v, k) => k !== 19 && v !== rb[k])) { diffs.push(`platform call ${i}: ${hx(ta)} / ${hx(tb)}`); break; }
    }
    if (diffs.length) { bad++; if (fails.length < 12) fails.push(`${hx(snap.pc)} (${snap.g}) trial ${t}: JS/Z80 ${diffs.join(' ')}`); } else same++;
  }
}
console.log(`trials ${trials}: same ${same}, different ${bad}, skipped ${skipped} (dead / unmodelled code or a runaway)`);
for (const f of fails) console.log('  ' + f);
const left = [...missing].filter((a) => !reached.has(a)).sort((a, b) => a - b);
console.log(`never-run instructions reached: ${reached.size}/${missing.size}; still not: ${left.map((a) => hx(a)).join(' ') || '-'}`);
process.exit(bad ? 1 : 0);
