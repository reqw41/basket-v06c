#!/usr/bin/env node
/**
 * A0 search: random scenarios (cover-only runs of golden.js, parallel) that
 * reach game instructions no golden covers yet; a hit is saved as
 * research/golden/scenarios/search_<n>.json (then record it with golden_one.sh).
 *   node tools/native/golden_search.js [runs=24] [jobs=8] [first-seed=1000]
 */
'use strict';
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { execFile } = require('child_process');

const ROOT = path.join(__dirname, '../..');
const BOT = process.env.BOT || 'mix';
const RUNS = +(process.argv[2] || 24), JOBS = +(process.argv[3] || 8), SEED0 = +(process.argv[4] || 1000);
const TMP = path.join(ROOT, 'build/native/search');
fs.mkdirSync(TMP, { recursive: true });

const inv = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/native/inventory.json'), 'utf8'));
const skip = new Set();
for (const f of ['cfg/native_dead.json', 'cfg/native_waits.json']) {
  for (const k of Object.keys(JSON.parse(fs.readFileSync(path.join(ROOT, f), 'utf8')))) {
    const [lo, hi] = k.split('-').map((h) => parseInt(h, 16));
    for (let a = lo; a <= (hi ?? lo); a++) skip.add(a);
  }
}
const covered = new Set();
const GD = path.join(ROOT, 'research/golden');
for (const f of fs.readdirSync(GD).filter((f) => f.endsWith('.json.gz'))) {
  for (const a of JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(GD, f)))).cover) covered.add(a);
}
const missing = new Set();
for (const p of inv.procs) for (const a of p.body) if (!covered.has(a) && !skip.has(a)) missing.add(a);
console.log(`missing ${missing.size}`);

function scenario(seed) {
  let x = seed * 2654435761 >>> 0;
  const r = () => { x ^= x << 13; x >>>= 0; x ^= x >>> 17; x ^= x << 5; x >>>= 0; return x / 4294967296; };
  const two = r() < 0.5, steps = [{ wait: 'menu' }];
  for (let i = Math.floor(r() * 3); i > 0; i--) steps.push({ key: '3' });
  steps.push({ key: two ? '2' : '1' }, { wait: 'match' });
  steps.push(two ? { bot: BOT, bot2: BOT, until: 'menu' } : { bot: BOT, until: 'menu' }, { idle: 100 });
  return { name: `search_${seed}`, seed, clock: '030', frames: 16000, steps };
}

const hits = [];
let next = 0, running = 0;
function launch() {
  while (running < JOBS && next < RUNS) {
    const seed = SEED0 + next++;
    const sc = scenario(seed), sf = path.join(TMP, `${sc.name}.json`), of = path.join(TMP, `${sc.name}.out.json`);
    fs.writeFileSync(sf, JSON.stringify(sc));
    running++;
    execFile('node', [path.join(__dirname, 'golden.js'), sf, of], { env: { ...process.env, COVER_ONLY: '1' }, maxBuffer: 1 << 26 }, (err) => {
      running--;
      if (err) console.log(`${sc.name}: ${err.message.split('\n')[0]}`);
      else {
        const res = JSON.parse(fs.readFileSync(of, 'utf8'));
        const fresh = res.cover.filter((a) => missing.has(a));
        console.log(`${sc.name}: frames ${res.stats.frames} new ${fresh.length}${fresh.length ? ' ' + fresh.slice(0, 12).map((a) => a.toString(16)).join(' ') : ''}`);
        if (fresh.length) {
          for (const a of fresh) missing.delete(a);
          fs.writeFileSync(path.join(ROOT, 'research/golden/scenarios', `${sc.name}.json`), JSON.stringify(sc) + '\n');
          hits.push(sc.name);
        }
      }
      if (next < RUNS) launch(); else if (!running) console.log(`hits: ${hits.join(' ') || 'none'}; still missing ${missing.size}`);
    });
  }
}
launch();
