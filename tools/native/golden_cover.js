#!/usr/bin/env node
/**
 * A0 coverage: union of the executed game instructions over all goldens
 * (research/golden/*.json.gz), per procedure of the inventory
 * (build/native/inventory.json, tools/native/inventory.py).
 *
 *   node tools/native/golden_cover.js [--md docs/native/COVERAGE.md]
 *
 * cfg/native_dead.json: {"ADDR" or "LO-HI": "reason"} — instructions that no
 * scenario can reach (dead code with a reason); they count as covered, and so
 * do the platform waits of cfg/native_waits.json (traced as adapter calls).
 * Exit 1 if a live instruction is not covered.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const ROOT = path.join(__dirname, '../..');
const DIR = path.join(ROOT, 'research/golden');
const mdArg = process.argv.indexOf('--md');
const MD = mdArg > 0 ? process.argv[mdArg + 1] : path.join(ROOT, 'docs/native/COVERAGE.md');
const inv = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/native/inventory.json'), 'utf8'));
const deadCfg = fs.existsSync(path.join(ROOT, 'cfg/native_dead.json'))
  ? JSON.parse(fs.readFileSync(path.join(ROOT, 'cfg/native_dead.json'), 'utf8')) : {};
const waitsCfg = JSON.parse(fs.readFileSync(path.join(ROOT, 'cfg/native_waits.json'), 'utf8'));
const dead = new Map();
for (const [k, why] of Object.entries({ ...deadCfg, ...waitsCfg })) {
  const [lo, hi] = k.split('-').map((h) => parseInt(h, 16));
  for (let a = lo; a <= (hi ?? lo); a++) dead.set(a, why);
}

const cover = new Map();   // addr -> first scenario
const scen = [];
for (const f of fs.readdirSync(DIR).filter((f) => f.endsWith('.json.gz')).sort()) {
  const tr = JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(DIR, f))));
  let fresh = 0;
  for (const a of tr.cover) if (!cover.has(a)) { cover.set(a, tr.scenario.name); fresh++; }
  scen.push({ name: tr.scenario.name, cover: tr.cover.length, fresh, frames: tr.stats.frames, iters: tr.stats.iters, events: tr.stats.events });
}
const hx = (a) => a.toString(16).toUpperCase().padStart(4, '0');
const ranges = (list) => {
  const out = []; let lo = null, prev = null;
  for (const a of list) {
    if (lo !== null && a - prev <= 4) { prev = a; continue; }
    if (lo !== null) out.push(lo === prev ? hx(lo) : `${hx(lo)}..${hx(prev)}`);
    lo = prev = a;
  }
  if (lo !== null) out.push(lo === prev ? hx(lo) : `${hx(lo)}..${hx(prev)}`);
  return out;
};
let total = 0, hit = 0, deadN = 0;
const rows = [];
for (const p of inv.procs) {
  const miss = p.body.filter((a) => !cover.has(a) && !dead.has(a));
  const d = p.body.filter((a) => !cover.has(a) && dead.has(a)).length;
  total += p.body.length; hit += p.body.length - miss.length - d; deadN += d;
  rows.push({ p, miss, d });
}
const lines = ['# Покрытие эталонами (A0, tools/native/golden_cover.js)', '',
  `Команд игры: ${total}; исполнено: ${hit} (${(100 * hit / total).toFixed(1)}%); мёртвых с причиной: ${deadN}; ` +
  `не покрыто: ${total - hit - deadN}.`, '',
  '## Сценарии', '', '| сценарий | кадров | ходов | событий | команд | новых |', '|---|---|---|---|---|---|',
  ...scen.map((s) => `| ${s.name} | ${s.frames} | ${s.iters} | ${s.events} | ${s.cover} | ${s.fresh} |`), '',
  '## Непокрытые процедуры и участки', '', '| вход | команд | не покрыто | участки |', '|---|---|---|---|'];
for (const r of rows.filter((r) => r.miss.length).sort((a, b) => b.miss.length - a.miss.length)) {
  lines.push(`| ${hx(r.p.entry)} | ${r.p.body.length} | ${r.miss.length} | ${ranges(r.miss).join(' ')} |`);
}
if (Object.keys(deadCfg).length) {
  lines.push('', '## Мёртвый код (cfg/native_dead.json)', '');
  for (const [k, why] of Object.entries(deadCfg)) lines.push(`- ${k}: ${why}`);
}
lines.push('', '## Ожидания платформы (cfg/native_waits.json)', '');
for (const [k, why] of Object.entries(waitsCfg)) lines.push(`- ${k}: ${why}`);
fs.writeFileSync(MD, lines.join('\n') + '\n');
// the list for the A1 synthetic check (tools/native/model_fuzz.js)
fs.mkdirSync(path.join(ROOT, 'build/native'), { recursive: true });
fs.writeFileSync(path.join(ROOT, 'build/native/missing.json'), JSON.stringify(rows.flatMap((r) => r.miss).sort((a, b) => a - b).map(hx)));
console.log(`coverage ${hit}/${total} (${(100 * hit / total).toFixed(1)}%), dead ${deadN}, missing ${total - hit - deadN} -> ${path.relative(ROOT, MD)}`);
process.exit(total - hit - deadN ? 1 : 0);
