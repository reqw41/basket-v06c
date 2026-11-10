'use strict';
/**
 * Player actions with the ball (ix = player, iy = opponent), 8E5A..91B4.
 *   8E5A  action start (jump table 84E5): take the ball / jump / shot setup,
 *         falls into 8F76
 *   8E73  take the ball (also from 903E)
 *   8F76  action step (jump table 84E2): flight, landing (9179)
 *   9009  after the step: what next for a landed / grounded player
 *   9041  shot release decision, 90EF the release (ball state 93EB = 02, flight setup)
 * Tails go to the vector table 93xx through m.jp (the Z80 code or the model).
 */
const { io } = require('./ent');
const { C, Z, add8, sub8, cp8, and8, xor8, inc8, dec8, neg, srl, rrc, bit, bitm, add16 } = require('./z80');

const BALL_STATE = 0x93EB, BALL_HOLD = 0x93F1, BALL_POS = 0x93F3, BALL_F5 = 0x93F5;
const REF_STATE = 0x93D3, RESTART = 0x93D6, EVENT = 0x9400;

function actionStart(m) {                // 8E5A
  const r = m.r, { ix, iy, wx, sx, rx } = io(m);
  rx(-2, 4);
  if (bitm(r, 4, ix(0))) {               // 8F0F: airborne
    sx(0, 3);
    r.l = ix(2); r.h = ix(3);
    let a = r.a = r.l, to = 0x8F51;
    cp8(r, a, 0x50);
    if (!(r.f & C)) {
      cp8(r, a, 0x5B);
      if (r.f & C) {
        a = r.a = r.h;
        let ok;
        if (bitm(r, 0, ix(1))) { cp8(r, a, 0x68); ok = !(r.f & C); } else { cp8(r, a, 0x0D); ok = !!(r.f & C); }
        if (ok) to = 0x8F33;
      }
    }
    if (to === 0x8F33) {
      r.a = ix(0x0A);
      cp8(r, r.a, 3);
      if (r.f & C) to = 0x8F59;
      else {
        sx(0, 5); rx(0, 3);
        r.b = 9;
        r.a = and8(r, m.rd(EVENT), m.rd(EVENT));
        if (!r.a) { r.a = 2; m.wr(REF_STATE, 2); }
        to = 0x8F5F;
      }
    }
    if (to === 0x8F51) {
      r.a = ix(0x0A); r.b = 4;
      and8(r, r.a, r.a);
      to = r.a ? 0x8F5F : 0x8F59;
    }
    if (to === 0x8F59) { r.b = 2; sx(1, 7); }
    wx(8, r.b);                          // 8F5F
    sx(0, 0);
    wx(-4, 0);
    r.l = ix(2); r.h = ix(3);
    wx(4, r.l); wx(5, r.h);
    return actionStep(m);
  }
  if (!bitm(r, 6, ix(1)) || bitm(r, 3, ix(1))) {   // 8F00
    if (bitm(r, 4, iy(0)) && bitm(r, 5, ix(1))) return m.jp(0x93B8);
    return actionStart8F51(m);
  }
  return takeBall(m);
}
function actionStart8F51(m) {            // 8F51 (grounded)
  const r = m.r, { ix, wx, sx } = io(m);
  r.a = ix(0x0A); r.b = 4;
  and8(r, r.a, r.a);
  if (!r.a) { r.b = 2; sx(1, 7); }
  wx(8, r.b);
  sx(0, 0);
  wx(-4, 0);
  r.l = ix(2); r.h = ix(3);
  wx(4, r.l); wx(5, r.h);
  return actionStep(m);
}

function takeBall(m) {                   // 8E73
  const r = m.r, { ix, wx, wy, sx, rx, ry } = io(m);
  r.a = m.rd(BALL_STATE);
  if (bit(r, 3, r.a)) wx(0x10, inc8(r, ix(0x10)));
  r.c = m.rd(BALL_STATE);
  r.a = 0x21;
  if (bitm(r, 0, ix(1))) r.a |= 0x80;
  m.wr(BALL_STATE, r.a);
  r.a = xor8(r, r.a, r.a);
  m.wr(BALL_F5, 0);
  ry(0, 2); rx(-2, 4); ry(1, 6); sx(0, 4); ry(0, 4); ry(1, 4); ry(0, 3); ry(0, 7); ry(-2, 5); ry(1, 1); ry(1, 2);
  wx(6, 3);
  if (!bit(r, 0, r.c) && !bitm(r, 0, ix(0))) {
    r.c = m.rd(BALL_HOLD);
    r.a = sub8(r, m.rd(BALL_POS), r.c);
    cp8(r, r.a, 0x14);
    if (!(r.f & C)) {
      sx(-2, 6);
      r.l = dec8(r, dec8(r, ix(2)));
      r.h = ix(3);
      wx(4, r.l); wx(5, r.h);
    }
  }
  const was = bitm(r, 5, m.rd((r.iy) & 0xffff));    // 8EEA
  ry(0, 5);
  if (was) {
    wy(8, 4);
    r.a = xor8(r, r.a, r.a);
    m.wr(REF_STATE, 0);
  }
  return m.jp(0x93BE);
}

function actionStep(m) {                 // 8F76
  const r = m.r, { ix, wx, sx, rx } = io(m);
  wx(-4, inc8(r, ix(-4)));
  m.call(0x938E);
  if (bitm(r, 1, ix(0))) return landing(m);
  m.call(0x93A3);
  m.call(0x93A3);
  if (bitm(r, 5, ix(0))) {
    if (bitm(r, 2, ix(-1))) {
      rx(0, 6);
      r.e = 8;
      if (!bitm(r, 0, ix(1))) r.e = 0;
      r.a = xor8(r, and8(r, ix(-1), 8), r.e);
      if (r.a) sx(0, 6);
    }
    r.b = 0; r.c = 0;                    // 8FAF
    let a = r.a = ix(2);
    cp8(r, a, 0x54);
    if (!(r.f & Z)) {
      r.c = 2;
      if (!(r.f & C)) r.c = 0xFE;
      r.a = add8(r, a, r.c);
      wx(2, r.a);
    }
    r.e = 9;                             // 8FC3
    if (bitm(r, 0, ix(1))) r.e = 0x6B;
    a = r.a = ix(3);
    cp8(r, a, r.e);
    if (!(r.f & Z)) {
      if (!(r.f & C)) { r.a = dec8(r, a); r.b = 0xFF; } else { r.a = inc8(r, a); r.b = 1; }
    }
    wx(3, r.a); wx(5, r.a);
    m.call(0x938B);
  }
  r.a = sub8(r, ix(4), 4);               // 8FE6
  wx(4, r.a);
  const n = dec8(r, ix(8));
  wx(8, n);
  if (n) return afterStep(m);
  sx(0, 1);
  if (!bitm(r, 4, ix(0))) return afterStep(m);
  if (!bitm(r, 7, ix(1))) return afterStep(m);
  sx(-2, 4);
  return release(m);
}

function afterStep(m) {                  // 9009
  const r = m.r, { ix, sx } = io(m);
  if (bitm(r, 5, ix(0))) return;
  if (bitm(r, 7, ix(0))) { sx(-2, 5); return; }
  if (bitm(r, 4, ix(0))) return release(m);
  if (bitm(r, 3, ix(1))) return;
  r.a = m.rd(BALL_STATE);
  if (bit(r, 1, r.a)) {
    r.c = rrc(r, ix(1));
    r.a = and8(r, xor8(r, r.a, r.c), 0x80);
    if (!r.a) return;
  }
  if (!bitm(r, 6, ix(1))) return;        // 9034
  if (bitm(r, 3, ix(1))) return;
  return takeBall(m);
}

function release(m) {                    // 9041
  const r = m.r, { ix, wx, sx } = io(m);
  let to;
  if (bitm(r, 1, ix(1))) to = 0x90B7;
  else if (bitm(r, 2, ix(1))) to = 0x907E;
  else {
    if (!bitm(r, 4, ix(-2))) return;
    const a = r.a = ix(3);
    let low;
    if (bitm(r, 0, ix(1))) { cp8(r, a, 0x60); low = !(r.f & C); } else { cp8(r, a, 0x14); low = !!(r.f & C); }
    if (low) { sx(1, 1); to = 0x90B7; } else if (bitm(r, 2, ix(-1))) { sx(1, 2); to = 0x907E; } else {
      sx(0, 7); sx(-2, 5);
      r.a = xor8(r, r.a, r.a);
      wx(7, 0);
      return m.jp(0x93BE);
    }
  }
  let pose;
  if (to === 0x907E) {
    const c = r.c = ix(-1);
    if (bitm(r, 0, ix(1))) {             // 90A4
      if (!bit(r, 2, c)) pose = 0x0C;
      else if (bit(r, 3, c)) return shoot(m);
      else pose = 0x01;
    } else if (!bit(r, 2, c)) pose = 0x04;
    else if (!bit(r, 3, c)) return shoot(m);
    else pose = 0x03;
  } else {                               // 90B7
    const c = r.c = ix(-1);
    r.a = ix(2);
    cp8(r, r.a, 0x55);
    let at;
    if (!(r.f & C)) {                    // 90E7
      if (!bit(r, 0, c)) at = 0x90E0;
      else if (bit(r, 1, c)) at = 0x90C9;
      else return shoot(m);
    } else if (!bit(r, 0, c)) at = 0x90D9;
    else if (bit(r, 1, c)) return shoot(m);
    else at = 0x90C9;
    if (at === 0x90C9) {
      r.a = 4;
      if (bitm(r, 0, ix(1))) r.a = 0x0C;
      pose = r.a;
    } else pose = at === 0x90D9 ? 0x03 : 0x01;
  }
  wx(-1, pose);
  return m.jp(0x93BE);
}

function shoot(m) {                      // 90EF
  const r = m.r, { ix, rx, sx } = io(m);
  r.a = 2;
  if (bitm(r, 0, ix(1))) r.a |= 0x80;
  m.wr(BALL_STATE, r.a);
  rx(0, 4); rx(0, 3); rx(0, 2);
  m.call(0x9391);
  r.a = ix(-3); m.wr(0x944D, r.a);
  r.a = ix(0x0A); m.wr(0x944E, r.a);
  r.d = 0;
  r.e = dec8(r, ix(-4));
  const hl = add16(r, 0x943A, r.e);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = m.rd(hl); m.wr(0x9450, r.a);
  let a = sub8(r, ix(2), 0x58);
  if (r.f & C) a = neg(r, a);
  r.c = a;
  a = ix(3);
  if (bitm(r, 0, ix(1))) { a = neg(r, a); a = add8(r, a, 0x74); }
  r.a = srl(r, add8(r, a, r.c));
  m.wr(0x944F, r.a);
  r.h = ix(5);
  r.l = r.a = sub8(r, ix(4), 0x1A);
  let twice;
  if (bitm(r, 0, ix(1))) {
    r.h = inc8(r, r.h);
    if (!bitm(r, 0, ix(-1))) { r.h = r.a = add8(r, r.h, 8); twice = false; } else twice = true;
  } else {
    r.h = dec8(r, r.h);
    twice = bitm(r, 0, ix(-1));
  }
  if (twice) { r.h = inc8(r, r.h); r.h = inc8(r, r.h); }
  m.wr(BALL_HOLD, r.l); m.wr(BALL_HOLD + 1, r.h);
  r.l = ix(2);
  m.wr(BALL_POS, r.l); m.wr(BALL_POS + 1, r.h);
  sx(-2, 6); sx(1, 4);
}

function landing(m) {                    // 9179
  const r = m.r, { ix, wx, rx } = io(m);
  r.l = ix(4); r.h = ix(5);
  m.call(0x9009);
  r.a = add8(r, ix(4), 4);
  wx(4, r.a);
  cp8(r, r.a, ix(2));
  if (r.f & C) return;
  r.a = and8(r, ix(0), 0x18); wx(0, r.a);
  r.a = and8(r, ix(1), 0x71); wx(1, r.a);
  wx(6, 0);
  const was = bitm(r, 3, ix(0));
  rx(0, 3);
  if (!was) return;
  r.a = and8(r, m.rd(RESTART), m.rd(RESTART));
  if (r.a) return;
  r.e = 1;
  return m.jp(0x93B2);
}

module.exports = {
  procs: { '8E5A': actionStart, '8E73': takeBall, '8F76': actionStep, '9009': afterStep, '9041': release, '90EF': shoot },
};
