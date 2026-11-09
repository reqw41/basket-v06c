#!/usr/bin/env node
'use strict';
const fs = require('fs');
const { sym } = require('./v06syms');
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
  cpu.instruction = function () { exec[cpu.pc & 0xffff] = 1; return oi(); };
  return { memory, keyboard, cpu, v06c, exec, io };
}

const emu = boot();
const rd = a => emu.memory.read(a & 0xffff, false);
const keys = (row, mask) => { for (let i = 0; i < 8; i++) emu.keyboard.matrix[i] = 0; if (mask) emu.keyboard.matrix[row] = mask; };

const assert=require('assert');
const wr=(a,v)=>emu.memory.write(a&65535,v,false);
let cases=0;
for(const [sw,sh] of [[1,8],[2,16],[3,32],[4,40],[5,48]]) for(const base of [0x2000,0xb9f0]) for(const sx of [0,3,6,10,18,28]) for(const sy of [0,12,25,40,80]){
 const rx=6,ry=20,rw=5,rh=24;
 const source=Array.from({length:sw*sh*2},(_,i)=>(i*73+cases*11)&255);
 const expect=Array.from({length:rw*rh*2},(_,i)=>(i*31+9)&255);
 for(let i=0;i<source.length;i++)wr(0xb498+i,source[i]);
 for(let i=-1;i<=expect.length;i++)wr(base+i,i>=0&&i<expect.length?expect[i]:0xa5);
 [sx,sy,sw,sh].forEach((v,i)=>wr(0xf81+i,v));[rx,ry,rw,rh].forEach((v,i)=>wr(0xf1a+i,v));wr(0xf6d,base&255);wr(0xf6e,base>>8);wr(0x0ff6,0x81);wr(0x0ff7,0x0f); // PCC_RECT
 for(let y=0;y<sh;y++)for(let x=0;x<sw;x++)if(sx+x>=rx&&sx+x<rx+rw&&sy+y>=ry&&sy+y<ry+rh){
  const src=(y*sw+x)*2,dst=((sy+y-ry)*rw+sx+x-rx)*2;
  const a=source[src],b=source[src+1],mask=(~(a|b))&255;
  expect[dst]=(expect[dst]&mask)|b;expect[dst+1]=(expect[dst+1]&mask)|a;
 }
 const st=emu.cpu.getState();Object.assign(st,{pc:sym('PLAYER_COMPOSE_CLIPPED'),sp:0xbf00,h:0xb4,l:0x98,ix:0xf81,iy:0x1234,iff1:0,iff2:0,halted:false});emu.cpu.setState(st);wr(0xbf00,0xfe);wr(0xbf01,0xff);
 let n=0;while(emu.cpu.pc!==0xfffe&&n++<100000)emu.cpu.instruction();assert(n<100000,'helper did not return');
 const actual=Array.from({length:expect.length},(_,i)=>rd(base+i));
 assert.deepStrictEqual(actual,expect,`base=${base.toString(16)} sprite=${sx},${sy}`);
 assert.strictEqual(rd(base-1),0xa5);assert.strictEqual(rd(base+expect.length),0xa5);
 const after=emu.cpu.getState();assert.strictEqual((after.h<<8)|after.l,0xb498+source.length);assert.strictEqual(after.sp,0xbf02);assert.strictEqual(after.ix,0xf81);assert.strictEqual(after.iy,0x1234);
 cases++;
}
console.log(`PASS clipped compositor: ${cases} cases, both buffers, complete source advance and guards`);

let rowCases=0;const expectedCourt=[];
function invoke(pc){const st=emu.cpu.getState();Object.assign(st,{pc,sp:0xbf00,iff1:0,iff2:0,halted:false});emu.cpu.setState(st);wr(0xbf00,0xfe);wr(0xbf01,0xff);let n=0;while(emu.cpu.pc!==0xfffe&&n++<300000)emu.cpu.instruction();assert(n<300000);return emu.cpu.getState().a;}
// Changing timer digits must refresh both bits, including their black cells.
for(const glyph of [[0,255,85,170,60,129,24,0],[255,0,170,85,195,126,231,255]]){
 glyph.forEach((v,i)=>wr(0x3e00+i,v));wr(0x4102,20);wr(0x4103,14);
 const st=emu.cpu.getState();st.h=0x3e;st.l=0;emu.cpu.setState(st);invoke(sym('NATIVE_TEXT_GLYPH'));
 for(let i=0;i<8;i++){assert.strictEqual(rd(0xee3f-i),glyph[i]);assert.strictEqual(rd(0xce3f-i),glyph[i]^255);}
}
console.log('PASS native text: changing glyphs remain white on black in both planes');
// Dual-plane text menu: MENU_BG_RELOAD expands both LZ streams from 1000.
const menuLo=fs.readFileSync(path.join(ROOT,'build/v06/menu_text_lo.bin'));
const menuHi=fs.readFileSync(path.join(ROOT,'build/v06/menu_text_hi.bin'));
{const st=emu.cpu.getState();st.ix=0x1234;emu.cpu.setState(st);invoke(sym('MENU_BG_RELOAD'));
 // LZ chrome matches the packed planes; the controls (y150/161/172) and
 // the copyright (y184) are drawn afterwards by MENU_DRAW_COPYRIGHT.
 const textRow=(y)=>[150,161,172,184].some((t)=>y>=t&&y<t+8);
 for(let col=0;col<32;col++)for(let y=0;y<256;y++){
  if(textRow(y)) continue;
  const at=col*256+((0xdf-y)&0xff);
  assert.strictEqual(rd(0xe000+at),menuLo[at],`menu lo y${y} col${col}`);
  assert.strictEqual(rd(0xc000+at),menuHi[at],`menu hi y${y} col${col}`);
 }
 // The menu flag is set (menu publishes put players on the blue panel).
 assert.strictEqual(rd(0x0fef),1);assert.strictEqual(emu.cpu.getState().ix,0x1234);
 // Copyright footer present on the low plane.
 let copyInk=0;
 for(let col=1;col<=30;col++) for(let y=184;y<192;y++){
  const at=col*256+((0xdf-y)&0xff);
  if(rd(0xe000+at)) copyInk++;
 }
 assert.ok(copyInk>100,`copyright ink ${copyInk}`);
 // Controls: pink labels (both planes) and white text (low plane only).
 for(const y of [150,161,172]){
  let pink=0,white=0;
  for(let col=0;col<32;col++)for(let r=0;r<8;r++){
   const at=col*256+((0xdf-y-r)&0xff),lo=rd(0xe000+at),hi=rd(0xc000+at);
   pink+=lo&hi?1:0; white+=lo&~hi&255?1:0;
  }
  assert.ok(pink>10&&white>20,`controls y${y}: pink ${pink} white ${white}`);
 }
}
console.log('PASS text menu: both colour planes, controls, copyright footer, menu flag');
wr(0xfef,0); // match/court fetch must not see a leftover menu snap

// Independent etalon: CPC court with VECTOR boards, written by the packer.
const expectedPairs=fs.readFileSync(path.join(ROOT,'build/v06/expected_court_pairs.bin'));
for(let y=0;y<112;y++)for(let x=0;x<32;x++){
 const i=(y*32+x)*2;
 const low=expectedPairs[i], high=expectedPairs[i+1];
 expectedCourt.push(low,high);
 wr(0xfee,1);const address=0x2500+y*32+x;
 const st=emu.cpu.getState();st.h=address>>8;st.l=address&255;st.b=0x12;st.c=0x34;st.d=0x56;st.e=0x78;emu.cpu.setState(st);
 assert.strictEqual(invoke(sym('PLAYER_BACKGROUND_ROW')),low,`CPC low row ${y}, col ${x}`);
 assert.strictEqual(rd(0xf59),high,`CPC high row ${y}, col ${x}`);
 const after=emu.cpu.getState();assert.strictEqual((after.h<<8)|after.l,address);assert.strictEqual((after.b<<8)|after.c,0x1234);assert.strictEqual((after.d<<8)|after.e,0x5678);
 wr(0xf5c,x);wr(0xf5d,y+8);assert.strictEqual(invoke(sym('PLAYER_BACKGROUND_HIGH')),high);
 rowCases++;
}
// Execute the physical two-plane initial publication, not just the fetcher.
invoke(sym('COURT_COLORIZE'));
for(let y=0;y<112;y++)for(let x=0;x<32;x++){
 const at=x*256+0xd7-y,i=(y*32+x)*2;
 assert.strictEqual(rd(0xe000+at),expectedCourt[i]);assert.strictEqual(rd(0xc000+at),expectedCourt[i+1]);
}
console.log('PASS physical court publication: every pixel in both hardware planes');
// Band copier (TILE_BAND_FILL) borrows SP one row at a time: every row from
// the first one to the band end, odd and even widths, both tile banks.
let fastRows=0;
assert.strictEqual(sym("tbf_first")>>8,sym("tbf_second")>>8,"COMPOSE_BOX patches only the low byte of TBF_ENTRY");
const w16=(a,v)=>{wr(a,v&255);wr(a+1,v>>8);};
for(let y=0;y<112;y++)for(const x of [0,3,7,15,26,27,31])for(const width of [1,2,5,Math.min(6,32-x)]){
 if(x+width>32)continue;
 const address=0x2500+y*32+x;wr(0xf1c,width);
 const st=emu.cpu.getState();Object.assign(st,{h:address>>8,l:address&255,b:0,c:x*2});emu.cpu.setState(st);
 const displacement=invoke(sym('COURT_TILE_ROW_POINTER'));const ptr=emu.cpu.getState();w16(0x0f69,(ptr.h<<8)|ptr.l);
 const rows=Math.min((16-displacement)>>1,112-y),bytes=rows*width*2;
 wr(sym('TBF_WIDTH')+1,(width+1)>>1);w16(sym('TBF_ENTRY')+1,width&1?sym('tbf_second'):sym('tbf_first'));
 wr(sym('TBF_END')+1,displacement+2*rows);w16(sym('tbf_sp')+1,0xbf00);
 const next=emu.cpu.getState();Object.assign(next,{d:0x20,e:0,c:displacement});emu.cpu.setState(next);
 wr(0x1fff,0xa5);wr(0x2000+bytes,0xa5);invoke(sym('TILE_BAND_FILL'));
 for(let r=0;r<rows;r++)assert.deepStrictEqual(Array.from({length:width*2},(_,i)=>rd(0x2000+r*width*2+i)),
  expectedCourt.slice(((y+r)*32+x)*2,((y+r)*32+x+width)*2),`y ${y} x ${x} w ${width} row ${r}`);
 const after=emu.cpu.getState();
 assert.strictEqual(rd(0x1fff),0xa5);assert.strictEqual(rd(0x2000+bytes),0xa5);assert.strictEqual(after.sp,0xbf02);
 assert.strictEqual((after.d<<8)|after.e,0x2000+bytes);assert.strictEqual(after.iff1?1:0,1);fastRows+=rows;
}
console.log(`PASS SP band copier: ${fastRows} rows, odd/even widths, clipped columns, source banks and real stack restored`);
// Damage boxes (damage_publish.asm): a rectangle merges into every box it
// touches while the bounding box fits the 1280-byte buffer; boxes it grows
// into are absorbed too. Boxes are c0,r0,c1,r1 (exclusive ends).
let boxCases=0;
for(const [rects,want] of [
 [[[4,40,3,32],[5,38,3,40]],[[4,38,8,78]]],                                  // a moving player
 [[[1,24,3,24],[28,24,3,24]],[[1,24,4,48],[28,24,31,48]]],                   // apart
 [[[0,0,10,40],[10,0,10,40]],[[0,0,10,40],[10,0,20,40]]],                    // touching, union 800 pairs
 [[[2,10,3,20],[20,10,3,20],[5,15,15,10]],[[2,10,23,30]]],                   // a bridge joins both
 [[[3,3,2,2],[3,3,2,2]],[[3,3,5,5]]],                                        // identical
 [[[5,10,22,29],[6,20,3,32]],[[5,10,27,39],[6,20,9,52]]],                    // stamp is full
]){
 wr(sym('DMG_BASE'),0x00);wr(sym('DMG_BASE')+1,0xb8);wr(sym('DMG_END'),0x00);wr(sym('DMG_END')+1,0xb8);
 for(const r of rects){r.forEach((v,i)=>wr(0x3e00+i,v));const st=emu.cpu.getState();st.h=0x3e;st.l=0;emu.cpu.setState(st);invoke(sym('DMG_ADD_RECT'));
  const after=emu.cpu.getState();assert.strictEqual((after.h<<8)|after.l,0x3e00);}
 const end=rd(sym('DMG_END'))|(rd(sym('DMG_END')+1)<<8),got=[];
 for(let a=0xb800;a<end;a+=4)got.push([rd(a),rd(a+1),rd(a+2),rd(a+3)]);
 const key=(x)=>x.map(String).sort();
 assert.deepStrictEqual(key(got),key(want),JSON.stringify(rects));boxCases++;
}
console.log(`PASS damage boxes: ${boxCases} layouts merge only within the buffer`);

wr(0xfef,1);
// Fast stub: menu snap always returns high 0 from TITLE_SRC.
wr(0x2000+8*32+8,0);{const st=emu.cpu.getState();st.h=0x20;st.l=8*32+8;emu.cpu.setState(st);
 assert.strictEqual(invoke(sym('PLAYER_BACKGROUND_ROW')),0);assert.strictEqual(rd(0xf59),0);}
wr(0xfef,0);
console.log(`PASS exact CPC tiles: ${rowCases} two-plane bytes, both bank segments, register preservation and menu`);

let shiftCases=0;
// Shift 0 rows take STAGE_ALIGNED_ROW. Shifted rows: the unrolled CP3_<shift>
// code entered (3 - stride) blocks in, HL source, DE stream (every other
// byte), C = 0 (color_sprite.asm).
const cp3={2:sym('CP3_TWO'),4:sym('CP3_FOUR'),6:sym('CP3_SIX')};
const cp3block={2:sym('CP3_TWO_1')-sym('CP3_TWO'),4:sym('CP3_FOUR_1')-sym('CP3_FOUR'),6:sym('CP3_SIX_1')-sym('CP3_SIX')};
for(const shift of [2,4,6])for(const stride of [1,2,3])for(let seed=0;seed<256;seed++){
 const src=Array.from({length:stride},(_,i)=>(seed+i*83)&255);
 src.forEach((v,i)=>wr(0xb498+i,v));for(let i=0;i<10;i++)wr(0xb1e4+i,0xa5);
 const st=emu.cpu.getState();Object.assign(st,{h:0xb4,l:0x98,d:0xb1,e:0xe4,c:0});emu.cpu.setState(st);invoke(cp3[shift]+(3-stride)*cp3block[shift]);
 const expected=[];let carry=0;
 for(const byte of src){expected.push((byte>>>shift)|carry);carry=(byte<<(8-shift))&255;}
 expected.push(carry);
 assert.deepStrictEqual(Array.from({length:expected.length},(_,i)=>rd(0xb1e4+2*i)),expected,`shift=${shift}, stride=${stride}, seed=${seed}`);
 for(let i=0;i<expected.length;i++)assert.strictEqual(rd(0xb1e5+2*i),0xa5,'odd bytes untouched');
 assert.strictEqual(rd(0xb1e4+2*expected.length),0xa5);
 const after=emu.cpu.getState();assert.strictEqual((after.h<<8)|after.l,0xb498+stride);assert.strictEqual((after.d<<8)|after.e,0xb1e4+2*expected.length);
 shiftCases++;
}
let alignedCases=0;
for(const stride of [1,2,3])for(let skip=0;skip<stride;skip++)for(let width=1;width<=stride-skip;width++){
 const src=Array.from({length:stride*2},(_,i)=>(i*71+width*11)&255);src.forEach((v,i)=>wr(0xb498+i,v));
 wr(0xf5a,0x98);wr(0xf5b,0xb4);wr(0xf5c,stride);wr(0xb1e2,skip);wr(0xb1e1,width);wr(0xf69,0);wr(0xf6a,0x20);
 wr(0x1fff,0xa5);wr(0x2000+width*2,0xa5);invoke(sym('STAGE_ALIGNED_ROW'));
 const expected=[];for(let i=skip;i<skip+width;i++)expected.push(src[i],src[stride+i]);
 assert.deepStrictEqual(Array.from({length:width*2},(_,i)=>rd(0x2000+i)),expected);
 assert.strictEqual(rd(0xf5a)|(rd(0xf5b)<<8),0xb498+stride*2);assert.strictEqual(rd(0xf69)|(rd(0xf6a)<<8),0x2000+width*2);
 assert.strictEqual(rd(0x1fff),0xa5);assert.strictEqual(rd(0x2000+width*2),0xa5);alignedCases++;
}
console.log(`PASS shifted rows: ${shiftCases} cases; aligned clipped rows: ${alignedCases} cases`);


