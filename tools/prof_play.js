#!/usr/bin/env node
/**
 * Live-play profile: tools/bench_play.js PCDUMP=… cycles by PC grouped by
 * procedure (adapter labels from build/v06/*.lst, game procedures P_xxxx,
 * il_/rt_ helpers of the i8080 image).
 *   CPU=i8080 node tools/prof_play.js [rom]   TOP=40
 * Beware: a label owns every byte up to the next label, so code after a
 * table or an include end is billed to the label before it.
 */
'use strict';
const fs = require('fs'), path = require('path'), cp = require('child_process'), os = require('os');
const ROOT = path.join(__dirname, '..');
const I8080 = process.env.CPU === 'i8080';
const dump = path.join(os.tmpdir(), `prof_play_${process.pid}.json`);
cp.execFileSync('node', [path.join(__dirname, 'bench_play.js'), ...process.argv.slice(2)], { env: { ...process.env, PCDUMP: dump }, stdio: ['ignore', 'inherit', 'ignore'] });
const { iters, pc } = JSON.parse(fs.readFileSync(dump)); fs.unlinkSync(dump);
const names = new Map(); const add = (a, n) => { if (!names.has(a)) names.set(a, n); };
const skip = new Set(['buffered_players.lst', 'color_sprite.lst', 'joy_p.lst', 'win_a4ab.lst']);   // stale units
for (const f of fs.readdirSync(path.join(ROOT, 'build/v06')).filter((x) => x.endsWith('.lst') && !skip.has(x)))
  for (const m of fs.readFileSync(path.join(ROOT, 'build/v06', f), 'utf8').matchAll(/^([A-Za-z_][A-Za-z0-9_]+)\s+= \$([0-9A-F]{4}) = +\d+\s+(\w+)\.asm/gm))
    if (!m[3].startsWith('labels') && m[3] !== 'cells') add(parseInt(m[2], 16), m[1]);
const map = I8080 ? JSON.parse(fs.readFileSync(path.join(ROOT, 'build/i8080/labels.json'))).map : null;
for (const m of fs.readFileSync(path.join(ROOT, 'disasm/v06/game.asm'), 'utf8').matchAll(/\bcall (?:\w+,)?Z_([0-9A-F]{4})/g)) {
  const a = I8080 ? (map[m[1]] ? parseInt(map[m[1]], 16) : null) : parseInt(m[1], 16); if (a !== null) add(a, 'P_' + m[1]); }
if (I8080) for (const m of fs.readFileSync(path.join(ROOT, 'build/i8080/game.lst'), 'utf8').matchAll(/^(il_\w+|rt_\w+)\s+= \$([0-9A-F]{4})/gm)) add(parseInt(m[2], 16), m[1]);
const entries = [...names.keys()].sort((a, b) => a - b);
const by = new Map(); let total = 0, j = -1;
for (let a = 0; a < 0x10000; a++) { while (j + 1 < entries.length && entries[j + 1] <= a) j++; if (!pc[a]) continue; total += pc[a];
  const n = j < 0 ? '?' : names.get(entries[j]); by.set(n, (by.get(n) || 0) + pc[a]); }
console.log(`live iterations ${iters}, ${(total / iters / 1000).toFixed(1)}k cycles/iter`);
for (const [n, c] of [...by].sort((a, b) => b[1] - a[1]).slice(0, +(process.env.TOP || 40)))
  console.log(`${(c / total * 100).toFixed(1).padStart(5)}%  ${(c / iters / 1000).toFixed(1).padStart(6)}k  ${n}`);
