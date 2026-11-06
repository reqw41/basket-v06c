#!/usr/bin/env node
/**
 * Court cleanliness after every publish (headless vector06js, keyboard only).
 *   node tools/test_court_clean.js [rom] [dump_dir]   env SEED (12345), NF (3000)
 *
 * At each COLOR_FRAME_END publish (0B01) during a live match, every court
 * byte pair outside the current sprite rectangles (rows 8..111, stands
 * included) must equal the seated court etalon, or the stamped one while
 * BG_FETCH (B338) points at the CPC stamp. Random 1P play from SEED.
 * Exit 1 on any damaged publish or when no publish was checked.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = path.resolve(process.argv[2] || path.join(ROOT, 'build/v06/basket.rom'));

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
]) vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

function boot() {
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
  for (let i = 0; i < file.length && base + i < 0x10000; i++) memory.write(base + i, file[i], false);
  if (base === 0x100) for (let i = 0; i < 0x100; i++) memory.write(i, memory.read(0x0e00 + i, false), false);
  const st = cpu.getState();
  st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1;
  cpu.setState(st); cpu.pc = 0x0100; cpu.sp = 0xe000;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  const exec = new Uint8Array(0x10000);
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () { const p = cpu.pc & 0xffff; exec[p] = 1; if (global.HOOK && WATCH[p]) global.HOOK(p); return oi(); };
  return { memory, keyboard, cpu, v06c, exec };
}

// cfp_done: the frame is published (adapter entries float: tools/v06syms.js).
const CFP_DONE = require('./v06syms').sym('cfp_done');
const WATCH = {[CFP_DONE]:1};
const emu = boot();
const rd = a => emu.memory.read(a & 0xffff, false);
const E0=fs.readFileSync(path.join(ROOT, 'build/v06/expected_court_pairs.bin')); const E1=fs.readFileSync(path.join(ROOT, 'build/v06/expected_stamped_court_pairs.bin'));
const keys = (row, mask) => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; if (mask) emu.keyboard.matrix[row] = mask; };
const OUT=process.argv[3]; if (OUT) fs.mkdirSync(OUT,{recursive:true});
let frame=0, phase='title', nfe=0, nbad=0, shown=0;
global.HOOK = p => {
  if (phase!=='match' || rd(0x93d1)) return;
  nfe++;
  const n=rd(0x0f80), R=[];
  for (let k=0;k<n;k++) R.push([rd(0x0f81+4*k),rd(0x0f82+4*k),rd(0x0f83+4*k)&0x7f,rd(0x0f84+4*k)]);
  const on=(rd(0xb339)|rd(0xb33a)<<8)!==0x1800; const E=on?E1:E0; if(on) global.NON=(global.NON||0)+1; const bad=[];
  for (let cr=+(process.env.R0||8); cr<112; cr++) for (let col=0; col<32; col++) {
    if (R.some(([c,r,w,h])=>c<=col&&col<c+w&&r<=cr&&cr<r+h)) continue;
    const y=cr+8, lo=rd(0xe000+col*256+0xdf-y), hi=rd(0xc000+col*256+0xdf-y);
    if (lo!==E[(cr*32+col)*2]||hi!==E[(cr*32+col)*2+1]) bad.push(`c${col}r${cr}`);
  }
  if (bad.length) { nbad++; if (shown++<15) console.log(`F${frame} stamp=${on?1:0} n=${n} noise=${rd(0x0f7c)} bad ${bad.length}: ${bad.slice(0,10).join(' ')} | ${R.map(r=>r.join(',')).join(' ')}`);
    if (OUT) { const buf=Buffer.alloc(0x4000); for (let i=0;i<0x2000;i++){buf[i]=rd(0xe000+i);buf[0x2000+i]=rd(0xc000+i);} fs.writeFileSync(`${OUT}/f${String(frame).padStart(5,'0')}.bin`,buf);} }
};
let rnd=+(process.env.SEED||12345); const rand=()=>(rnd=(rnd*1103515245+12345)&0x7fffffff)/0x7fffffff; let cur=0,hold=0;
for (; frame < +(process.env.NF||3000); frame++) {
  keys(0,0);
  if (phase==='title' && frame>=8 && frame<40) keys(7,0x80);
  if (phase==='menu') keys(2,0x02);
  if (phase==='match') { const x=rd(0x940d), y=rd(0x940e);
    if (hold--<=0){hold=5+Math.floor(rand()*30);cur=Math.floor(rand()*7);}
    if (cur<3) { if (x>0x5a) keys(0,0x10); else if (x<0x50) keys(0,0x40); else if (y>0x0c) keys(0, 0x20); else keys(7, 0x80); }
    else { const m=[[0, 0x10], [0, 0x40], [0, 0x20], [7, 0x80]][cur-3]; keys(m[0],m[1]); } }
  emu.v06c.oneFrame();
  if (phase==='title' && rd(0x940d)===0x6e && rd(0x9427)===0x6e && rd(0x940b)===0x10) phase='menu';
  else if (phase==='menu' && rd(0x0fed)===1) phase='match';
}
console.log('publishes', nfe, 'with damage', nbad, 'stamped publishes', global.NON||0);
console.log(nbad || !nfe ? 'COURT_CLEAN_FAIL' : 'COURT_CLEAN_PASS'); process.exit(nbad || !nfe ? 1 : 0);
