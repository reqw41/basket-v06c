#!/usr/bin/env node
/**
 * Fair SP vs direct copy of one 32-byte run.
 * Same source bytes, same destination, cycle count includes DI/EI and SP save.
 * Not installed into the ROM.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const g = {};
for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g;
function fcx() {
  return {
    createImageData: (w, h) => ({ data: new Uint8ClampedArray(16), width: 1, height: 1 }),
    putImageData: () => {}, drawImage: () => {}, getImageData: () => ({ data: new Uint8ClampedArray(4) }),
    fillRect: () => {}, save: () => {}, restore: () => {}, scale: () => {}, setTransform: () => {},
  };
}
g.document = { createElement: () => ({ width: 0, height: 0, style: {}, getContext: () => fcx() }), getElementById: () => null };
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
]) vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;
const memory = new Memory();
const keyboard = new Keyboard();
const timer = new I8253();
const ay = new AY();
const floppy = new (Floppy().FD1793)();
const io = new IO(keyboard, timer, memory, ay, floppy);
const cpu = new I8080(memory, io);
const wr = (a, v) => memory.write(a, v & 255, false);
const rd = a => memory.read(a, false);

// direct: ld a,(hl) / ld (de),a / inc hl / inc de / dec b / jr nz   for 32 bytes
// SP: di; ld (nn),sp; ld sp,src; pop x8 into a stack image; ld sp,dst+16;
//     push x8; ld sp,(nn); ei. 16 bytes per bank, two banks = 32.
function run(code, max) {
  const RET = 0x0ff8;
  wr(RET, 0xc9);
  wr(0xbfee, RET & 255); wr(0xbfef, RET >> 8);
  const st = cpu.getState();
  st.pc = 0x8000; st.sp = 0xbfee; st.iff1 = 1; st.halted = false;
  cpu.setState(st); cpu.pc = 0x8000; cpu.sp = 0xbfee;
  let cyc = 0, n = 0;
  while ((cpu.pc & 0xffff) !== RET) {
    if (++n > max) return { ok: false, cyc };
    cyc += cpu.instruction() || 0;
  }
  return { ok: true, cyc, sp: cpu.sp & 0xffff };
}
const src = [];
for (let i = 0; i < 32; i++) src.push(0xA0 + i);
function loadSrc() { for (let i = 0; i < 32; i++) wr(0x9000 + i, src[i]); for (let i = 0; i < 32; i++) wr(0x9100 + i, 0); }

// Direct loop at 8000
loadSrc();
const direct = [
  0x21, 0x00, 0x90,       // ld hl,9000
  0x11, 0x00, 0x91,       // ld de,9100
  0x06, 32,               // ld b,32
  0x7E,                   // ld a,(hl)
  0x12,                   // ld (de),a
  0x23,                   // inc hl
  0x13,                   // inc de
  0x05,                   // dec b
  0x20, 0xF9,             // jr nz,-7
  0xC9,
];
direct.forEach((b, i) => wr(0x8000 + i, b));
console.log('stored', rd(0x8000).toString(16), rd(0x8008).toString(16), rd(0x9000).toString(16));
const d = run(direct, 5000);
const got = [];
for (let i = 0; i < 32; i++) got.push(rd(0x9100 + i));
const same = got.every((b, i) => b === src[i]);
console.log('direct sample', got.slice(0, 4).map(b => b.toString(16)).join(' '), 'match', same, 'cycles', d.cyc);

loadSrc();
// 16-byte SP move, done twice. push writes downward so dest SP starts at end.
const spCode = [
  0xF3,                   // di
  0xED, 0x73, 0x00, 0x80, // ld (8000),sp  -- NO this overwrites code. use 0x8FFE
];
// rewrite carefully
const sp = [
  0xF3,                         // di
  0xED, 0x73, 0xFE, 0x8F,       // ld (8FFE),sp
  0x31, 0x00, 0x90,             // ld sp,9000
  0xC1, 0xD1, 0xE1, 0xD9, 0xC1, 0xD1, 0xE1, 0xD9, // 8 pops = 16 bytes? 
];
// That's only 4 register pairs * 2 via exx = 8 words = 16 bytes. Do it twice.
console.log('direct', d);

// Proper SP block: two 16-byte chunks.
function emitSp() {
  const o = [];
  const emit = (...b) => o.push(...b);
  emit(0xF3);
  emit(0xED, 0x73, 0xF0, 0x8F); // ld (8FF0),sp
  for (let chunk = 0; chunk < 2; chunk++) {
    const s = 0x9000 + chunk * 16;
    const dEnd = 0x9100 + chunk * 16 + 16;
    emit(0x31, s & 255, s >> 8);           // ld sp,src
    emit(0xC1, 0xD1, 0xE1, 0xD9, 0xC1, 0xD1, 0xE1); // pop bc,de,hl,exx,pop bc,de,hl  = 7 words = 14 bytes
    // 16 bytes = 8 words. one more pop of af? AF pop clobbers flags. Use ix via dd e1 = pop ix (14 cycles) 
    emit(0xDD, 0xE1);                      // pop ix  (8th word)
    emit(0x31, dEnd & 255, dEnd >> 8);     // ld sp,dest+16
    emit(0xDD, 0xE5);                      // push ix
    emit(0xE5, 0xD1 & 0xff); // wrong
  }
  return o;
}
// Hand-written and checked: pop order must match push order (LIFO).
// pop bc,de,hl,ix then push ix,hl,de,bc restores the same order at dest.
function chunk(srcA, dstEnd) {
  // 8 words = 16 bytes. Push order is the reverse of the pops.
  return [
    0x31, srcA & 255, srcA >> 8,       // ld sp,src
    0xC1, 0xD1, 0xE1, 0xDD, 0xE1,       // pop bc,de,hl,ix
    0xD9,                               // exx
    0xC1, 0xD1, 0xE1, 0xFD, 0xE1,       // pop bc,de,hl,iy
    0x31, dstEnd & 255, dstEnd >> 8,    // ld sp,dest+16
    0xFD, 0xE5, 0xE5, 0xD5, 0xC5,       // push iy,hl,de,bc
    0xD9,                               // exx
    0xDD, 0xE5, 0xE5, 0xD5, 0xC5,       // push ix,hl,de,bc
  ];
}
const prog = [
  0xF3,
  0xED, 0x73, 0xF0, 0x8F,
  ...chunk(0x9000, 0x9110),
  ...chunk(0x9010, 0x9120),
  0xED, 0x7B, 0xF0, 0x8F, // ld sp,(8FF0)
  0xFB,
  0xC9,
];
loadSrc();
prog.forEach((b, i) => wr(0x8000 + i, b));
const s = run(prog, 500);
const got2 = [];
for (let i = 0; i < 32; i++) got2.push(rd(0x9100 + i));
const same2 = got2.every((b, i) => b === src[i]);
console.log('sp bytes match', same2, 'cycles', s.cyc, 'sp', s.sp && s.sp.toString(16), 'ok', s.ok);
console.log('sp/direct', s.cyc, d.cyc, 'saved', d.cyc - s.cyc);
console.log('DI window is the whole SP move:', s.cyc, 'cycles');
if (!same2) console.log('got', got2.map(b => b.toString(16)).join(' '));
process.exit(same && same2 && d.ok && s.ok ? 0 : 1);
