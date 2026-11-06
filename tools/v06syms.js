// Adapter/game addresses by name for the stands: cfg/labels.json first
// (linked by tools/link_labels.py), then src/v06/cells.inc, then the unit
// listings in build/v06.
// Adapter entries float, so tests must not hard-code them.
'use strict';
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '..');

function load() {
  const m = {};
  const labels = JSON.parse(fs.readFileSync(path.join(ROOT, 'cfg/labels.json'), 'utf8')).labels;
  for (const [n, e] of Object.entries(labels)) m[n] = parseInt(e.addr, 16);
  // Adapter RAM cells (src/v06/cells.inc).
  const cells = fs.readFileSync(path.join(ROOT, 'src/v06/cells.inc'), 'utf8');
  for (const x of cells.matchAll(/^([A-Za-z_]\w*)\s+equ\s+0x([0-9A-Fa-f]+)/gm)) if (!(x[1] in m)) m[x[1]] = parseInt(x[2], 16);
  const dir = path.join(ROOT, 'build/v06');
  for (const f of fs.readdirSync(dir).filter((x) => x.endsWith('.lst')).sort()) {
    const t = fs.readFileSync(path.join(dir, f), 'utf8');
    for (const x of t.matchAll(/^([A-Za-z_]\w*)\s+= \$([0-9A-F]{4}) =\s+\d+\s+(\S+?):/gm)) {
      if (x[3].startsWith('labels') || x[3] === 'cells.inc') continue;
      if (!(x[1] in m)) m[x[1]] = parseInt(x[2], 16);
    }
  }
  return m;
}

const SYMS = load();
function sym(name) {
  if (!(name in SYMS)) throw new Error(`v06syms: no symbol ${name}`);
  return SYMS[name];
}
module.exports = { sym, SYMS };
