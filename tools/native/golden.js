#!/usr/bin/env node
/**
 * A0 goldens: the Z80 port image (build/v06/basket.rom, = MSX move for move)
 * played headless by a scenario; every switch between the game logic and
 * the platform is recorded.
 *
 *   node tools/native/golden.js research/golden/scenarios/<name>.json [out.json.gz]
 *
 * Game code = every instruction of disasm/v06/game.asm (window 84D0..B257
 * and system block 3300..3F7F, docs/native/INVENTORY.md); everything else
 * is the adapter (glue, renderer, BIOS stubs, IRQ handler).
 *
 * Trace (gzip JSON):
 *   mem0   base64 of 0000..BFFF at the first entry into game code (84D0)
 *   ev     [kind, pc, regs, diff] per event:
 *            kind 'O' game -> adapter (call / rst / jp out of a procedure)
 *                 'R' adapter -> game, back at the return address of an 'O'
 *                 'E' adapter -> game, a nested entry (game ISR, print, ...)
 *                 'L' game -> adapter, a nested entry returns
 *                 'M' mark: game main-loop iteration (8554), stays in game
 *            regs [a f b c d e h l a' f' b' c' d' e' h' l' ix iy sp iff1]
 *            diff [addr, value, ...]: bytes < C000 changed since the
 *                 previous event (screen planes C000..FFFF are not traced)
 *   cover  game instruction addresses executed
 *   stats  frames, iterations, events, IRQ deferrals
 *
 * The frame IRQ is held while the CPU is in game code and taken at the
 * first adapter instruction with interrupts on (the adapter's own waits run
 * there), so the game ISR (36F3) is always a nested entry 'E' inside an
 * adapter call: the logic between two events is a pure function of memory
 * and registers, which the JS model (A1) reproduces byte for byte.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const zlib = require('zlib');

const ROOT = path.join(__dirname, '../..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const SCEN = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const OUT = process.argv[3] || path.join(ROOT, 'research/golden', `${SCEN.name}.json.gz`);
const ROM = path.resolve(ROOT, SCEN.rom || 'build/v06/basket.rom');
const TRACE_TOP = 0xC000, STACK_LO = 0xBC00;
const COVER_ONLY = !!process.env.COVER_ONLY;
const PROBE = process.env.PROBE ? parseInt(process.env.PROBE, 16) : -1, probe = {};   // debug: A@TEXT_COL at a PC   // search mode: executed addresses only

// ---- game code map ----------------------------------------------------------
const RX = /^\t(\w+)\s*([^;]*?)\s*;\s*([0-9A-F]{4})\s+((?:[0-9A-F]{2}\s?)+)/;
const isGame = new Uint8Array(0x10000), insLen = new Uint8Array(0x10000);
for (const line of fs.readFileSync(path.join(ROOT, 'disasm/v06/game.asm'), 'utf8').split('\n')) {
  const m = RX.exec(line);
  if (!m || m[1] === 'db' || m[1] === 'dw' || m[1] === 'ds') continue;
  const a = parseInt(m[3], 16);
  isGame[a] = 1; insLen[a] = m[4].trim().split(/\s+/).length;
}
// Busy-wait procedures (cfg/native_waits.json; a delay loop spends real
// time, the frame IRQ runs meanwhile): traced as platform calls, so the
// IRQs they absorb are inside an 'O' event. The model calls them as waits.
// HALT is a wait too.
const WAITS = Object.fromEntries(Object.keys(JSON.parse(fs.readFileSync(path.join(ROOT, 'cfg/native_waits.json'), 'utf8'))).map((k) => k.split('-')));
for (const [lo, hi] of Object.entries(WAITS)) for (let a = parseInt(lo, 16); a <= parseInt(hi, 16); a++) isGame[a] = 0;

// ---- emulator ---------------------------------------------------------------
const g = {};
for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g;
const fcx = () => ({
  createImageData: (w, h) => ({ data: new Uint8ClampedArray((w || 1) * (h || 1) * 4), width: w, height: h }),
  putImageData: () => {}, drawImage: () => {}, getImageData: () => ({ data: new Uint8ClampedArray(4) }),
  fillRect: () => {}, save: () => {}, restore: () => {}, scale: () => {}, setTransform: () => {},
});
const fc = () => ({ width: 0, height: 0, style: {}, getContext: () => fcx() });
g.document = { createElement: () => fc(), getElementById: () => fc() };
g.requestAnimationFrame = () => 0; g.setTimeout = () => 0; g.print = () => {};
g.console = { ...console, log: () => {} };
const ctx = vm.createContext(g);
for (const f of [
  'i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js',
  'src/fili.js', 'src/ay.js', 'src/fd1793.js', 'src/fddimage.js', 'src/i8253.js',
  'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  'Z80_v06.js', 'z80_adapter.js',
]) vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

const memory = new Memory(), keyboard = new Keyboard(), timer = new I8253(), ay = new AY();
const io = new IO(keyboard, timer, memory, ay, new (Floppy().FD1793)());
io.Palette = new Array(16).fill(0xff000000);
const tape = { advance: () => {}, sample: 0, reset: () => {}, stop: () => {}, sampleAt: () => 0 };
io.tape_player = tape;
const cpu = new I8080(memory, io);
const v06c = new Vector06c(cpu, memory, io, ay, tape);
Object.assign(v06c, { tape_player: tape, bmp: new Uint32Array(576 * 288), displayFrame: () => {}, dbg: null, check_breakpoint: () => false });
{
  const file = new Uint8Array(fs.readFileSync(ROM));
  for (let i = 0; i < file.length && 0x100 + i < 0x10000; i++) memory.write(0x100 + i, file[i], false);
  for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
  // shorter halves: the clock template 93E2..93E4 ("500" = 5:00) is part of mem0
  if (SCEN.clock) for (let i = 0; i < 3; i++) memory.write(0x93e2 + i, SCEN.clock.charCodeAt(i), false);
  const st = cpu.getState();
  Object.assign(st, { pc: 0x0100, sp: 0xe000, iff1: 0, iff2: 0, halted: false, imode: 1 });
  cpu.setState(st);
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
}
const rd = (a) => memory.read(a & 0xffff, false);
const rd16 = (a) => rd(a) | rd(a + 1) << 8;

// joysticks «П» on PPI2 (port 5 selects, port 6 reads, 0 = pressed)
let joyA = 0, joyB = 0, joySel = 0x9f;
{
  const ioIn = io.input.bind(io), ioOut = io.output.bind(io);
  io.output = (p, v) => { if ((p & 0xff) === 5) joySel = v & 0xff; return ioOut(p, v); };
  io.input = (p) => {
    if ((p & 0xff) !== 6) return ioIn(p);
    const j = joySel === 0xdf ? joyB : joySel === 0xbf ? joyA : (joyA | joyB);
    return ~j & 0xff;
  };
}

// ---- tracing ----------------------------------------------------------------
const shadow = new Uint8Array(TRACE_TOP), dirty = new Uint8Array(TRACE_TOP), dirtyList = [];
{
  const w = memory.write.bind(memory);
  memory.write = (a, v, s) => {
    a &= 0xffff;
    if (a < TRACE_TOP && !dirty[a]) { dirty[a] = 1; dirtyList.push(a); }
    return w(a, v, s);
  };
}
function diff() {
  const d = [];
  dirtyList.sort((x, y) => x - y);
  for (const a of dirtyList) {
    dirty[a] = 0;
    const v = rd(a);
    // stack bytes are recorded on every write, even unchanged: a JS model keeps
    // no Z80 stack of its own, and must see the platform's return addresses
    if (v !== shadow[a] || a >= STACK_LO) { d.push(a, v); shadow[a] = v; }
  }
  dirtyList.length = 0;
  return d;
}
const F = (f) => f.S << 7 | f.Z << 6 | f.Y << 5 | f.H << 4 | f.X << 3 | f.P << 2 | f.N << 1 | f.C;
function regs() {
  const s = cpu.getState();
  return [s.a, F(s.flags), s.b, s.c, s.d, s.e, s.h, s.l,
    s.a_prime, F(s.flags_prime), s.b_prime, s.c_prime, s.d_prime, s.e_prime, s.h_prime, s.l_prime,
    s.ix, s.iy, s.sp, s.iff1];
}

const ev = [], cover = new Uint8Array(0x10000);
let mem0 = null, world = 0, prevPc = 0, pokes = null;
const frames = [];      // stack: {k: 'O', ret, sp} | {k: 'E', sp}
const stats = { frames: 0, iters: 0, events: 0, deferred: 0, forced: 0, merged: 0, halts: 0, jpOut: {}, landElsewhere: {}, odd: [] };
const MARKS = new Set((SCEN.marks || ['8554']).map((h) => parseInt(h, 16)));
const hx = (v) => v.toString(16);
const odd = (s) => { if (stats.odd.length < 50) stats.odd.push(s); };

function onSwitch(pc) {
  const sp = cpu.sp & 0xffff;
  // frames whose stack has been unwound (sp above their return slot) are gone
  // (an ISR that came out of a HALT in game code returns into game code: its E
  // frame is left behind; it is stale once the stack is at or above its slot
  // and the switch is not its return)
  while (frames.length && frames[frames.length - 1].sp >= 0 && (frames[frames.length - 1].sp < sp
    || (frames[frames.length - 1].k === 'E' && frames[frames.length - 1].sp === sp && pc !== frames[frames.length - 1].ret))) {
    if (isGame[pc] && frames[frames.length - 1].k === 'O') break;   // an R below
    const f = frames.pop();
    if (f.k === 'O') odd(`O ${hx(f.from)}->${hx(f.to)} unwound without return (now ${hx(pc)} sp ${hx(sp)})`);
  }
  const top = frames[frames.length - 1];
  let kind;
  if (isGame[pc]) {                         // adapter -> game
    if (top && top.k === 'O' && sp >= top.sp) {   // back from the call (the adapter may land elsewhere)
      kind = 'R'; frames.pop();
      if (pc !== top.ret || sp !== top.sp) {
        const k = `${hx(top.from)}->${hx(top.to)} lands ${hx(pc)}`;
        stats.landElsewhere[k] = (stats.landElsewhere[k] || 0) + 1;
      }
    }
    else { kind = 'E'; frames.push({ k: 'E', sp: sp + 2, at: pc, ret: rd16(sp) }); }
  } else if (top && top.k === 'E' && sp === top.sp && pc === top.ret) {
    kind = 'L'; frames.pop();               // game -> adapter: a nested entry returns
  } else {                                  // game -> adapter: a call out
    kind = 'O';
    const op = rd(prevPc);
    const call = op === 0xcd || (op & 0xc7) === 0xc4 || (op & 0xc7) === 0xc7;
    if (!call) stats.jpOut[`${hx(prevPc)}->${hx(pc)}`] = (stats.jpOut[`${hx(prevPc)}->${hx(pc)}`] || 0) + 1;
    frames.push({ k: 'O', ret: rd16(sp), sp: sp + 2, from: prevPc, to: pc });
  }
  let from = prevPc;
  if (kind === 'O' && haltAt >= 0 && haltAt === prevPc - 1) { from = haltAt; stats.halts++; }   // IRQ out of HALT
  haltAt = -1;
  if (COVER_ONLY) { dirtyList.length = 0; ev.length = 1; } else ev.push([kind, pc, regs(), diff(), from]);
  if (frames.length > 64) frames.splice(0, 32);   // non-local exits (SP reset) leave stale frames
}

let pend = false, pendAge = 0, haltAt = -1;
const FORCE_AFTER = 200000;   // instructions held in game code before the IRQ is forced (logged)
v06c.checkInterrupt = function () {
  const pc = cpu.pc & 0xffff;
  if (this.irq && this.CPU.iff) {
    this.irq = false;
    if (pend) stats.merged++;
    if (!pend) pendAge = 0;
    pend = true;
  }
  if (!pend || !this.CPU.iff) return;
  if ((isGame[pc] || world) && mem0 && !(isGame[pc] && (haltAt = cpu.getState().halted ? pc - 1 : -1) >= 0)) {   // HALT: the game waits for the IRQ
    if (++pendAge < FORCE_AFTER) return;
    stats.forced++; odd(`IRQ forced in game code at ${pc.toString(16)}`);
  } else if (pendAge) stats.deferred++;
  pend = false;
  if (this.CPU.last_opcode === 0x76) this.CPU.pc += 1;
  this.CPU.execute(0xf3);
  this.CPU.execute(0xff);
  this.instr_time += 16;
};

{
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    const pc = cpu.pc & 0xffff;
    const w = isGame[pc];
    if (!mem0 && pc === 0x84d0) {
      mem0 = new Uint8Array(TRACE_TOP);
      for (let a = 0; a < TRACE_TOP; a++) { mem0[a] = shadow[a] = rd(a); dirty[a] = 0; }
      dirtyList.length = 0;
      world = 1;
      ev.push(['E', pc, regs(), []]);
      cover[pc] = 1;
      frames.push({ k: 'E', sp: -1 });
    } else if (mem0) {
      if (w !== world) { onSwitch(pc); world = w; }
      if (w) {
        cover[pc] = 1;
        if (pc === 0xa697) menuPoll = curFrame;
        if (pc === PROBE) { const k = `${hx(cpu.getState().a)}@${rd(0x4103)}`; probe[k] = (probe[k] || 0) + 1; }
        if (MARKS.has(pc)) { if (!COVER_ONLY) ev.push(['M', pc, regs(), diff()]); if (pc === 0x8554) stats.iters++; }
      }
    }
    if (pokes && !w) {                  // scenario pokes land in adapter code: inside an 'O' diff
      for (const [a, v] of Object.entries(pokes)) memory.write(parseInt(a, 16), v, false);
      pokes = null;
    }
    prevPc = pc;
    return oi();
  };
}

// ---- scenario driver --------------------------------------------------------
// Keys: Vector matrix [row, mask]
const KEY = { left: [0, 0x10], up: [0, 0x20], right: [0, 0x40], down: [0, 0x80], vk: [0, 0x04], zb: [0, 0x08],
  ar2: [1, 0x04], space: [7, 0x80] };
for (let d = 0; d < 8; d++) KEY[String(d)] = [2, 1 << d];
KEY['8'] = [3, 0x01]; KEY['9'] = [3, 0x02];
for (let c = 0; c < 26; c++) { const n = c + 1; KEY[String.fromCharCode(65 + c)] = [4 + (n >> 3), 1 << (n & 7)]; }
const JOY = { up: 0x04, down: 0x08, left: 0x02, right: 0x01, fire: 0x40 };

let seed = SCEN.seed >>> 0 || 1;
const rnd = () => { seed ^= seed << 13; seed >>>= 0; seed ^= seed >>> 17; seed ^= seed << 5; seed >>>= 0; return seed / 4294967296; };
const press = (names) => {
  for (let i = 0; i < 8; i++) keyboard.matrix[i] = 0;
  keyboard.us = names.includes('us'); keyboard.ss = names.includes('ss');
  for (const n of names) { if (n === 'us' || n === 'ss') continue; const k = KEY[n]; if (!k) throw new Error(`key ${n}`); keyboard.matrix[k[0]] |= k[1]; }
};
const joyBits = (names) => names.reduce((m, n) => m | JOY[n], 0);

// Phase tests (as tools/port_lockstep.js / test_game_flow.js)
let menuPoll = -100, curFrame = 0;   // the menu key poll (A697 CALL MENU_KEY) ran in the last frames
const inMenu = () => curFrame - menuPoll < 3 && rd(0x0fed) !== 1;
const inMatch = () => rd(0x0fed) === 1;

// bots: per frame -> {keys, joyA, joyB}
const BOTS = {
  idle: () => ({ keys: [] }),
  random(st, p) {        // random direction/fire combos held 5..30 frames
    if (!st.hold || --st.hold <= 0) {
      st.hold = 5 + Math.floor(rnd() * 26);
      const dirs = [[], ['up'], ['down'], ['left'], ['right'], ['up', 'left'], ['up', 'right'], ['down', 'left'], ['down', 'right']];
      st.cur = dirs[Math.floor(rnd() * dirs.length)].concat(rnd() < (p.fire ?? 0.3) ? ['fire'] : []);
    }
    return st.cur;
  },
  chase(st, p, who) {    // run at the other player with fire held near him: contacts, steals, fouls
    const me = who === 2 ? 0x9425 : 0x940b, him = who === 2 ? 0x940b : 0x9425;
    const dx = rd(him + 2) - rd(me + 2), dy = rd(him + 3) - rd(me + 3), out = [];
    if (dx > 2) out.push('right'); else if (dx < -2) out.push('left');
    if (dy > 1) out.push('down'); else if (dy < -1) out.push('up');
    if (Math.abs(dx) < 12 && Math.abs(dy) < 6 && rnd() < (p.fire ?? 0.7)) out.push('fire');
    return out;
  },
  wander(st, p, who) {   // walk to a random spot of the court and fire there
    const me = who === 2 ? 0x9425 : 0x940b;
    if (!st.tx || st.wait > 200) { st.tx = 0x20 + Math.floor(rnd() * 0x50); st.ty = 0x08 + Math.floor(rnd() * 0x60); st.wait = 0; }
    st.wait++;
    const dx = st.tx - rd(me + 2), dy = st.ty - rd(me + 3), out = [];
    if (dx > 2) out.push('right'); else if (dx < -2) out.push('left');
    if (dy > 2) out.push('down'); else if (dy < -2) out.push('up');
    if (!out.length) { st.tx = 0; return ['fire']; }
    return out;
  },
  dunker(st, p, who) {   // shooter for either player and either basket (sides change at half time): switch basket every 700 frames
    const me = who === 2 ? 0x9425 : 0x940b;
    st.t = (st.t || 0) + 1;
    const top = Math.floor(st.t / 700) % 2 === 0;
    const x = rd(me + 2), y = rd(me + 3);
    if (x > 0x5a) return ['left'];
    if (x < 0x50) return ['right'];
    if (top ? y >= 0x0d : y <= 0x66) return [top ? 'up' : 'down'];
    return ['fire'];
  },
  mix(st, p, who) {      // switch between random / chase / shooter / idle every 100..600 frames
    if (!st.left || --st.left <= 0) {
      st.left = 100 + Math.floor(rnd() * 500);
      st.kind = (p.kinds || ['random', 'chase', 'shooter', 'idle', 'random'])[Math.floor(rnd() * (p.kinds || [0, 0, 0, 0, 0]).length)];
      st.fire = rnd(); st.sub = {};
    }
    if (st.kind === 'idle') return [];
    if (st.kind === 'shooter' && who === 2) return BOTS.chase(st.sub, { fire: st.fire }, who);
    return BOTS[st.kind](st.sub, { fire: st.fire }, who);
  },
  mix2(st, p, who) { return BOTS.mix(st, { kinds: ['random', 'chase', 'shooter', 'idle', 'wander', 'wander'] }, who); },
  shooter(st, p) {       // steer player 1 into the dunk window (8F0F), then fire
    const x = rd(0x940d), y = rd(0x940e);
    if (x > 0x5a) return ['left'];
    if (x < 0x50) return ['right'];
    if (y >= 0x0d) return ['up'];
    return ['fire'];
  },
};
const toKeys = (dirs) => dirs.map((d) => (d === 'fire' ? 'space' : d));

const steps = SCEN.steps;
let si = 0, sf = 0, botSt = {}, seenMenu = false;
const NF = SCEN.frames || 60000;
const t0 = Date.now();
for (let frame = 0; frame < NF && si < steps.length; frame++) {
  stats.frames = frame; curFrame = frame;
  const s = steps[si];
  let done = false;
  joyA = joyB = 0;
  if (s.wait) {                          // title -> 'menu' / 'match' / 'notmatch'
    press(!seenMenu && frame % 300 >= 8 && frame % 300 < 40 && s.wait === 'menu' ? ['space'] : []);   // splash/title only
    done = s.wait === 'menu' ? inMenu() : s.wait === 'match' ? inMatch() : !inMatch();
    if (sf > (s.max || 6000)) throw new Error(`step ${si} wait ${s.wait}: timeout (menu poll at frame ${menuPoll}, pc ${hx(cpu.pc)})`);
  } else if (s.key) {                    // press keys for 'hold' frames, then release for 'gap'
    const hold = s.hold || 6, gap = s.gap ?? 20;
    press(sf < hold ? [].concat(s.key) : []);
    done = sf >= hold + gap;
  } else if (s.type) {                   // type a string (name entry), each char a key
    const i = Math.floor(sf / 16), t = Array.isArray(s.type) ? s.type : [...s.type];
    press(i < t.length && sf % 16 < 6 ? [t[i] === ' ' ? 'space' : t[i]] : []);
    done = i >= s.type.length;
  } else if (s.bot) {                    // play: bot for player 1 (keys) and optionally joystick A
    const dirs = BOTS[s.bot](botSt, s, 1);
    press(toKeys(dirs));
    if (s.bot2) joyA = joyBits(BOTS[s.bot2](botSt.p2 || (botSt.p2 = {}), s, 2));
    done = (s.frames && sf >= s.frames) || (s.until === 'notmatch' && !inMatch()) || (s.until === 'menu' && inMenu());
  } else if (s.poke) {                  // {"poke": {"ADDR": value}}: set state (rare paths), once, from adapter code
    if (sf === 0) pokes = s.poke;
    press([]); done = !pokes;
  } else if (s.idle) {
    press([]); done = sf >= s.idle;
  }
  v06c.oneInterrupt(false);   // one TV frame (oneFrame skips frames by wall-clock time: not deterministic)
  sf++;
  if (inMenu()) seenMenu = true;
  if (process.env.PROGRESS && frame % 1000 === 0) process.stderr.write(`f${frame} step${si} mode ${rd(0x0fed)} clock ${String.fromCharCode(rd(0x93e7), rd(0x93e8), rd(0x93e9))} half ${rd(0x93e5)} ev ${ev.length}\n`);
  if (done) { si++; sf = 0; botSt = {}; if (process.env.PROGRESS) process.stderr.write(`f${frame} -> step ${si} mode ${rd(0x0fed)}\n`); }
}
if (process.env.DUMP) { const [a, n] = process.env.DUMP.split(',').map((h) => parseInt(h, 16)); const b = []; for (let i = 0; i < n; i++) b.push(rd(a + i).toString(16).padStart(2, '0')); process.stderr.write(`dump ${hx(a)}: ${b.join(' ')}\n`); }
stats.events = ev.length;
stats.step = si;
stats.secs = (Date.now() - t0) / 1000;
const coverList = []; for (let a = 0; a < 0x10000; a++) if (cover[a]) coverList.push(a);
const { secs, ...fileStats } = stats;   // wall time stays out of the file (determinism)
if (PROBE >= 0) process.stderr.write(`probe ${JSON.stringify(probe)}\n`);
if (COVER_ONLY) { fs.writeFileSync(OUT, JSON.stringify({ scenario: SCEN, cover: coverList, stats: fileStats })); process.stdout.write('{}\n'); process.exit(0); }
const out = { scenario: SCEN, mem0: Buffer.from(mem0).toString('base64'), ev, cover: coverList, stats: fileStats };
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, zlib.gzipSync(JSON.stringify(out), { level: 9 }));
const kinds = {}; let dbytes = 0;
for (const e of ev) { kinds[e[0]] = (kinds[e[0]] || 0) + 1; dbytes += e[3].length / 2; }
process.stdout.write(JSON.stringify({ name: SCEN.name, ...stats, kinds, diffBytes: dbytes, cover: coverList.length, size: fs.statSync(OUT).size }) + '\n');
