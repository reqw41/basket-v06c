#!/usr/bin/env node
/**
 * Headless Z80 smoke for basket.rom — run N frames, report PC / VRAM / plane.
 *
 *   node tools/smoke_v06js.js [rom] [frames] [--input] [--vi53]
 *
 * Options:
 *   --input   Inject keyboard input (arrows+space) after frame 100
 *   --vi53    Log VI53 port writes (0x08-0x0B)
 *   --diff    Run twice (no-input vs input) and report state differences
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const args = process.argv.slice(2).filter(a => !a.startsWith('--'));
const flags = new Set(process.argv.slice(2).filter(a => a.startsWith('--')));
const ROM = args[0] || path.join(ROOT, 'build/v06/basket.rom');
const FRAMES = Number(args[1] || 100);
const WITH_INPUT = flags.has('--input') || flags.has('--diff');
const LOG_VI53 = flags.has('--vi53');
const DIFF_MODE = flags.has('--diff');
const INPUT_START_FRAME = 100;

global.window = global;
global.document = {
  createElement: () => fc(),
  getElementById: () => fc(),
};
function fcx() {
  return {
    createImageData: (w, h) => ({
      data: new Uint8ClampedArray((w || 1) * (h || 1) * 4),
      width: w,
      height: h,
    }),
    putImageData: () => {},
    drawImage: () => {},
    getImageData: () => ({ data: new Uint8ClampedArray(4) }),
    fillRect: () => {},
    save: () => {},
    restore: () => {},
    scale: () => {},
    setTransform: () => {},
  };
}
function fc() {
  return { width: 0, height: 0, style: {}, getContext: () => fcx() };
}
global.requestAnimationFrame = () => 0;
global.setTimeout = () => 0;
global.print = () => {};
global.console.debug = () => {};

const g = {};
for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g;
const ctx = vm.createContext(g);

for (const f of [
  'i8080-js/i8080_trace.js',
  'i8080-js/i8080_disasm.js',
  'i8080-js/i8080.js',
  'src/fili.js',
  'src/ay.js',
  'src/fd1793.js',
  'src/fddimage.js',
  'src/i8253.js',
  'src/io.js',
  'src/keyboard.js',
  'src/memory.js',
  'src/sound.js',
  'src/tv.js',
  'Z80_v06.js',
  'z80_adapter.js',
]) {
  vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
}

const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

// VI53 write logger
const vi53Log = [];
const originalTimerWrite = I8253.prototype.Write;
I8253.prototype.Write = function(port, value) {
  if (LOG_VI53) {
    vi53Log.push({ frame: currentFrame, port: 0x08 + ((~port) & 3), value });
  }
  return originalTimerWrite.call(this, port, value);
};

let currentFrame = 0;

function createEmulator() {
  const memory = new Memory();
  const keyboard = new Keyboard();
  const timer = new I8253();
  const ay = new AY();
  const floppy = new (Floppy().FD1793)();
  const io = new IO(keyboard, timer, memory, ay, floppy);
  io.Palette = new Array(16).fill(0xff000000);
  const tape = { advance: () => {}, sample: 0, reset: () => {}, stop: () => {}, sampleAt: () => 0 };
  io.tape_player = tape;
  const cpu = new I8080(memory, io); // z80_adapter replaced I8080 with Z80
  const v06c = new Vector06c(cpu, memory, io, ay, tape);
  v06c.tape_player = tape;
  v06c.bmp = new Uint32Array(576 * 288);
  v06c.displayFrame = () => {};
  v06c.dbg = null;
  v06c.check_breakpoint = () => false;
  return { memory, keyboard, timer, io, cpu, v06c };
}

const emu = createEmulator();
const { memory, keyboard, timer, io, cpu, v06c } = emu;

// --wav: capture the emulated sound path to build/v06/sound.wav (22050 Hz mono)
if (flags.has('--wav') && v06c.soundnik) {
  const RATE = 22050, pcm = [];
  v06c.soundnik.soundRatio = RATE / 1497600;
  v06c.soundnik.sample = (s) => pcm.push(s);
  process.on('exit', () => {
    const buf = Buffer.alloc(44 + pcm.length * 2);
    buf.write('RIFF', 0); buf.writeUInt32LE(36 + pcm.length * 2, 4); buf.write('WAVEfmt ', 8);
    buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(1, 22);
    buf.writeUInt32LE(RATE, 24); buf.writeUInt32LE(RATE * 2, 28); buf.writeUInt16LE(2, 32);
    buf.writeUInt16LE(16, 34); buf.write('data', 36); buf.writeUInt32LE(pcm.length * 2, 40);
    pcm.forEach((s, i) => buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(s * 32767))), 44 + i * 2));
    fs.writeFileSync(path.join(ROOT, 'build/v06/sound.wav'), buf);
  });
}

function loadRom(mem) {
  const file = new Uint8Array(fs.readFileSync(ROM));
  // Vector-native: file[0] → mem[0100]. Legacy 64K images load at 0000.
  const base = file.length === 65536 ? 0 : 0x100;
  for (let i = 0; i < file.length && base + i < 0x10000; i++)
    mem.write(base + i, file[i], false);
  if (mem.detach_boot) mem.detach_boot();
}

function initCpu(c, t) {
  c.pc = 0x0100;
  c.sp = 0x7f00;
  c.iff = false;
  t.Write(3, 0x36);
  t.Write(3, 0x76);
  t.Write(3, 0xb6);
}

loadRom(memory);
initCpu(cpu, timer);

// --irqlog: per frame, did the IRQ window see IFF=1 (taken) or IFF=0 (lost)?
if (flags.has('--irqlog')) {
  const irqStat = { taken: 0, lostFrames: 0, lostPcs: new Map() };
  let sawWindow = false, took = false;
  const origCheck = v06c.checkInterrupt.bind(v06c);
  v06c.checkInterrupt = function () {
    if (this.irq) took = true;
    return origCheck();
  };
  const origFrame = v06c.oneFrame.bind(v06c);
  v06c.oneFrame = function () {
    took = false;
    const r = origFrame();
    if (took) irqStat.taken++;
    else {
      irqStat.lostFrames++;
      const pc = cpu.pc & 0xffff;
      irqStat.lostPcs.set(pc, (irqStat.lostPcs.get(pc) || 0) + 1);
    }
    return r;
  };
  // Where does IFF drop 1→0 / rise 0→1 (PC of the instruction that did it)
  const drops = new Map(), rises = new Map();
  let prevIff = cpu.iff, prevPc = 0;
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    prevPc = cpu.pc & 0xffff;
    const r = oi();
    const now = cpu.iff;
    if (prevIff && !now) drops.set(prevPc, (drops.get(prevPc) || 0) + 1);
    if (!prevIff && now) rises.set(prevPc, (rises.get(prevPc) || 0) + 1);
    prevIff = now;
    return r;
  };
  process.on('exit', () => {
    console.log(`IRQ taken=${irqStat.taken} lost=${irqStat.lostFrames} iff_now=${cpu.iff}`);
    const fmt = m => [...m].sort((a, b) => b[1] - a[1]).slice(0, 10).map(([p, n]) => `${p.toString(16)}:${n}`).join(' ');
    console.log('IFF drops at', fmt(drops));
    console.log('IFF rises at', fmt(rises));
  });
}


// --watch=HHHH: log writes to one address (with writer PC)
const watchArg = process.argv.find(a => a.startsWith('--watch='));
if (watchArg) {
  const wa = parseInt(watchArg.slice(8), 16);
  const WMAX = +(process.env.WATCH_MAX || 10), WQUIET = !!process.env.WATCH_QUIET;
  const origWrite = memory.write.bind(memory);
  let hits = 0;
  const wring = [];
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () { wring.push(cpu.pc & 0xffff); if (wring.length > 24) wring.shift(); return oi(); };
  memory.write = function (addr, val, stack) {
    if ((addr & 0xffff) === wa && hits < WMAX && !WQUIET) { console.log('  pcs:', wring.map(p => p.toString(16)).join(' ')); const m=[]; for (let a=(cpu.pc&0xffff)-4;a<(cpu.pc&0xffff)+6;a++) m.push(memory.read(a,false).toString(16).padStart(2,'0')); console.log('  code@pc-4:', m.join(' ')); }
    if ((addr & 0xffff) === wa && hits++ < WMAX)
      console.log(`WATCH ${wa.toString(16)} <= ${(val & 0xff).toString(16)} pc=${(cpu.pc & 0xffff).toString(16)} sp=${(cpu.sp & 0xffff).toString(16)} frame=${currentFrame}`);
    return origWrite(addr, val, stack);
  };
}

// --accmap: per-byte access map to build/v06/accmap.bin (bit0 read, bit1 write)
if (flags.has('--accmap')) {
  const acc = new Uint8Array(0x10000);
  const origRead = memory.read.bind(memory), origWr = memory.write.bind(memory);
  memory.read = function (addr, stack) { acc[addr & 0xffff] |= 1; return origRead(addr, stack); };
  memory.write = function (addr, val, stack) { acc[addr & 0xffff] |= 2; return origWr(addr, val, stack); };
  process.on('exit', () => fs.writeFileSync(path.join(ROOT, 'build/v06/accmap.bin'), acc));
}

// --xref: code/data cross-reference → build/v06/xref.json
//   fetch: byte addresses read as opcode/operand of the current instruction
//   rd/wr: data address → up to 6 instruction PCs that read/wrote it (stack excluded)
if (flags.has('--xref')) {
  let cur = 0, xrefCpuActive = false;
  const fetch = new Uint8Array(0x10000), exec = new Uint8Array(0x10000);
  const rd = new Map(), wr = new Map();
  const note = (m, a) => { let s = m.get(a); if (!s) m.set(a, s = new Set()); if (s.size < 6) s.add(cur); };
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    cur = cpu.pc & 0xffff; exec[cur] = 1; xrefCpuActive = true;
    try { return oi(); } finally { xrefCpuActive = false; }
  };
  const r0 = memory.read.bind(memory), w0 = memory.write.bind(memory);
  memory.read = function (addr, stack) {
    const a = addr & 0xffff;
    if (xrefCpuActive && !stack) { if (((a - cur) & 0xffff) < 4) fetch[a] = 1; else note(rd, a); }
    return r0(addr, stack);
  };
  memory.write = function (addr, val, stack) { if (xrefCpuActive && !stack) note(wr, addr & 0xffff); return w0(addr, val, stack); };
  process.on('exit', () => {
    const dump = (m) => { const o = {}; for (const [a, s] of m) o[a] = [...s]; return o; };
    fs.writeFileSync(path.join(ROOT, 'build/v06/xref.json'), JSON.stringify({
      exec: [...exec.keys()].filter(i => exec[i]), fetch: [...fetch.keys()].filter(i => fetch[i]),
      rd: dump(rd), wr: dump(wr) }));
  });
}

// --lastuse: frame of the last access to each byte → build/v06/lastuse.bin (u16, +1; 0 = never)
if (flags.has('--lastuse')) {
  const last = new Uint16Array(0x10000);
  const r0 = memory.read.bind(memory), w0 = memory.write.bind(memory);
  memory.read = function (addr, stack) { last[addr & 0xffff] = currentFrame + 1; return r0(addr, stack); };
  memory.write = function (addr, val, stack) { last[addr & 0xffff] = currentFrame + 1; return w0(addr, val, stack); };
  process.on('exit', () => fs.writeFileSync(path.join(ROOT, 'build/v06/lastuse.bin'), Buffer.from(last.buffer)));
}

// --vramlog: OUT 98 (RST 08) writes to the colour table VRAM 2000..37FF
// → build/v06/vramlog.txt "frame addr value pc"
if (flags.has('--vramlog')) {
  const log = [];
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    if ((cpu.pc & 0xffff) === 0x0008 && log.length < 200000) {
      const va = memory.read(0x0F09, false) | ((memory.read(0x0F0A, false) & 0x3f) << 8);
      if (va >= 0x2000 && va < 0x3800) {
        const st = cpu.getState ? cpu.getState() : null;
        const a = st ? st.a : cpu.a;
        const sp = cpu.sp & 0xffff;
        const ret = memory.read(sp, false) | (memory.read(sp + 1, false) << 8);
        log.push(`${currentFrame} ${va.toString(16)} ${a.toString(16)} ${(ret - 1).toString(16)}`);
      }
    }
    return oi();
  };
  process.on('exit', () => fs.writeFileSync(path.join(ROOT, 'build/v06/vramlog.txt'), log.join('\n') + '\n'));
}

// --psglog: record WRTPSG (0093) calls: frame, reg (A), value (E)
if (flags.has('--psglog')) {
  const log = [];
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    if ((cpu.pc & 0xffff) === 0x0093 && log.length < 20000) {
      const st = cpu.getState ? cpu.getState() : null;
      const a = st ? st.a : cpu.a, e = st ? st.e : cpu.e;
      log.push(`${currentFrame} ${a} ${e}`);
    }
    return oi();
  };
  process.on('exit', () => fs.writeFileSync(path.join(ROOT, 'build/v06/psglog.txt'), log.join('\n') + '\n'));
}

// --peek=HHHH:N,...: hex dump at exit
const peekArg = process.argv.find(a => a.startsWith('--peek='));
if (peekArg) process.on('exit', () => {
  for (const spec of peekArg.slice(7).split(',')) {
    const [a, n] = spec.split(':');
    const lo = parseInt(a, 16), cnt = n ? +n : 16;
    const b = [];
    for (let i = 0; i < cnt; i++) b.push(memory.read((lo + i) & 0xffff, false).toString(16).padStart(2, '0'));
    console.log(`PEEK ${a}: ${b.join(' ')}`);
  }
});

// --pcs=HHHH,HHHH: count executions of the given addresses (first frame too)
const pcsArg = process.argv.find(a => a.startsWith('--pcs='));
const pcHits = new Map();
if (pcsArg) {
  for (const h of pcsArg.slice(6).split(',')) pcHits.set(parseInt(h, 16), { n: 0, first: -1 });
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    const e = pcHits.get(cpu.pc & 0xffff);
    if (e) { if (!e.n) e.first = currentFrame; e.n++; }
    return oi();
  };
  process.on('exit', () => {
    for (const [a, e] of pcHits) console.log(`PC ${a.toString(16)}: ${e.n} hits, first frame ${e.first}`);
  });
}

// --prof=F0:F1: per-instruction PC histogram (cycles) over frames F0..F1
const profArg = process.argv.find(a => a.startsWith('--prof='));
if (profArg) {
  const [f0, f1] = profArg.slice(7).split(':').map(Number);
  const hist = new Map();
  let total = 0;
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    const pc = cpu.pc & 0xffff;
    const c = oi();
    if (currentFrame >= f0 && currentFrame < f1) {
      hist.set(pc, (hist.get(pc) || 0) + (c || 4));
      total += c || 4;
    }
    return c;
  };
  process.on('exit', () => {
    const buckets = new Map();
    for (const [pc, c] of hist) {
      const b = pc < 0x1000 ? 'adapter' : (pc >> 6 << 6).toString(16);
      buckets.set(b, (buckets.get(b) || 0) + c);
    }
    const top = [...buckets].sort((a, b) => b[1] - a[1]).slice(0, 16);
    console.log('PROF', top.map(([b, c]) => `${b}:${(100 * c / total).toFixed(1)}%`).join(' '));
    const ad = [...hist].filter(([p]) => p < 0x1000);
    const ab = new Map();
    for (const [pc, c] of ad) { const b = (pc >> 4 << 4).toString(16); ab.set(b, (ab.get(b) || 0) + c); }
    console.log('PROF adapter', [...ab].sort((a, b) => b[1] - a[1]).slice(0, 12).map(([b, c]) => `${b}:${(100 * c / total).toFixed(1)}%`).join(' '));
  });
}

// --prof2=F0:F1: cycles by game procedure (memmap.json entries), adapter time
// charged to the game procedure that called it; IRQ (adapter + game ISR) apart.
const prof2Arg = process.argv.find(a => a.startsWith('--prof2='));
if (prof2Arg) {
  const [f0, f1] = prof2Arg.slice(8).split(':').map(Number);
  const mm = JSON.parse(fs.readFileSync(path.join(ROOT, 'build/v06/memmap.json'), 'utf8'));
  const entries = mm.procs.map(p => p.addr).sort((a, b) => a - b);
  const labels = [];
  for (const [n, a] of Object.entries(require('./v06syms').SYMS)) labels.push([a, n]);
  labels.sort((a, b) => a[0] - b[0]);
  const near = (arr, pc) => { let lo = 0, hi = arr.length - 1, r = -1; while (lo <= hi) { const mid = (lo + hi) >> 1; if ((arr[mid][0] ?? arr[mid]) <= pc) { r = mid; lo = mid + 1; } else hi = mid - 1; } return r; };
  const procOf = pc => { const i = near(entries, pc); return i < 0 ? 'low' : entries[i].toString(16).toUpperCase(); };
  const labOf = pc => { const i = near(labels, pc); return i < 0 ? '?' : labels[i][1]; };
  const self = new Map(), charged = new Map(), adapt = new Map();
  let total = 0, irq = 0, irqSP = -1, caller = 'none';
  const add = (m, k, c) => m.set(k, (m.get(k) || 0) + c);
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    const pc = cpu.pc & 0xffff;
    const on = currentFrame >= f0 && currentFrame < f1;
    if (pc === 0x0038 && irqSP < 0) irqSP = (cpu.sp & 0xffff) + 2;
    const c = oi() || 4;
    if (!on) { if (irqSP >= 0 && (cpu.sp & 0xffff) >= irqSP) irqSP = -1; return c; }
    total += c;
    if (irqSP >= 0) {
      irq += c;
      if (pc < 0x1000) add(adapt, 'IRQ:' + labOf(pc), c);
      else add(adapt, 'IRQ:game ' + procOf(pc), c);
      if ((cpu.sp & 0xffff) >= irqSP) irqSP = -1;
      return c;
    }
    if (pc >= 0x1000) { caller = procOf(pc); add(self, caller, c); }
    else { add(charged, caller, c); add(adapt, labOf(pc), c); }
    return c;
  };
  process.on('exit', () => {
    const pct = c => (100 * c / total).toFixed(1) + '%';
    const keys = new Set([...self.keys(), ...charged.keys()]);
    const rows = [...keys].map(k => [k, self.get(k) || 0, charged.get(k) || 0]).sort((a, b) => (b[1] + b[2]) - (a[1] + a[2]));
    console.log(`PROF2 frames ${f0}..${f1} total ${total} cycles, IRQ ${pct(irq)}`);
    for (const [k, s, a] of rows.slice(0, 18)) console.log(`  ${k.padEnd(6)} ${pct(s + a).padStart(6)}  (own ${pct(s)}, adapter ${pct(a)})`);
    console.log('  adapter routines:');
    for (const [k, c] of [...adapt].sort((a, b) => b[1] - a[1]).slice(0, 14)) console.log(`    ${k.padEnd(24)} ${pct(c)}`);
  });
}

// --trap: report the first entry of PC into E000+ (visible plane / MSX high RAM)
if (flags.has('--trap')) {
  const ring = [];
  let trapped = false;
  const origInstr = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    const pc = cpu.pc & 0xffff;
    if (!trapped && pc >= 0xe000 && ring.length) {
      trapped = true;
      console.log(`TRAP pc=${pc.toString(16)} sp=${(cpu.sp & 0xffff).toString(16)} frame=${currentFrame}`);
      console.log('  last PCs:', ring.map(p => p.toString(16)).join(' '));
      const sp = cpu.sp & 0xffff;
      const st = [];
      for (let i = 0; i < 8; i++) st.push((memory.read(sp + 2 * i, false) | (memory.read(sp + 2 * i + 1, false) << 8)).toString(16));
      console.log('  stack:', st.join(' '));
      const m=[];for(let a=0x1018;a<0x1030;a++)m.push(memory.read(a,false).toString(16).padStart(2,'0'));console.log('  mem1018:',m.join(''));
    }
    ring.push(pc);
    if (ring.length > 40) ring.shift();
    return origInstr();
  };
}
keyboard.Hook && keyboard.Hook();

function countNz(mem, lo, hi) {
  let n = 0;
  for (let a = lo; a < hi; a++) if (mem.read(a, false)) n++;
  return n;
}

// Keyboard input injection: Vector-06C keyboard matrix
// Row 0: DN(0x80) RT(0x40) UP(0x20) LT(0x10) ...
// Row 7: SPACE(0x80) ...
// --press=F:R:M[:N],... hold Vector row R mask M from frame F for N frames (8)
const pressArg = process.argv.find(a => a.startsWith('--press='));
const presses = pressArg ? pressArg.slice(8).split(',').map(s => {
  const [f, r, m, n] = s.split(':');
  return { f: +f, r: +r, m: parseInt(m, 16), n: n ? +n : 8 };
}) : null;

// --snap=F1,F2,...: dump both colour planes at these frames
const snapArg = process.argv.find(a => a.startsWith('--snap='));
const snapFrames = new Set(snapArg ? snapArg.slice(7).split(',').map(Number) : []);

// --sprlog: print colour sprite calls (frame, record pointer, X/Y).
if (flags.has('--sprlog')) {
  const entry = require('./v06syms').sym('COLOR_SPRITE');
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () {
    if ((cpu.pc & 0xffff) === entry) {
      const ptr = memory.read(0x3302, false) | (memory.read(0x3303, false) << 8);
      console.log(`SPR ${currentFrame} ptr=${ptr.toString(16)} x=${memory.read(0x3301, false)} y=${memory.read(0x3300, false)}`);
    }
    return oi();
  };
}

// --poslog=F0:F1: player coords 940B/9425 (+2=X +3=Y) each frame → build/v06/poslog.csv
const posArg = process.argv.find(a => a.startsWith('--poslog='));
const posRange = posArg ? posArg.slice(9).split(':').map(Number) : null;
const posRows = [];
const dirtyStats = flags.has('--dirtylog') ? {
  menu: { count: 0, minCol: 255, maxCol: 0, minRow: 255, maxRow: 0, maxRects: 0 },
  match: { count: 0, minCol: 255, maxCol: 0, minRow: 255, maxRow: 0, maxRects: 0 },
} : null;

function sampleDirty() {
  if (!dirtyStats) return;
  const peek = a => memory.read(a & 0xffff, false);
  const mode = peek(0x0fee) ? 'match' : 'menu';
  const s = dirtyStats[mode];
  const n = Math.min(peek(0x0f80), 27);
  s.maxRects = Math.max(s.maxRects, n);
  for (let i = 0; i < n; i++) {
    const a = 0x0f81 + i * 4;
    const col = peek(a), row = peek(a + 1), w = peek(a + 2), h = peek(a + 3);
    if (!w || !h) continue;
    s.count++;
    s.minCol = Math.min(s.minCol, col); s.maxCol = Math.max(s.maxCol, col + w - 1);
    s.minRow = Math.min(s.minRow, row); s.maxRow = Math.max(s.maxRow, row + h - 1);
  }
}

function injectInput(kbd, frame) {
  if (presses) {
    for (let i = 0; i < 8; i++) kbd.matrix[i] = 0;
    for (const p of presses) if (frame >= p.f && frame < p.f + p.n) kbd.matrix[p.r] |= p.m;
    return;
  }
  if (!WITH_INPUT || frame < INPUT_START_FRAME) return;
  
  // Cycle through different inputs to test
  const phase = Math.floor((frame - INPUT_START_FRAME) / 30) % 5;
  
  // Reset matrix first
  for (let i = 0; i < 8; i++) kbd.matrix[i] = 0;
  
  switch (phase) {
    case 0: kbd.matrix[0] = 0x20; break; // UP
    case 1: kbd.matrix[0] = 0x40; break; // RIGHT
    case 2: kbd.matrix[0] = 0x80; break; // DOWN
    case 3: kbd.matrix[0] = 0x10; break; // LEFT
    case 4: kbd.matrix[7] = 0x80; break; // SPACE (fire)
  }
}

const pcs = new Map();
const hitTitle = [];
const hitPath = [];
const pathRanges = [
  [0x84d0, 0x8530, 'entry'],
  [0xaa7c, 0xaad0, 'AA7C'],
  [0xa54a, 0xa620, 'A54A'],
  [0xcc76, 0xcce7, 'CC76'],
  [0xd48b, 0xd4ac, 'ISR'],
];
for (currentFrame = 0; currentFrame < FRAMES; currentFrame++) {
  injectInput(keyboard, currentFrame);
  v06c.oneFrame();
  sampleDirty();
  if (snapFrames.has(currentFrame)) {
    const low = Buffer.alloc(0x2000);
    const high = Buffer.alloc(0x2000);
    for (let i = 0; i < 0x2000; i++) {
      low[i] = memory.read(0xe000 + i, false);
      high[i] = memory.read(0xc000 + i, false);
    }
    fs.writeFileSync(path.join(ROOT, `build/v06/snap_${currentFrame}.bin`), low);
    fs.writeFileSync(path.join(ROOT, `build/v06/snap_${currentFrame}_hi.bin`), high);
  }
  if (posRange && currentFrame >= posRange[0] && currentFrame < posRange[1]) {
    const rd = a => memory.read(a, false);
    posRows.push([
      currentFrame,
      rd(0x940b), rd(0x940c), rd(0x940d), rd(0x940e),
      rd(0x9425), rd(0x9426), rd(0x9427), rd(0x9428),
      rd(0x93e6), rd(0x93e7), rd(0x93e8), rd(0x93e9),
      rd(0xac4d), rd(0xac4e),
    ].join(','));
  }
  const pc = cpu.pc & 0xffff;
  pcs.set(pc, (pcs.get(pc) || 0) + 1);
  if (pc >= 0xa54a && pc <= 0xa620 && hitTitle.length < 8)
    hitTitle.push(`f${currentFrame}:${pc.toString(16)}`);
  for (const [lo, hi, name] of pathRanges) {
    if (pc >= lo && pc < hi && hitPath.length < 40)
      hitPath.push(`f${currentFrame}:${name}@${pc.toString(16)}`);
  }
  if (currentFrame % 25 === 0 || currentFrame === FRAMES - 1) {
    const inputStr = WITH_INPUT && currentFrame >= INPUT_START_FRAME 
      ? ` kbd=[${keyboard.matrix[0].toString(16)},${keyboard.matrix[7].toString(16)}]`
      : '';
    console.log(
      `frame ${currentFrame}: pc=${pc.toString(16).padStart(4, '0')} sp=${(cpu.sp & 0xffff)
        .toString(16)
        .padStart(4, '0')} vram=${countNz(memory, 0x2000, 0x3b80)} plane=${countNz(memory, 0xe000, 0x10000)}${inputStr}`
    );
  }
}
if (dirtyStats) console.log('DIRTY_STATS', JSON.stringify(dirtyStats));
if (posRows.length) {
  const hdr = 'frame,p1_0,p1_1,p1_x,p1_y,p2_0,p2_1,p2_x,p2_y,clk_div,clk_m,clk_s1,clk_s0,ac4d,ac4e';
  fs.writeFileSync(path.join(ROOT, 'build/v06/poslog.csv'), hdr + '\n' + posRows.join('\n') + '\n');
  console.log(`wrote build/v06/poslog.csv (${posRows.length} rows)`);
}
console.log('title A54A hits:', hitTitle.join(' ') || 'none');
console.log('path hits:', hitPath.join(' ') || 'none');

const top = [...pcs.entries()].sort((a, b) => b[1] - a[1]).slice(0, 12);
console.log(
  'top PCs:',
  top.map(([p, n]) => `${p.toString(16)}:${n}`).join(' ')
);
console.log('final vram', countNz(memory, 0x2000, 0x3b80),
  'planeHi', countNz(memory, 0xc000, 0xe000),
  'planeLo', countNz(memory, 0xe000, 0x10000));

// Report VI53 activity
if (LOG_VI53 && vi53Log.length > 0) {
  console.log(`\n=== VI53 writes: ${vi53Log.length} total ===`);
  // Group by frame ranges
  const byPort = { 0x08: 0, 0x09: 0, 0x0a: 0, 0x0b: 0 };
  const firstFew = vi53Log.slice(0, 20);
  vi53Log.forEach(e => byPort[e.port] = (byPort[e.port] || 0) + 1);
  console.log('Port counts:', Object.entries(byPort).map(([p,c]) => `${(+p).toString(16)}:${c}`).join(' '));
  console.log('First writes:', firstFew.map(e => `f${e.frame}:${e.port.toString(16)}=${e.value.toString(16)}`).join(' '));
}

// Dump a few soft-VDP state bytes if present
const regs = [];
for (let i = 0; i < 8; i++) regs.push(memory.read(0x0f00 + i, false).toString(16).padStart(2, '0'));
console.log('VDP_REGS@0F00', regs.join(' '));
console.log('VDP_STATUS', memory.read(0x0f08, false).toString(16));
console.log('VDP_ADDR', memory.read(0x0f0a, false).toString(16).padStart(2,'0') + memory.read(0x0f09, false).toString(16).padStart(2,'0'));
console.log('VDP_LATCH', memory.read(0x0f0b, false));

// MSX shadow keyboard rows (V_MSXROW = KEY_SNAP at 0x4104)
const msxRows = [];
for (let i = 0; i < 9; i++) msxRows.push(memory.read(0x4104 + i, false).toString(16).padStart(2, '0'));
console.log('MSX_SHADOW', msxRows.join(' '));

// PSG shadow (V_AYREG at 0x0F40)
const ayRegs = [];
for (let i = 0; i < 14; i++) ayRegs.push(memory.read(0x0f40 + i, false).toString(16).padStart(2, '0'));
console.log('AY_SHADOW', ayRegs.join(' '));

// Debug counters at 0F70+
const wrCnt = memory.read(0x0f70, false) | (memory.read(0x0f71, false) << 8);
const lastAddr = memory.read(0x0f72, false) | (memory.read(0x0f73, false) << 8);
const regCnt = memory.read(0x0f74, false);
const addrCnt = memory.read(0x0f75, false);
const lastReg = memory.read(0x0f76, false);
const lastVal = memory.read(0x0f77, false);
const firstAddr = memory.read(0x0f78, false) | (memory.read(0x0f79, false) << 8);
const firstData = memory.read(0x0f7a, false);
console.log(`DBG: wr_cnt=${wrCnt} last_addr=${lastAddr.toString(16).padStart(4,'0')} reg_cnt=${regCnt} addr_setups=${addrCnt}`);
console.log(`DBG: first_addr=${firstAddr.toString(16).padStart(4,'0')} first_data=${firstData.toString(16).padStart(2,'0')}`);
console.log(`DBG: last_reg=R${lastReg} last_val=${lastVal.toString(16).padStart(2,'0')}`);

// Write plane dump for visualization
const plane = Buffer.alloc(0x2000);
const planeHi = Buffer.alloc(0x2000);
for (let i = 0; i < 0x2000; i++) plane[i] = memory.read(0xe000 + i, false);
for (let i = 0; i < 0x2000; i++) planeHi[i] = memory.read(0xc000 + i, false);
fs.writeFileSync(path.join(ROOT, 'build/v06/plane.bin'), plane);
fs.writeFileSync(path.join(ROOT, 'build/v06/plane-hi.bin'), planeHi);
console.log('wrote build/v06/plane.bin + plane-hi.bin');

// Soft VRAM samples
function hexdump(lo, n) {
  let s = '';
  for (let i = 0; i < n; i++) s += memory.read(lo + i, false).toString(16).padStart(2, '0');
  return s;
}
const SOFT = 0x2000;
console.log('name', hexdump(SOFT + 0x1800, 32));
const soft = Buffer.alloc(0x2000);
for (let i = 0; i < 0x1b80; i++) soft[i] = memory.read(SOFT + i, false);
fs.writeFileSync(path.join(ROOT, 'build/v06/softvram.bin'), soft);
console.log('wrote softvram.bin; 410F=', hexdump(0x410f, 2), '4104=', hexdump(0x4104, 11), '4111=', hexdump(0x4111, 6), '4141=', hexdump(0x4141, 3));
