#!/usr/bin/env node
/**
 * A2: i8080 cycles of the game logic per iteration, by procedure of the
 * inventory (build/native/inventory.json) and by hand module. Every i8080 PC
 * of the game code goes to the Z80 instruction whose image holds it (the
 * address map), il_/rt_ runtime helpers stay apart (they are paid by their
 * callers), hand modules by their NAT_/Z_ symbols.
 *   CPU=i8080 node tools/native/prof_logic.js [rom]   env N (iterations), TOP
 */
'use strict';
const fs = require('fs');
const path = require('path');
const cp = require('child_process');
const ROOT = path.join(__dirname, '../..');
const dump = path.join(require('os').tmpdir(), `prof_logic_${process.pid}.bin`);
cp.execFileSync('node', [path.join(ROOT, 'tools/bench_play.js'), ...process.argv.slice(2)],
  { env: { ...process.env, CPU: 'i8080', PCDUMP: dump }, stdio: ['ignore', 'inherit', 'ignore'] });
const D = JSON.parse(fs.readFileSync(dump, 'utf8'));
const pc = D.pc, iters = D.iters;
const map = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/i8080/labels.json'), 'utf8')).map;
const owner = new Array(0x10000).fill(null);
// i8080 address -> Z80 instruction: sorted starts of the mapped instructions
const starts = Object.entries(map).map(([z, i]) => [parseInt(i, 16), parseInt(z, 16)]).sort((a, b) => a[0] - b[0]);
const inv = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/native/inventory.json'), 'utf8')).procs;
const procOf = new Map();
for (const p of inv) for (const a of p.body) procOf.set(a, p.entry);
const lst = fs.readFileSync(path.join(ROOT, 'build/i8080/game.lst'), 'utf8');
const sym = [];
for (const m of lst.matchAll(/^(\w+)\s+= \$([0-9A-F]{4})/gm)) sym.push([parseInt(m[2], 16), m[1]]);
sym.sort((a, b) => a[0] - b[0]);
const used = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/i8080/labels.json'), 'utf8')).used.map(([a, b]) => [parseInt(a, 16), parseInt(b, 16)]);
const inGame = (a) => used.some(([lo, hi]) => a >= lo && a <= hi);
let si = 0, mi = 0;
const by = new Map();
let total = 0, game = 0;
for (let a = 0; a < 0x10000; a++) {
  while (si + 1 < sym.length && sym[si + 1][0] <= a) si++;
  while (mi + 1 < starts.length && starts[mi + 1][0] <= a) mi++;
  if (!pc[a]) continue;
  total += pc[a];
  if (!inGame(a)) continue;
  game += pc[a];
  const s = sym[si] && sym[si][0] <= a ? sym[si][1] : '?';
  let k;
  if (/^(il_|rt_)/.test(s)) k = 'runtime ' + s.replace(/_\w*$/, '');
  else if (/^(NAT_|ct_)/.test(s) || (/^[a-z]{2}_/.test(s) && !/^Z_/.test(s))) k = 'native ' + s.split('_')[1];
  else {
    const z = starts[mi] && starts[mi][0] <= a ? starts[mi][1] : null;
    k = z !== null && procOf.has(z) ? 'P_' + procOf.get(z).toString(16).toUpperCase() : 'other ' + s;
  }
  by.set(k, (by.get(k) || 0) + pc[a]);
}
console.log(`iterations ${iters}: all ${(total / iters / 1000).toFixed(1)}k, game code ${(game / iters / 1000).toFixed(1)}k cycles/iter`);
for (const [k, v] of [...by].sort((a, b) => b[1] - a[1]).slice(0, +(process.env.TOP || 30)))
  console.log(`${(v / iters).toFixed(0).padStart(7)}  ${(100 * v / game).toFixed(1).padStart(5)}%  ${k}`);
fs.unlinkSync(dump);
