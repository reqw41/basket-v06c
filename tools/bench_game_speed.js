#!/usr/bin/env node
/** Measure real keyboard-driven match ticks using emulated time.
 * node tools/bench_game_speed.js path/to.rom [--motion] [--min-hz 5.5]
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

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
g.console = {log:()=>{},debug:()=>{},error:console.error,warn:console.warn};
const ctx = vm.createContext(g);
// CPU=i8080: the recompiled image on the i8080 core; the game loop 8554 moves.
const I8080_IMAGE = process.env.CPU === 'i8080';
const ITER = I8080_IMAGE ? parseInt(JSON.parse(fs.readFileSync(path.join(__dirname, '../build/i8080/labels.json'))).map['8554'], 16) : 0x8554;
for (const f of [
  'i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js',
  'src/fili.js', 'src/ay.js', 'src/fd1793.js', 'src/fddimage.js', 'src/i8253.js',
  'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  ...(I8080_IMAGE ? [] : ['Z80_v06.js', 'z80_adapter.js']),
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
  if (!I8080_IMAGE) {
    const st = cpu.getState();
    st.pc = 0x0100; st.sp = 0xe000; st.iff1 = 0; st.iff2 = 0; st.halted = false; st.imode = 1;
    cpu.setState(st);
  }
  cpu.pc = 0x0100; cpu.sp = 0xe000;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  const exec = new Uint8Array(0x10000);
  const oi = cpu.instruction.bind(cpu);
  cpu.instruction = function () { exec[cpu.pc & 0xffff] = 1; return oi(); };
  return { memory, keyboard, cpu, v06c, exec, io };
}

const emu = boot();
const rd = a => emu.memory.read(a & 0xffff, false);
const keys = (row, mask) => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; if (mask) emu.keyboard.matrix[row] = mask; };

// Emulated time, independent of host runtime. --motion reproduces the
// additional movement/stop run; no physics flags or CPU entry are forced.
const moving=process.argv.includes('--motion');
let phase='title',match=0,frame=0,active=false;
const ticks=[],publishes=[];
const oi=emu.cpu.instruction.bind(emu.cpu);
emu.cpu.instruction=function(){ const pc=this.pc&65535; if(active && pc===ITER)ticks.push({frame,x:rd(0x940d),y:rd(0x940e)}); if(active && pc===0x3fb0)publishes.push(frame); return oi(); };
for(frame=0;frame<1050;frame++){
 keys(0,0);if(phase==='title'&&frame>=8&&frame<40)keys(7,0x80);if(phase==='menu'&&frame>=190)keys(2,0x02);if(moving&&phase==='move'&&frame-match<170)keys(0,0x40);

 active=phase==='move'&&frame-match>=120&&frame-match<620;
 emu.v06c.oneFrame();
 if(phase==='title'&&rd(0x940d)===0x6e&&rd(0x9427)===0x6e&&rd(0x940b)===0x10)phase='menu';
 else if(phase==='menu'&&rd(0x0fed)===1){phase='move';match=frame;}
}
const hardwareHz=3000000/59904;
const result={rom:ROM,rom_sha256:require('crypto').createHash('sha256').update(fs.readFileSync(ROM)).digest('hex'),scenario:moving?'1p-motion-stop':'1p-no-input',matchFrame:match,windowFrames:500,seconds:500/hardwareHz,tickCount:ticks.length,tickHz:ticks.length*hardwareHz/500,publishHz:publishes.length*hardwareHz/500,ticks,publishes};
console.log(JSON.stringify(result));
const minAt=process.argv.indexOf('--min-hz');
if(!match||!ticks.length||(minAt>=0&&result.tickHz<Number(process.argv[minAt+1])))process.exitCode=1;
