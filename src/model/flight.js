'use strict';
/**
 * Ball flight (ix = 93F5, the flight block 93EB..9400), 9A1B..9C7B.
 *   9A1B  shot flight: on the first step aim a line from the hand (93F1/93F3)
 *         to the basket (0554 or 3954 by 93EB bit 7), then step it (9B0B) and
 *         lift the ball by a parabola (398C/39A3) from table 9B69
 *   9AF6  line setup (B = |dy|, C = |dx|/2, D/E = signs), 9B0B step, 9B4C resume
 *         from the saved state ix+3..ix+0A. The alternate set holds the step
 *         direction (exx), as on the Z80.
 *   9BF6  rebound: random table 9B89/9B9F/9BBB/9BD7, side by the random bits
 */
const { io } = require('./ent');
const { C, Z, add8, sub8, cp8, and8, or8, xor8, inc8, dec8, neg, srl, rra, bit, bitm, exx } = require('./z80');

const FLIGHT = 0x93F5;

function shotFlight(m) {                 // 9A1B
  const r = m.r, { ix, wx, sx } = io(m);
  r.ix = FLIGHT;
  if (bitm(r, 0, ix(0))) {
    if (bitm(r, 2, ix(0))) {             // 9A84: the line has ended: drop by 4
      bit(r, 7, m.rd(0x93EB));
      const neg1 = !(r.f & Z);
      r.a = 1;
      if (!neg1) r.a = neg(r, r.a);
      r.c = ix(-1);
      r.a = add8(r, r.a, r.c);
      wx(-1, r.a); wx(-3, r.a);
      r.a = add8(r, ix(-4), 4);
      wx(-4, r.a);
      sx(0, 1);
      return;
    }
    lineResume(m);
  } else {
    wx(0, 1);
    r.a = 1; m.wr(0x93F0, 1);
    m.wr16(0x93ED, 0x9B69);
    r.l = ix(-2); r.h = ix(-1);
    r.a = m.rd(0x93F1);
    wx(1, r.a);
    r.a = sub8(r, r.a, 0x1E);
    if (r.f & C) { r.a = neg(r, r.a); sx(0, 7); }
    wx(2, r.a);
    r.d = 0x05; r.e = 0x54;
    if (bitm(r, 7, ix(-0x0A))) r.d = 0x39;
    r.a = r.d;
    r.h = srl(r, r.h);
    r.a = sub8(r, r.a, r.h);
    r.d = 2;
    if (r.f & C) { r.a = neg(r, r.a); r.d = 0xFE; }
    r.b = r.a;
    r.a = sub8(r, r.e, r.l);
    r.e = 2;
    if (r.f & C) { r.a = neg(r, r.a); r.e = 0xFE; }
    r.c = r.a;
    r.c = srl(r, r.c);
    r.a = r.b;
    cp8(r, r.a, r.c);
    if (r.f & C) r.a = r.c;
    m.wr(0x93EF, r.a);
    r.a = srl(r, r.a);
    m.wr(0x93EC, r.a);
    lineSetup(m);
  }
  let hl = m.rd16(0x93ED);               // 9AAF: the height table
  r.c = m.rd(hl);
  r.a = and8(r, m.rd(0x93EC), m.rd(0x93EC));
  if (!r.a) hl = (hl - 1) & 0xffff;
  else { r.a = dec8(r, r.a); m.wr(0x93EC, r.a); hl = (hl + 1) & 0xffff; }
  m.wr16(0x93ED, hl);
  r.h = ix(-1);
  wx(-3, r.h);
  m.push(r.b << 8 | r.c);
  r.c = ix(-5);
  wx(-5, inc8(r, ix(-5)));
  r.l = ix(2); r.h = 0; r.b = 0;
  m.call(0x398C);
  r.b = 0; r.c = ix(-6);
  m.call(0x39A3);
  if (bitm(r, 7, ix(0))) { r.a = neg(r, r.l); r.l = r.a; }
  r.a = sub8(r, ix(1), r.l);
  const bc = m.pop(); r.b = bc >> 8; r.c = bc & 0xff;
  r.a = sub8(r, r.a, r.c);
  wx(-4, r.a);
}

function lineSetup(m) {                  // 9AF6
  const r = m.r;
  r.a = r.c;
  cp8(r, r.a, r.b);
  if (r.f & C) {
    r.l = r.c;
    m.push(r.d << 8 | r.e);
    r.a = xor8(r, r.a, r.a);
    r.e = 0;
  } else {
    r.a = or8(r, r.a, r.c);
    if (!r.a) return lineEnd(m);
    r.l = r.b; r.b = r.c;
    m.push(r.d << 8 | r.e);
    r.d = 0;
  }
  r.h = r.b;
  r.a = r.b;
  rra(r);
  return lineStep(m);
}

function lineStep(m) {                   // 9B0B (A = error, the direction pushed)
  const r = m.r, { ix, wx } = io(m);
  r.a = add8(r, r.a, r.l);
  let diag = !!(r.f & C);
  if (!diag) { cp8(r, r.a, r.h); diag = !(r.f & C); }
  if (diag) {                            // 9B11: step both ways
    r.a = sub8(r, r.a, r.h);
    r.c = r.a;
    exx(r);
    const v = m.pop(); r.b = v >> 8; r.c = v & 0xff;
    m.push(v);
  } else {                               // 9B18: step the long axis only
    r.c = r.a;
    m.push(r.d << 8 | r.e);
    exx(r);
    const v = m.pop(); r.b = v >> 8; r.c = v & 0xff;
  }
  r.a = add8(r, r.b, ix(-1));            // 9B1C
  wx(-1, r.a);
  r.b = r.a;
  r.a = add8(r, r.c, ix(-2));
  wx(-2, r.a);
  exx(r);
  r.b = dec8(r, r.b);
  wx(3, r.l); wx(4, r.h); wx(5, r.c); wx(6, r.b); wx(7, r.e); wx(8, r.d);
  const hl = m.pop(); r.h = hl >> 8; r.l = hl & 0xff;
  wx(9, r.l); wx(0x0A, r.h);
  if (!(r.f & Z)) return;
  return lineEnd(m);
}
function lineEnd(m) {                    // 9B47
  const r = m.r;
  m.wr(r.ix, m.rd(r.ix) | 0x04);
}
function lineResume(m) {                 // 9B4C
  const r = m.r, { ix } = io(m);
  r.e = ix(9); r.d = ix(0x0A);
  m.push(r.d << 8 | r.e);
  r.l = ix(3); r.h = ix(4); r.c = ix(5); r.b = ix(6); r.e = ix(7); r.d = ix(8);
  r.a = r.c;
  return lineStep(m);
}

function rebound(m) {                    // 9BF6
  const r = m.r, { ix, wx, sx, rx } = io(m);
  r.ix = FLIGHT;
  if (!bitm(r, 0, ix(0))) {
    wx(0, 0x41);
    m.call(0x386E);
    m.push(r.a << 8 | r.f);
    m.call(0x386E);
    r.a = and8(r, r.a, 3);
    let hl = 0x9B89;
    if (r.a) {
      hl = 0x9B9F; r.a = dec8(r, r.a);
      if (r.a) { hl = 0x9BBB; r.a = dec8(r, r.a); if (r.a) hl = 0x9BD7; }
    }
    m.wr16(0x93ED, hl);
    const af = m.pop(); r.a = af >> 8; r.f = af & 0xff;
    r.a = and8(r, r.a, 3);
    if (r.a) {
      rx(0, 6);
      if (bit(r, 0, r.a)) sx(0, 7);
    }
  }
  let hl = m.rd16(0x93ED);               // 9C36
  r.a = and8(r, m.rd(0x93D6), m.rd(0x93D6));
  if (r.a || !bitm(r, 6, ix(0))) {
    r.a = m.rd(hl);
    if (bitm(r, 7, ix(0))) r.a = neg(r, r.a);
    r.a = add8(r, r.a, ix(-2));
    wx(-2, r.a);
  }
  hl++;                                  // 9C54
  bit(r, 7, m.rd(0x93EB));
  const nz = !(r.f & Z);
  r.a = m.rd(hl);
  if (nz) r.a = neg(r, r.a);
  r.a = add8(r, r.a, ix(-1));
  wx(-1, r.a); wx(-3, r.a);
  hl++;
  r.a = add8(r, m.rd(hl), ix(-4));
  wx(-4, r.a);
  hl++;
  m.wr16(0x93ED, hl);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = inc8(r, m.rd(hl));
  if (r.a) return;
  sx(0, 1);
}

module.exports = { procs: { '9A1B': shotFlight, '9AF6': lineSetup, '9B0B': lineStep, '9B4C': lineResume, '9BF6': rebound } };
