'use strict';
/**
 * Replay, the whistle and small screens, A82C..A9C6, AE34..AF0D.
 *   A82C  replay: frame boxes, the ring buffer (RING_REPLAY 751C), the match
 *         state 93EB..9439 saved to 1B40 and back, scenes 144C/144F, A8C8 / A8F4
 *         (platform) until the space key; 93D1 = 1 while replaying
 *   A95E  ring reset; A969 ring push (not during an event)
 *   A9AD  whistle: 150 toggles of the beeper (0135) with a delay loop
 *   AE34 / AE40  controls table: 5 bytes through the pointer list, AC4F = speed
 *   AEFA  print DE (FF-terminated) at HL through RST 18
 *   AF05  keys + pads (37CC, 3811, NATIVE_PADS)
 */
const { Z, P, C, cp8, and8, or8, xor8, inc8, dec8, sub8, bit, ldir } = require('./z80');

function replay(m) {                     // A82C
  const r = m.r;
  m.call(0x3769);
  const box = (h, l, b, c, a) => { r.h = h; r.l = l; r.b = b; r.c = c; r.a = a; m.call(0xA75F); };
  box(0x00, 0x00, 0x20, 0x70, 0x1F);
  r.h = 0x08; r.l = 0x40; r.b = 0x18; r.c = 0x20;
  r.a = m.rd(0x9400);
  if (bit(r, 7, r.a)) r.h = 0;
  r.a = 0x1A;
  m.call(0xA75F);
  box(0x00, 0x70, 0x20, 0x50, 0x17);
  m.pcall(0x751C);
  const save = (from, to) => { r.h = from >> 8; r.l = from & 0xff; r.d = to >> 8; r.e = to & 0xff; r.b = 0; r.c = 0x4F; ldir(m); };
  save(0x93EB, 0x1B40);
  r.a = xor8(r, r.a, r.a);
  m.wr(0x3332, 0);
  r.a = inc8(r, r.a);
  m.wr(0x93D1, 1);
  r.a = m.rd(0x9400);
  m.wr(0x3333, r.a);
  bit(r, 7, r.a);
  r.h = 0; r.l = r.f & Z ? 0 : 0x10;
  m.wr16(0xA8F9, r.l);
  m.call(0xA991);
  m.pcall(0x144C);
  m.pcall(0x144F);
  m.call(0xA8F4);
  m.call(0x3758);
  for (;;) {                             // A893
    r.a = dec8(r, m.rd(0x93D3));
    const z = !r.a;
    r.a = 0x0A;
    if (z) break;
    m.call(0xA991);
    m.pcall(0x144C);
    m.pcall(0x144F);
    m.call(0xA8C8);
    m.call(0xA8F4);
    r.a = sub8(r, m.rd(0x4110), 0x20);
    if (!r.a) { m.wr(0x93D3, 0); r.a = inc8(r, r.a); break; }
  }
  save(0x1B40, 0x93EB);                  // A8B5
  m.pcall(0x08DE);
  r.a = xor8(r, r.a, r.a);
  m.wr(0x93D1, 0);
}

function ringReset(m) { const r = m.r; r.a = xor8(r, r.a, r.a); m.wr(0x93D3, 0); return m.jp(0x7511); }   // A95E
function ringPush(m) {                   // A969
  const r = m.r;
  r.a = and8(r, m.rd(0x9400), m.rd(0x9400));
  if (r.a) return;
  return m.jp(0x74E8);
}

function whistle(m) {                    // A9AD
  const r = m.r;
  r.iff = 0;
  r.e = 0x96;
  r.a = xor8(r, r.a, r.a);
  do {
    m.push(r.a << 8 | r.f);
    m.pcall(0x0135);
    const af = m.pop(); r.a = af >> 8; r.f = af & 0xff;
    r.a = xor8(r, r.a, 0x10);
    r.d = r.a;
    let bc = 0x02BC;
    do { bc = (bc - 1) & 0xffff; r.a = or8(r, bc >> 8, bc & 0xff); } while (r.a);
    r.b = 0; r.c = 0;
    r.a = r.d;
    r.e = dec8(r, r.e);
  } while (r.e);
  r.iff = 1;
}

function ctlTable(m) { m.r.ix = 0xAE6D; m.r.h = 0xAE; m.r.l = 0x67; return ctlCopy(m); }   // AE34
function ctlCopy(m) {                    // AE40: 5 x LDI through the pointers at IX
  const r = m.r;
  let bc = 5, hl = r.h << 8 | r.l, v = 0;
  do {
    r.e = m.rd(r.ix); r.ix = (r.ix + 1) & 0xffff;
    r.d = m.rd(r.ix); r.ix = (r.ix + 1) & 0xffff;
    v = m.rd(hl); m.wr(r.d << 8 | r.e, v);
    hl = (hl + 1) & 0xffff; bc--;
    const de = ((r.d << 8 | r.e) + 1) & 0xffff; r.d = de >> 8; r.e = de & 0xff;
    const t = (r.a + v) & 0xff;
    r.f = (r.f & 0xC1) | (bc ? P : 0) | (t & 0x02 ? 0x20 : 0) | (t & 0x08 ? 0x08 : 0);
  } while (bc);
  r.b = 0; r.c = 0;
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = m.rd(hl);
  m.wr(0xAC4F, r.a);
}

function printAt(m) {                    // AEFA
  const r = m.r;
  m.wr(0x4102, r.l); m.wr(0x4103, r.h);
  for (;;) {
    let de = r.d << 8 | r.e;
    r.a = m.rd(de); de = (de + 1) & 0xffff; r.d = de >> 8; r.e = de & 0xff;
    cp8(r, r.a, 0xFF);
    if (r.a === 0xFF) return;
    m.pcall(0x0018);
  }
}

function pads(m) {                       // AF05
  m.call(0x37CC);
  m.call(0x3811);
  return m.jp(0x6CD0);
}

module.exports = {
  procs: {
    'A82C': replay, 'A95E': ringReset, 'A969': ringPush, 'A9AD': whistle,
    'AE34': ctlTable, 'AE40': ctlCopy, 'AEFA': printAt, 'AF05': pads,
  },
};

// AE19 (AC44): controls defaults (AE15..AE18), then both tables
function ctlInit(m) {
  const r = m.r;
  r.a = 1; m.wr(0xAE15, 1); m.wr(0xAE17, 1);
  r.a = xor8(r, r.a, r.a); m.wr(0xAE16, 0); m.wr(0xAE18, 0);
  m.call(0xAE34);
  r.ix = 0xAE5D; r.h = 0xAE; r.l = 0x57;
  return ctlCopy(m);
}
module.exports.procs.AE19 = ctlInit;
module.exports.procs['9F6D'] = () => {};   // the clock-off hook: RET
