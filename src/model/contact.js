'use strict';
/**
 * Contact tests between two players / player and ball (ix = the mover, iy = the other).
 *   8CF7  contact by the ball state 93EB: CF = contact
 *   8D72  box test of ix against the ball position 93F3 (c = 0)
 *   8D7D  box test: HL = other (l x, h y), DE = mover (e x, d y), C = x offset;
 *         the box size depends on the poses (ix-1)/(iy-1), (iy+0) bit 4 = airborne.
 *         Result in CF (CP of the last span), A/E/D/H/L/C left as the Z80 leaves them.
 * Entities: +0 state bits (0 has ball, 4 airborne, 5 ...), +1 bits (0 = team side),
 *   +2/+3 x/y, +4/+5 ball x/y, -1 pose bits, -2 control bits.
 */
const { C, add8, sub8, cp8, and8, inc8, dec8, neg, bitm, scf } = require('./z80');

const BALL_STATE = 0x93EB, BALL_HOLD = 0x93F1, BALL_POS = 0x93F3;

function contactBall(m) {                // 8CF7
  const r = m.r, ix = (d) => m.rd(r.ix + d), iy = (d) => m.rd(r.iy + d);
  r.c = 0;
  const a = r.a = m.rd(BALL_STATE);
  let hl;
  if (!(a & 0x20)) {
    if (a & 0x01) {                      // 8D33: the ball is free
      scf(r);
      if (bitm(r, 4, ix(0))) return;
      hl = m.rd16(BALL_POS);
      if (bitm(r, 0, iy(0))) hl = (hl & 0xff00) | iy(4);
      return boxWith(m, hl);
    }
    if (a & 0x04) return held(m);
    if (!(a & 0x02)) {
      if (a & 0x08) {
        r.c = 0xE6;
        if (!bitm(r, 0, ix(0))) return boxWith(m, m.rd16(BALL_HOLD));
      } else {
        if (!(a & 0x10) || !bitm(r, 0, ix(0))) return boxBall(m);
      }
    }
    r.c = 0xE2;                          // 8D2C
    return boxWith(m, m.rd16(BALL_HOLD));
  }
  return held(m);
}
function held(m) {                       // 8D08: and a / bit 4,(ix+0) / ret z / scf
  const r = m.r;
  and8(r, r.a, r.a);
  if (!bitm(r, 4, m.rd(r.ix))) return;
  scf(r);
}
// 8D45: box test against hl first (c kept), then a second test from the hand position
function boxWith(m, hl) {
  const r = m.r, ix = (d) => m.rd(r.ix + d), iy = (d) => m.rd(r.iy + d);
  const c = r.c, b = r.b;
  boxBall(m);
  r.b = b; r.c = c; r.h = hl >> 8; r.l = hl & 0xff;
  if (!(r.f & C)) return;
  r.e = ix(2); r.d = ix(3);
  if (bitm(r, 0, ix(0))) { r.e = ix(4); r.d = ix(5); }
  if (bitm(r, 0, iy(0))) {
    let a = sub8(r, r.l, r.e);
    if (r.f & C) { a = neg(r, a); a = add8(r, a, a); }
    a = neg(r, a);
    r.c = r.a = add8(r, a, r.c);
  }
  box(m);
}
function boxBall(m) {                    // 8D72
  const r = m.r;
  r.l = m.rd(BALL_POS); r.h = m.rd(BALL_POS + 1);
  r.e = m.rd(r.ix + 2); r.d = m.rd(r.ix + 3);
  r.c = 0;
  box(m);
}

function box(m) {                        // 8D7D
  const r = m.r, ix = (d) => m.rd((r.ix + d) & 0xffff), iy = (d) => m.rd((r.iy + d) & 0xffff);
  r.e = r.a = add8(r, r.e, r.c);
  if (!bitm(r, 2, ix(-1))) return boxLow(m);
  r.c = 8; r.b = 4;
  if (bitm(r, 4, iy(0))) {
    r.c = 6;
    if (bitm(r, 2, iy(-1))) {
      r.b = 3;
      if (bitm(r, 3, iy(-1))) {
        if (bitm(r, 3, ix(-1))) r.b = inc8(r, r.b);
      } else {
        r.b = 6;
        if (!bitm(r, 3, ix(-1))) r.b = dec8(r, r.b);
      }
    } else {
      r.b = 6; r.c = 6;
      if (!bitm(r, 1, iy(-1))) { r.b = 4; r.c = inc8(r, r.c); }
    }
  }
  r.d = r.a = add8(r, r.d, r.b);         // 8DC0
  if (bitm(r, 3, ix(-1))) { r.d = r.h; r.h = r.a; }
  r.a = sub8(r, r.d, r.h);
  cp8(r, r.a, r.c);
  if (!(r.f & C)) return;
  r.a = sub8(r, add8(r, r.e, 4), r.l);
  cp8(r, r.a, 9);
}
function boxLow(m) {                     // 8DD6
  const r = m.r, ix = (d) => m.rd((r.ix + d) & 0xffff), iy = (d) => m.rd((r.iy + d) & 0xffff);
  r.c = 6;
  let a = r.e, to = 0x8E37;
  if (bitm(r, 4, iy(0))) {
    if (bitm(r, 2, iy(-1))) {
      a = dec8(r, a); r.c = dec8(r, r.c);
      if (bitm(r, 1, ix(-1))) a = dec8(r, a);
      if (!bitm(r, 0, ix(1))) a = inc8(r, a);       // 8E30
    } else {
      let side;
      if (bitm(r, 1, iy(-1))) {
        r.c = 3; r.e = a = add8(r, a, 4);
        side = bitm(r, 1, ix(-1));
        if (!side) { r.e = a = add8(r, a, 4); r.c = inc8(r, r.c); }
      } else {
        r.c = 5; r.e = a = add8(r, a, 2);
        side = bitm(r, 1, ix(-1));
        if (!side) { r.e = a = add8(r, a, 4); r.c = 2; }
      }
      if (side) {                        // 8E27
        if (!bitm(r, 0, ix(1))) r.c = dec8(r, r.c);
        to = 0x8E44;
      } else {
        if (!bitm(r, 0, ix(1))) r.c = inc8(r, r.c);
        to = 0x8E40;
      }
    }
  }
  if (to === 0x8E37) {
    r.e = a = add8(r, a, 6);
    to = bitm(r, 1, ix(-1)) ? 0x8E44 : 0x8E40;
  }
  if (to === 0x8E40) { a = sub8(r, a, 0x0A); r.e = r.l; r.l = a; }
  r.a = sub8(r, r.e, r.l);               // 8E44
  cp8(r, r.a, r.c);
  if (!(r.f & C)) return;
  a = add8(r, r.d, 0x0D);
  r.c = 0x10;
  if (bitm(r, 1, ix(-1))) { r.c = 0x0E; a = dec8(r, dec8(r, a)); }
  r.a = sub8(r, a, r.h);
  cp8(r, r.a, r.c);
}

module.exports = { procs: { '8CF7': contactBall, '8D72': boxBall, '8D7D': box } };
