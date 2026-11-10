'use strict';
/**
 * JS model of the Basket Master game logic (A1, docs/NATIVE_PLAN.md).
 * procs: {Z80 entry address: fn(m)} — see tools/native/machine.js for the
 * interface. Modules are added here one by one; what is not listed runs as
 * Z80 code in the replay.
 */
const modules = ['rng', 'contact', 'action', 'setup', 'pdraw', 'move', 'math', 'flight', 'walk', 'stamina', 'score', 'stats', 'ai', 'ball', 'menu', 'replay', 'sound', 'sys', 'main', 'stubs'].map((n) => require('./' + n));
const procs = {};
for (const mod of modules) for (const [a, fn] of Object.entries(mod.procs)) procs[parseInt(a, 16)] = fn;
module.exports = { procs };
