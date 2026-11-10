'use strict';
/**
 * Player walk step (vector 93BB) and the ball follow (93BE), 9C7C..9E6E.
 *   9C83  stick (ix-2) -> pose (ix-1); a jump / shot press goes to 8E5A, an
 *         action in progress to 8F76; step x/y within the court and around the
 *         other player (ix+1 bit 5 = blocked), 9E47 the step rate; then 9ED4
 *   9DC2  ball in hand follows the player (93F3); out of the court = event 3,
 *         crossing the half line = event 5 (back court)
 *   9C7C  no stick: 9E82 (stamina back)
 */
const { io } = require('./ent');
const { C, Z, add8, sub8, cp8, and8, inc8, dec8, neg, srl, bit, bitm } = require('./z80');

function idle(m) {                       // 9C7C
  const { rx } = io(m);
  rx(1, 5);
  return m.jp(0x9E82);
}

function walk(m) {                       // 9C83
  const r = m.r, { ix, iy, wx, sx, rx } = io(m);
  rx(-7, 0);
  if (bitm(r, 0, ix(0))) return m.jp(0x8F76);
  r.a = and8(r, ix(-2), 0x1F);
  if (!r.a) return idle(m);
  r.b = ix(-1);
  cp8(r, r.a, 0x10);
  if (r.a === 0x10) return m.jp(0x8E5A);
  let set = true;
  if (bitm(r, 4, ix(0))) {
    if (!bit(r, 4, r.a)) set = false;
    else {
      r.a &= ~0x10;
      cp8(r, r.a, ix(-1));
      if (r.a === ix(-1)) return m.jp(0x8E5A);
    }
  } else if (bit(r, 4, r.a)) return m.jp(0x8E5A);
  if (set) wx(-1, r.a);
  const c = r.c = r.a;                   // 9CB9
  r.l = ix(2); r.h = ix(3); r.e = iy(2); r.d = iy(3);
  rx(1, 5);
  const near = (lim) => {               // |d - h| < 6
    r.a = sub8(r, r.d, r.h);
    if (r.f & C) r.a = neg(r, r.a);
    cp8(r, r.a, lim);
    return !!(r.f & C);
  };
  const nearX = () => {                  // |l - e| < 3
    r.a = sub8(r, r.l, r.e);
    if (r.f & C) r.a = neg(r, r.a);
    cp8(r, r.a, 3);
    return !!(r.f & C);
  };
  // x step: blocked by the other player when touching on that side
  const blockX = (front, back) => {      // a = front + 1 vs back; then a - 6 vs back
    r.a = inc8(r, front());
    cp8(r, r.a, back());
    if (r.f & C) return false;
    r.a = sub8(r, r.a, 6);
    cp8(r, r.a, back());
    sx(1, 5);
    if (r.f & C) return true;
    rx(1, 5);
    return false;
  };
  const rate = () => { m.call(0x9E47); return !(r.f & Z); };
  if (bit(r, 0, c)) {
    r.a = r.l;
    if (bit(r, 1, c)) {                  // 9CFC: right
      cp8(r, r.a, 0x6E);
      if (r.f & C) {
        if (!(near(6) && blockX(() => r.e, () => r.l))) {
          r.l = inc8(r, r.l);
          if (!rate()) r.l = inc8(r, r.l);
        }
      }
    } else {
      cp8(r, r.a, 0x41);
      if (!(r.f & C)) {
        if (!(near(6) && blockX(() => r.l, () => r.e))) {
          r.l = dec8(r, r.l);
          if (!rate()) r.l = dec8(r, r.l);
        }
      }
    }
  }
  r.a = 0x70; r.c = 0x70;                // 9D23: the court edges for this x
  r.a = sub8(r, r.a, r.l);
  r.a = srl(r, r.a); r.a = srl(r, r.a);
  r.a = inc8(r, r.a);
  r.b = r.a;
  cp8(r, r.a, r.h);
  if (r.f & C) {
    r.a = neg(r, r.a);
    r.a = add8(r, r.a, 0x73);
    r.c = r.a;
    cp8(r, r.a, r.h);
    if (r.f & C) {
      r.a = dec8(r, dec8(r, r.h));
      cp8(r, r.a, r.c);
      if (!(r.f & C) && !(r.f & Z)) wx(-2, 4);
    }
  } else {
    r.a = inc8(r, r.h);
    cp8(r, r.a, r.b);
    if (r.f & C) wx(-2, 0x0C);
  }
  if (bitm(r, 2, ix(-2))) {              // 9D4F: y step
    sx(-7, 0);
    if (bitm(r, 3, ix(-2))) {            // 9D8B: down
      r.a = r.c;
      cp8(r, r.a, r.h);
      if (!(r.f & C)) {
        rx(-7, 0);
        let blocked = false;
        if (nearX()) {
          r.a = r.d;
          cp8(r, r.a, r.h);
          if (!(r.f & C)) {
            r.a = sub8(r, r.a, 8);
            cp8(r, r.a, r.h);
            sx(1, 5);
            if (r.f & C) blocked = true; else rx(1, 5);
          }
        }
        if (!blocked) { r.h = inc8(r, r.h); if (!rate()) r.h = inc8(r, r.h); }
      }
    } else {
      r.a = r.b;
      cp8(r, r.a, r.h);
      if (r.f & C) {
        rx(-7, 0);
        let blocked = false;
        if (nearX()) {
          r.a = r.h;
          cp8(r, r.a, r.d);
          if (!(r.f & C)) {
            r.a = sub8(r, r.a, 8);
            cp8(r, r.a, r.d);
            sx(1, 5);
            if (r.f & C) blocked = true; else rx(1, 5);
          }
        }
        if (!blocked) { r.h = dec8(r, r.h); if (!rate()) r.h = dec8(r, r.h); }
      }
    }
  }
  wx(2, r.l); wx(3, r.h);                // 9DB9
  m.call(0x9ED4);
  return follow(m);
}

function follow(m) {                     // 9DC2
  const r = m.r, { ix, rx, sx } = io(m);
  r.l = ix(2); r.h = ix(3);
  if (!bitm(r, 4, ix(0))) return;
  const c = r.c = ix(-1);
  if (bit(r, 2, c)) {
    if (bit(r, 3, c)) r.h = r.a = add8(r, r.h, 9);
  } else {
    const nz = bit(r, 1, c);
    r.c = 2;
    if (!nz) { r.c = 0xFE; r.h = r.a = add8(r, r.h, 9); }
    r.l = r.a = add8(r, r.l, r.c);
  }
  m.wr(0x93F3, r.l); m.wr(0x93F4, r.h);  // 9DED
  r.a = r.l;
  cp8(r, r.a, 0x41);
  let out = !!(r.f & C);
  if (!out) { cp8(r, r.a, 0x6E); out = !(r.f & C); }
  if (out && bitm(r, 4, ix(0))) { r.e = 3; m.call(0x9919); return; }
  if (!bitm(r, 4, ix(0))) { rx(1, 4); return; }
  const crossed = bitm(r, 4, ix(1));     // 9E10
  r.a = ix(3);
  if (!crossed) {
    if (bitm(r, 0, ix(1))) { cp8(r, r.a, 0x3E); if (r.f & C) return; } else { cp8(r, r.a, 0x38); if (!(r.f & C)) return; }
    sx(1, 4);
    return;
  }
  if (bitm(r, 0, ix(1))) { cp8(r, r.a, 0x3E); if (!(r.f & C)) return; } else { cp8(r, r.a, 0x38); if (r.f & C) return; }
  r.e = 5;
  m.call(0x9919);
  rx(1, 4);
}

function stepRate(m) {                   // 9E47: NZ = no second pixel
  const r = m.r, { ix, wx } = io(m);
  r.a = and8(r, ix(0x0A), ix(0x0A));
  if (!r.a) {
    r.a = and8(r, inc8(r, ix(-5)), 1);
    wx(-5, r.a);
    return;
  }
  if (!bitm(r, 4, ix(0))) return;
  r.a = m.rd(0x93EB);
  if (!bit(r, 6, r.a)) return;
  const n = dec8(r, ix(-6));
  wx(-6, n);
  if (n) return;
  r.a = m.rd(0x93EB) & ~0x40;
  m.wr(0x93EB, r.a);
}

module.exports = { procs: { '9C7C': idle, '9C83': walk, '9DC2': follow, '9E47': stepRate } };
