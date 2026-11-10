'use strict';
/**
 * Player update and draw (ix = player, iy = the other), 95A1..98B2.
 * Sprite frames: 9E6F sets BLIT_SRC from the frame number in A (table 7760),
 * BLIT_Y (3300) holds the screen position, B01C draws (jp 01E9, platform).
 *   95A1  walk animation (step counters ix+6/ix+7), body + head (9652), contact pose 96BC
 *   9652  body/legs frame, the head-in-hand check against 94A7 (blocked shot flag)
 *   9705  player with the ball / dribble: 9753 arm, 9718 ball in hand
 *   978A  shot pose (ix+7 toggles; the second frame releases the ball: 84D9)
 *   97F5  jump / dunk frames, 97D6 the ball goes loose (84DC)
 * Stack: every push and call the Z80 makes before a platform call is repeated
 * (the platform events compare SP).
 */
const { io } = require('./ent');
const { C, Z, add8, sub8, cp8, and8, xor8, inc8, dec8, neg, bit, bitm, add16 } = require('./z80');

const BLIT_Y = 0x3300, BLIT_SRC = 0x3302;

function spriteSrc(m) {                  // 9E6F
  const r = m.r;
  r.a = add8(r, r.a, r.a);
  let hl = add16(r, r.a, 0x7760);
  r.e = m.rd(hl); r.d = m.rd(hl + 1);
  hl = add16(r, 0x415A, r.d << 8 | r.e);
  r.h = hl >> 8; r.l = hl & 0xff;
  m.wr16(BLIT_SRC, hl);
}
function blit(m) {                       // (3300) = hl; 9E6F; jp B01C
  const r = m.r;
  m.wr(BLIT_Y, r.l); m.wr(BLIT_Y + 1, r.h);
  spriteSrc(m);
  return m.jp(0xB01C);
}

function player(m) {                     // 95A1
  const r = m.r, { ix, wx, sx, rx } = io(m);
  if (bitm(r, 5, ix(0))) return jump(m);
  if (bitm(r, 5, ix(-2)) || bitm(r, 7, ix(0))) return shotPose(m);
  if (bitm(r, 6, ix(-2)) || bitm(r, 0, ix(0))) return withBall(m);
  r.e = 1;
  let hl = 0x9442, a;
  r.a = and8(r, ix(-2), 0x1F);
  if (!r.a) {
    a = r.a;
    if (bitm(r, 4, ix(0))) { hl = 0x9446; r.e = dec8(r, r.e); sx(0, 2); a = ix(6); }
  } else {
    a = ix(6);
    const was = bitm(r, 2, ix(0));
    rx(0, 2);
    if (was) { a = dec8(r, a); a |= 1; }
  }
  a = and8(r, inc8(r, a), 3);            // 95F3
  wx(6, a);
  r.b = 0; r.c = a;
  hl = add16(r, hl, r.c);
  r.a = m.rd(hl);
  wx(7, r.a);
  r.c = r.a;
  hl = add16(r, 0x944A, r.c);
  a = m.rd(hl);
  r.l = ix(2); r.h = ix(3);
  r.e = dec8(r, r.e);
  if (r.e) a = 0xDB;
  r.l = r.a = add8(r, a, r.l);
  m.push(r.h << 8 | r.l); m.push(r.ix); m.push(r.iy);
  m.call(0x9652);
  r.iy = m.pop(); r.ix = m.pop();
  let v = m.pop(); r.h = v >> 8; r.l = v & 0xff;
  r.a = 0x0A;
  if (bitm(r, 2, ix(-1))) {
    if (bitm(r, 3, ix(-1))) r.a = add8(r, r.a, 0x0C);
  } else {
    r.a = 0x22;
    if (!bitm(r, 1, ix(-1))) r.a = add8(r, r.a, 0x0C);
  }
  if (bitm(r, 0, ix(1))) r.a = inc8(r, r.a);
  if (bitm(r, 4, ix(0))) contactPose(m);
  return blit(m);
}

function body(m) {                       // 9652
  const r = m.r, { ix, wx } = io(m);
  r.h = ix(3);
  r.l = r.a = sub8(r, ix(2), 0x1C);
  const air = bitm(r, 4, ix(0));
  r.a = ix(7);
  if (air) r.a = add8(r, r.a, 3);
  if (bitm(r, 2, ix(-1))) {
    if (bitm(r, 3, ix(-1))) r.a = add8(r, r.a, 0x0C);
  } else {
    r.a = add8(r, r.a, 0x18);
    if (!bitm(r, 1, ix(-1))) r.a = add8(r, r.a, 0x0C);
  }
  m.wr(BLIT_Y, r.l); m.wr(BLIT_Y + 1, r.h);
  m.push(r.ix); m.push(r.a << 8 | r.f);
  m.call(0x9E6F);
  m.call(0xB01C);
  const af = m.pop(); r.d = af >> 8; r.e = af & 0xff;
  r.ix = m.pop();
  let hl = 0x94A7;                       // frames that put the head into the hand
  for (;;) {
    r.a = m.rd(hl); hl++;
    r.a = and8(r, r.a, r.a);
    if (!r.a) { r.h = hl >> 8; r.l = hl & 0xff; return; }
    cp8(r, r.a, r.d);
    if (r.a === r.d) break;
  }
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = m.rd(0x93EB) | 0x40; m.wr(0x93EB, r.a);
  wx(-6, 3);
  r.a = and8(r, m.rd(0x93D8), m.rd(0x93D8));
  if (r.a) return;
  r.a = inc8(r, r.a);
  m.wr(0xAA83, r.a);
  m.wr16(BLIT_Y, 2);
  r.h = 0x80; r.l = 0x70;
  m.wr16(BLIT_SRC, 0x8070);
  return m.jp(0xAA80);
}

function contactPose(m) {                // 96BC: A = frame; may change A / L
  const r = m.r, { ix, iy } = io(m);
  if (bitm(r, 2, ix(0))) return;
  r.c = r.a;
  r.a = sub8(r, ix(3), iy(3));
  r.b = 0x0A; r.e = 0;
  if (r.f & C) { r.b = 0x16; r.e = inc8(r, r.e); r.a = neg(r, r.a); }
  cp8(r, r.a, 6);
  if (!(r.f & C)) { r.a = r.c; return; }
  r.a = sub8(r, ix(2), iy(2));
  if (r.f & C) r.a = neg(r, r.a);
  cp8(r, r.a, 0x0A);
  if (!(r.f & C)) { r.a = r.c; return; }
  if (bitm(r, 0, ix(1))) r.b = inc8(r, r.b);
  r.a = r.b;
  cp8(r, r.a, r.c);
  if (r.a === r.c) return;
  if (bitm(r, 2, ix(-1))) return;
  if (!bitm(r, 1, ix(-1))) { r.a = r.c; return; }
  if (!bitm(r, 0, ix(1))) return;
  r.l = dec8(r, r.l);
}

function withBall(m) {                   // 9705
  const r = m.r, { ix } = io(m);
  if (bitm(r, 2, ix(-1)) || bitm(r, 1, ix(-1))) {
    m.push(r.ix); m.call(0x9718); r.ix = m.pop();
    return arm(m);
  }
  m.push(r.ix); m.call(0x9753); r.ix = m.pop();
  return ballInHand(m);
}
function ballInHand(m) {                 // 9718
  const r = m.r, { ix } = io(m);
  r.h = ix(5);
  r.l = r.a = sub8(r, ix(4), 0x25);
  r.a = 0x0A;
  let add;
  if (bitm(r, 2, ix(-1))) add = bitm(r, 3, ix(-1));
  else { r.a = add8(r, r.a, 0x18); add = !bitm(r, 1, ix(-1)); }
  if (add) r.a = add8(r, r.a, 0x0C);
  if (bitm(r, 0, ix(1))) r.a = inc8(r, r.a);
  return blit(m);
}
function arm(m) {                        // 9753
  const r = m.r, { ix } = io(m);
  r.h = ix(5);
  r.l = r.a = sub8(r, ix(4), 0x24);
  const air = bitm(r, 4, ix(0));
  r.a = 9;
  if (air) r.a = dec8(r, r.a);
  if (bitm(r, 2, ix(-1))) {
    if (bitm(r, 3, ix(-1))) { r.a = add8(r, r.a, 0x0C); r.h = inc8(r, r.h); }
  } else {
    r.a = add8(r, r.a, 0x24);
    if (bitm(r, 1, ix(-1))) r.a = sub8(r, r.a, 0x0C);
  }
  return blit(m);
}

function shotPose(m) {                   // 978A
  const r = m.r, { ix, wx } = io(m);
  r.h = ix(5);
  r.l = r.a = sub8(r, ix(4), 0x24);
  if (bitm(r, 0, ix(1))) { r.h = dec8(r, r.h); r.h = dec8(r, r.h); }
  m.wr(BLIT_Y, r.l); m.wr(BLIT_Y + 1, r.h);
  r.a = add8(r, ix(7), 0x36);
  if (!bitm(r, 1, ix(-1))) { r.a = inc8(r, r.a); r.a = inc8(r, r.a); }
  if (bitm(r, 0, ix(1))) r.a = add8(r, r.a, 4);
  spriteSrc(m);
  m.push(r.ix); m.call(0xB01C); r.ix = m.pop();
  r.a = and8(r, inc8(r, ix(7)), 1);
  if (!r.a) return;
  wx(7, r.a);
  return m.jp(0x84D9);
}

function looseCheck(m) {                 // 97CB: A = sprite y
  const r = m.r;
  cp8(r, r.a, 0x22);
  if (r.f & C) m.call(0x97D6);
  return withBall(m);
}
function loose(m) {                      // 97D6
  const r = m.r, { ix, wx } = io(m);
  r.a = xor8(r, r.a, r.a);
  if (bitm(r, 0, ix(1))) r.a |= 0x80;
  m.wr(0x93EB, r.a);
  r.a = and8(r, m.rd(0x9400), m.rd(0x9400));
  const nz = r.a;
  r.a = 0;
  if (!nz) { wx(0x0C, inc8(r, ix(0x0C))); r.a = 2; }
  m.wr(0x93D9, r.a);
  return m.jp(0x84DC);
}

function jump(m) {                       // 97F5
  const r = m.r, { ix, sx, rx } = io(m);
  r.a = ix(4);
  r.h = dec8(r, ix(5));
  r.l = r.a = sub8(r, r.a, 0x24);
  m.wr(BLIT_Y, r.l); m.wr(BLIT_Y + 1, r.h);
  r.c = 2;
  if (!bitm(r, 6, ix(0))) r.c = dec8(r, r.c);
  if (!bitm(r, 1, ix(0))) {
    r.c = dec8(r, r.c);
    bit(r, 2, m.rd(0x93EB));
    const dunk = !(r.f & Z);
    r.a = r.l;
    if (dunk) {                          // 9829: the dunk scores
      sx(0, 1); sx(1, 3); rx(0, 4); rx(0, 3);
      r.h = 0x08; r.l = 0x4C;
      if (bitm(r, 0, ix(1))) r.h = 0x74;
      m.wr(0x93F3, r.l); m.wr(0x93F4, r.h);
      r.l = 0x21;
      m.wr(0x93F1, r.l); m.wr(0x93F2, r.h);
      r.c = inc8(r, r.c);
      m.push(r.b << 8 | r.c);
      const y = m.rd16(BLIT_Y);
      r.h = y >> 8; r.l = y & 0xff;
      m.push(y);
      r.a = xor8(r, r.a, r.a);
      m.wr(0xAA83, 0);
      m.wr16(BLIT_Y, 2);
      r.h = 0x80; r.l = 0x39;
      m.wr16(BLIT_SRC, 0x8039);
      m.call(0xAA80);
      const hl = m.pop(); r.h = hl >> 8; r.l = hl & 0xff;
      m.wr16(BLIT_Y, hl);
      const bc = m.pop(); r.b = bc >> 8; r.c = bc & 0xff;
    } else {
      if (bitm(r, 6, ix(0))) return looseCheck(m);
      cp8(r, r.a, 0x22);
      if (!(r.f & C)) return withBall(m);
      sx(1, 3);                          // 986C
      cp8(r, r.a, 0x1D);
      if (r.f & C) m.call(0x97D6);
    }
  }
  r.a = add8(r, 0x30, r.c);              // 9875
  r.c = 1;
  let tail = false;
  if (!bitm(r, 2, ix(-1))) {
    r.h = 0x33; r.l = 0x01;
    if (bitm(r, 0, ix(1))) {
      if (!bitm(r, 1, ix(-1))) { r.a = add8(r, r.a, 2); m.wr(0x3301, inc8(r, m.rd(0x3301))); }
      r.c = dec8(r, r.c);
      r.a = add8(r, r.a, 8);
    } else {
      m.wr(0x3301, inc8(r, m.rd(0x3301)));
      r.a = add8(r, r.a, 6);
      if (!bitm(r, 1, ix(-1))) { r.a = add8(r, r.a, 2); tail = true; }
    }
  }
  if (!tail && bitm(r, 0, ix(1))) { r.a = add8(r, r.a, 2); r.a = add8(r, r.a, r.c); }
  spriteSrc(m);
  return m.jp(0xB01C);
}

module.exports = {
  procs: {
    '9E6F': spriteSrc, '95A1': player, '9652': body, '96BC': contactPose, '9705': withBall,
    '9718': ballInHand, '9753': arm, '978A': shotPose, '97CB': looseCheck, '97D6': loose, '97F5': jump,
  },
};
