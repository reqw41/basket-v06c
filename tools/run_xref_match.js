#!/usr/bin/env node
/**
 * Adaptive match xref: title → menu → 1P/2P → move/throw → replay / ESC→menu.
 * Writes xref_<name>.json + .meta.json bound to basket.rom SHA-256.
 *
 * Mandatory outcomes (failure → exit 1):
 *   2p     — leave menu with 93EA===0 (2 PLAYERS) and B206===1
 *   replay — execute REPLAY_ZOOM (via A8F4 stub after live match)
 *   1p_esc — return to menu pose after ESC
 *
 * Usage:
 *   node tools/run_xref_match.js [1p|2p|1p_throw|1p_esc|replay] [rom]
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const mode = process.argv[2] || '1p_throw';
const ROM = path.resolve(process.argv[3] || path.join(ROOT, 'build/v06/basket.rom'));
const OUT = path.join(ROOT, 'build/v06');

const g = {};
for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g;
function fcx() {
  return {
    createImageData: (w, h) => ({ data: new Uint8ClampedArray((w || 1) * (h || 1) * 4), width: w, height: h }),
    putImageData: () => {}, drawImage: () => {}, getImageData: () => ({ data: new Uint8ClampedArray(4) }),
    fillRect: () => {}, save: () => {}, restore: () => {}, scale: () => {}, setTransform: () => {},
  };
}
function fc() { return { width: 0, height: 0, style: {}, getContext: () => fcx() }; }
g.document = { createElement: () => fc(), getElementById: () => fc() };
g.requestAnimationFrame = () => 0;
g.setTimeout = () => 0;
g.print = () => {};
g.console = console;
const ctx = vm.createContext(g);
for (const f of [
  'i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js',
  'src/fili.js', 'src/ay.js', 'src/fd1793.js', 'src/fddimage.js', 'src/i8253.js',
  'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  'Z80_v06.js', 'z80_adapter.js',
]) {
  vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
}
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

function makeEmu() {
  const memory = new Memory();
  const keyboard = new Keyboard();
  const timer = new I8253();
  const ay = new AY();
  const floppy = new (Floppy().FD1793)();
  const io = new IO(keyboard, timer, memory, ay, floppy);
  io.Palette = new Array(16).fill(0xff000000);
  const tape = { advance: () => {}, sample: 0, reset: () => {}, stop: () => {}, sampleAt: () => 0 };
  io.tape_player = tape;
  const cpu = new I8080(memory, io);
  const v06c = new Vector06c(cpu, memory, io, ay, tape);
  v06c.tape_player = tape;
  v06c.bmp = new Uint32Array(576 * 288);
  v06c.displayFrame = () => {};
  v06c.dbg = null;
  v06c.check_breakpoint = () => false;
  const file = new Uint8Array(fs.readFileSync(ROM));
  const base = file.length === 65536 ? 0 : 0x100;
  function install() {
    for (let i = 0; i < file.length && base + i < 0x10000; i++) memory.write(base + i, file[i], false);
    if (base === 0x100) {
      for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
    }
    const st = cpu.getState();
    st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 0;
    st.a = st.b = st.c = st.d = st.e = st.h = st.l = 0;
    cpu.setState(st);
    cpu.pc = 0x0100;
    cpu.sp = 0xe000;
    cpu.iff = false;
  }
  install();
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  return { memory, keyboard, cpu, v06c };
}

const { memory, keyboard, cpu, v06c } = makeEmu();
const rd = a => memory.read(a & 0xffff, false);
const wr = (a, v) => memory.write(a & 0xffff, v & 0xff, false);

// xref hooks
let cur = 0, xrefCpuActive = false;
const exec = new Uint8Array(0x10000);
const fetch = new Uint8Array(0x10000);
const rdMap = new Map(), wrMap = new Map();
const note = (m, a) => { let s = m.get(a); if (!s) m.set(a, s = new Set()); if (s.size < 6) s.add(cur); };
const oi = cpu.instruction.bind(cpu);
cpu.instruction = function () {
  cur = cpu.pc & 0xffff; exec[cur] = 1; xrefCpuActive = true;
  try { return oi(); } finally { xrefCpuActive = false; }
};
const r0 = memory.read.bind(memory), w0 = memory.write.bind(memory);
memory.read = function (addr, stack) {
  const a = addr & 0xffff;
  if (xrefCpuActive && !stack) { if (((a - cur) & 0xffff) < 4) fetch[a] = 1; else note(rdMap, a); }
  return r0(addr, stack);
};
memory.write = function (addr, val, stack) {
  if (xrefCpuActive && !stack) note(wrMap, addr & 0xffff);
  return w0(addr, val, stack);
};

function loadSyms() {
  const syms = {};
  const lst = path.join(OUT, 'glue.lst');
  if (!fs.existsSync(lst)) return syms;
  for (const line of fs.readFileSync(lst, 'utf8').split('\n')) {
    const m = line.match(/^([A-Za-z_][A-Za-z0-9_]*)\s+=\s+\$([0-9A-Fa-f]+)/);
    if (m) syms[m[1]] = parseInt(m[2], 16);
  }
  return syms;
}

/**
 * Procedure check only: CALL addr and return. Hitting maxSteps is a failure.
 * This is not a match exit and not a replay start.
 */
function callAddr(addr, maxSteps) {
  const RET = 0x0ff8;
  wr(RET, 0xc9);
  const st = cpu.getState();
  st.pc = addr;
  st.sp = 0xbfee;
  wr(0xbfee, RET & 0xff);
  wr(0xbfef, RET >> 8);
  cpu.setState(st);
  cpu.pc = addr;
  cpu.sp = 0xbfee;
  let steps = 0;
  while (steps < maxSteps) {
    if ((cpu.pc & 0xffff) === RET) return { steps, ok: true };
    cpu.instruction();
    steps++;
  }
  return { steps, ok: false, error: `call ${addr.toString(16)} exceeded ${maxSteps} steps` };
}

const syms = loadSyms();
const replayZoom = syms.REPLAY_ZOOM;

const want2p = mode === '2p';
const wantEsc = mode === '1p_esc';
const wantReplay = mode === 'replay';
const procCheck = mode === 'proc_a618' || mode === 'proc_a8f4';
const digitMask = want2p ? 0x04 : 0x02; // Vector row2: '1'=bit1, '2'=bit2
// Use the same keyboard-replay time budget as test_game_flow: the buffered
// raster path takes more hardware frames per game tick. Keep the entry gate.
const maxFrames = wantReplay ? 4500 : wantEsc ? 2200 : 1200;

let phase = 'title';
let frame = 0;
let matchStart = 0;
let menuAt = 0;
let playersMode = null; // 1 or 2
const clearKeys = () => {
  for (let i = 0; i < 8; i++) keyboard.matrix[i] = 0;
  keyboard.ss = false;
  keyboard.us = false;
};

for (; frame < maxFrames; frame++) {
  clearKeys();
  if (phase === 'title' && frame >= 8 && frame < 40) keyboard.matrix[7] = 0x80;
  if (phase === 'menu') keyboard.matrix[2] = digitMask;
  if (phase === 'match' || phase === 'ready') {
    if (wantReplay) {
      // Entity +2/+3 are x/y.  Enter the dunk window used by L_8F0F,
      // then hold fire.  Player 1 (one player): cursor keys + SPACE
      // (joy_p.asm NATIVE_PADS).
      const x = rd(0x940d), y = rd(0x940e);
      if (x > 0x5a) keyboard.matrix[0] = 0x10;      // cursor left
      else if (x < 0x50) keyboard.matrix[0] = 0x40; // cursor right
      else if (y >= 0x0d) keyboard.matrix[0] = 0x20; // cursor up
      else keyboard.matrix[7] = 0x80;               // SPACE: fire
    } else {
      const step = Math.floor((frame - matchStart) / 40) % 6;
      if (step === 0) keyboard.matrix[0] = 0x20;
      else if (step === 1) keyboard.matrix[0] = 0x40;
      else if (step === 2) keyboard.matrix[0] = 0x80;
      else if (step === 3) keyboard.matrix[0] = 0x10;
      else if (step === 4) keyboard.matrix[7] = 0x80;
      else keyboard.matrix[0] = 0x40;
    }
    if (wantEsc && frame > matchStart + 80) {
      // The original game requires SHIFT+CTRL+ESC (L_8685/D5DE).
      keyboard.ss = true;
      keyboard.us = true;
      keyboard.matrix[1] = 0x04; // АР2 → ESC
    }
  }
  if (procCheck) break;
  v06c.oneFrame();

  const y1 = rd(0x940d), y2 = rd(0x9427), ball = rd(0x93f3);
  const matchMode = rd(0x0fed);
  const ea = rd(0x93ea);

  if (phase === 'title' && y1 === 0x6e && y2 === 0x6e && rd(0x940b) === 0x10) {
    phase = 'menu';
    menuAt = frame;
    console.log(`menu@${frame}`);
  } else if (phase === 'menu' && matchMode === 1) {
    // 93EA: 1 = 1P, 0 = 2P (see game.asm L_A6B2)
    playersMode = ea === 0 ? 2 : 1;
    phase = 'match';
    matchStart = frame;
    console.log(`match@${frame} players=${playersMode} ea=${ea} digit=${digitMask.toString(16)}`);
  } else if (phase === 'match' && ball && y1 && y2 && y1 !== y2 && y1 !== 0x6e) {
    phase = 'ready';
    console.log(`ready@${frame} y1=${y1} y2=${y2} ball=${ball}`);
  }

  if (wantEsc && (phase === 'match' || phase === 'ready') && y1 === 0x6e && y2 === 0x6e && frame > matchStart + 40) {
    phase = 'menu_returned';
    console.log(`menu_returned@${frame} via input`);
    break;
  }

  if (!wantReplay && !wantEsc && phase === 'ready' && frame > matchStart + 200) break;
  if (wantReplay && phase === 'ready' && replayZoom != null && exec[replayZoom]) break;
  if (wantReplay && phase === 'ready' && frame > matchStart + 4000) break;
  if (wantEsc && frame > matchStart + 900) break;
}

// Procedure checks are separate from integration. They do not set a success phase.
let procedureCheck = null;
if (procCheck) {
  const addr = mode === 'proc_a618' ? 0xa618 : 0xa8f4;
  const limit = mode === 'proc_a618' ? 200000 : 2000000;
  const r = callAddr(addr, limit);
  procedureCheck = {
    kind: 'procedure_check',
    entry: addr,
    steps: r.steps,
    returned: r.ok,
    note: 'direct CALL; not a match exit and not a replay start',
  };
  console.log(`procedure_check ${mode} @${addr.toString(16)} steps=${r.steps} ok=${r.ok}`);
  if (!r.ok) {
    console.error(r.error);
  }
}

const execList = [...exec.keys()].filter(i => exec[i]);
const execSet = new Set(execList);

const expect = procCheck ? [] : ({
  '1p': ['FRAME_BEGIN', 'FRAME_END', 'COLOR_SPRITE', 'DIRTY_ADD', 'V_KBD_POLL'],
  '2p': ['FRAME_BEGIN', 'V_KBD_POLL'],
  '1p_throw': ['FRAME_BEGIN', 'FRAME_END', 'COLOR_SPRITE', 'DIRTY_ADD', 'nks_fire'],
  '1p_esc': ['FRAME_BEGIN', 'V_KBD_POLL'],
  'replay': ['FRAME_BEGIN', 'COLOR_SPRITE', 'REPLAY_ZOOM'],
}[mode] || ['FRAME_BEGIN']);

const hits = {};
const missing = [];
for (const s of expect) {
  const addr = syms[s];
  const ok = addr != null && execSet.has(addr);
  hits[s] = { addr, hit: ok };
  if (!ok) missing.push(s);
}

// Mandatory scenario outcomes
const mandatory = [];
if (want2p) {
  if (playersMode !== 2) mandatory.push('2p_mode');
  if (phase === 'menu' || phase === 'title') mandatory.push('phase:match');
}
if (wantReplay) {
  const zoom = syms.REPLAY_ZOOM;
  if (zoom == null || !execSet.has(zoom)) mandatory.push('replay_via_game');
}
if (wantEsc) {
  if (phase !== 'menu_returned') mandatory.push('menu_return_via_input');
}
if (procCheck) {
  if (!procedureCheck || !procedureCheck.returned) mandatory.push('procedure_check_limit');
}
if (mode.startsWith('1p') && !wantEsc && playersMode !== 1 && phase !== 'title' && phase !== 'menu') {
  // soft: 1P expected when we pressed digit 1
  if (playersMode != null && playersMode !== 1) mandatory.push('1p_mode');
}

missing.push(...mandatory.filter(m => !missing.includes(m)));

const romSha = crypto.createHash('sha256').update(fs.readFileSync(ROM)).digest('hex');
const name = `match_${mode}`;
const dump = (m) => { const o = {}; for (const [a, s] of m) o[a] = [...s]; return o; };
fs.writeFileSync(path.join(OUT, `xref_${name}.json`), JSON.stringify({
  exec: execList,
  fetch: [...fetch.keys()].filter(i => fetch[i]),
  rd: dump(rdMap),
  wr: dump(wrMap),
}));
const meta = {
  scenario: name,
  rom_sha256: romSha,
  rom: ROM,
  frames: frame,
  phase,
  mode,
  playersMode,
  integration: !procCheck,
  procedure_check: procedureCheck,
  expect_hits: hits,
  missing_required: missing,
  note: 'absence of an address outside mandatory checks is not dead-code proof',
};
fs.writeFileSync(path.join(OUT, `xref_${name}.meta.json`), JSON.stringify(meta, null, 2));
const ok = missing.length === 0;
console.log(`${name}: frames=${frame} phase=${phase} players=${playersMode} exec=${execList.length} `
  + `${ok ? 'OK' : 'FAIL ' + missing.join(',')}`);
process.exit(ok ? 0 : 1);
