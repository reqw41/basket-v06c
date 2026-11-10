#!/usr/bin/env node
/**
 * A1 check: replay the goldens (research/golden/*.json.gz) through the JS model
 * of the logic (src/model/), without the emulator; code not modelled yet runs
 * as Z80 on a bare core (tools/native/machine.js).
 *
 *   node tools/native/model_run.js [golden.json.gz ...]     default: all goldens
 *   env ONLY=a,b / SKIP=a,b  subset of the JS procedures; SHADOW=1 each JS call vs Z80
 *   env STRICT=1  fail when the bare Z80 core runs any instruction (the model is complete)
 *   env ORACLE=1  no JS procedures: the Z80 code alone (F/F' and the stack compared too)
 */
'use strict';
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { Machine, Mismatch } = require('./machine');

const ROOT = path.join(__dirname, '../..');
const ORACLE = !!process.env.ORACLE;
const { procs } = ORACLE ? { procs: {} } : require(path.join(ROOT, 'src/model'));
// ONLY=8E5A,8F76  keep just these JS procedures; SKIP=...  drop these
const pick = (v) => (v || '').split(',').filter(Boolean).map((h) => parseInt(h, 16));
if (process.env.ONLY) { const k = new Set(pick(process.env.ONLY)); for (const a of Object.keys(procs)) if (!k.has(+a)) delete procs[a]; }
for (const a of pick(process.env.SKIP)) delete procs[a];
const files = process.argv.slice(2).length ? process.argv.slice(2)
  : fs.readdirSync(path.join(ROOT, 'research/golden')).filter((f) => f.endsWith('.json.gz')).sort().map((f) => path.join(ROOT, 'research/golden', f));
let bad = 0;
const stats = {};
for (const f of files) {
  const t0 = Date.now();
  const name = path.basename(f, '.json.gz');
  const m = new Machine(JSON.parse(zlib.gunzipSync(fs.readFileSync(f))), { procs, oracle: ORACLE, stats });
  try {
    m.run();
    if (process.env.STRICT && m.steps) throw new Mismatch(`${m.steps} Z80 instructions ran (the model is not complete)`);
    console.log(`ok   ${name}: ${m.ev.length} events, ${m.segs} checked, ${m.steps} Z80 instructions (${((Date.now() - t0) / 1000).toFixed(1)} s)`);
  } catch (e) {
    if (!(e instanceof Mismatch)) throw e;
    bad++;
    console.log(`FAIL ${name}: ${e.message}`);
  }
}
const n = Object.keys(procs).length;
if (n) console.log(`JS procedures: ${n}, called ${Object.values(stats).reduce((x, y) => x + y, 0)} times; never called: ${Object.keys(procs).filter((a) => !stats[a]).map((a) => (+a).toString(16)).join(' ') || '-'}`);
process.exit(bad ? 1 : 0);
