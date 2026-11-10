'use strict';
/**
 * Match / restart setup and the per-frame object scheduler.
 *   91B5  restart positions after an event (9400) or the tip-off; 9211 the throw-in
 *         side by E bit 7 (also called from the main loop 8631)
 *   8B26  ball hold point from 93F1: 93F0 = (93F1)+6, 93EF = 0
 *   9273  match reset (93EB..9439 cleared, fouls/timers), 9295 clock reload
 *   92A7  new match: 9273 then 92AA (half start: screen, score, clock, players)
 *   94B0  scheduler: list at 3C1E of (y, routine) for the ball, its shadow and the
 *         two players, bubble-sorted by y (largest first), then called in order
 *   9543  joystick / AI input into 9409 / 9423 (AC4A reads the controls)
 *   9599 / 958F  player 1 / 2 update: ix = self, iy = the other, then 95A1
 */
const { add8, and8, cp8, xor8, inc8, bit, ldir } = require('./z80');

const BALL_STATE = 0x93EB, RESTART = 0x93D6, EVENT = 0x9400, LIST = 0x3C1E;

function restart(m) {                    // 91B5
  const r = m.r;
  r.a = xor8(r, r.a, r.a);
  m.wr(RESTART, 0); m.wr(0x93F5, 0); m.wr(0x9426, 0);
  r.a = inc8(r, r.a);
  m.wr(0x940C, 1);
  m.wr16(0x9409, 0x0C00);
  m.wr16(0x9423, 0x0400);
  r.a = and8(r, m.rd(EVENT), m.rd(EVENT));
  if (!r.a) {                            // tip-off
    m.wr16(0x940D, 0x1054);
    m.wr16(0x9427, 0x6454);
    m.wr16(0x93F3, 0x3E54);
    m.wr16(0x93F1, 0x3E26);
    holdPoint(m);
    r.a = 0x10; m.wr(BALL_STATE, 0x10);
    r.a = xor8(r, r.a, r.a);
    m.wr(0x940B, 0); m.wr(0x9425, 0); m.wr(0x9426, 0);
    return done(m);
  }
  r.e = r.a;                             // 91FE
  r.a = and8(r, r.a, 7);
  cp8(r, r.a, 2);
  if (r.a !== 2) {                       // 9229
    if (bit(r, 7, r.e)) { m.wr16(0x940D, 0x3654); r.h = 0x64; r.l = 0x54; return side2(m); }
    m.wr16(0x940D, 0x1054); r.h = 0x3E; r.l = 0x54;
    return side1(m);
  }
  r.a = r.e;
  m.wr(RESTART, r.a);
  r.a = 0x16; m.wr(0x9415, 0x16); m.wr(0x942F, 0x16);
  return throwIn(m);
}
function throwIn(m) {                    // 9211
  const r = m.r;
  if (bit(r, 7, r.e)) { m.wr16(0x940D, 0xC854); r.h = 0x18; r.l = 0x54; return side2(m); }
  m.wr16(0x940D, 0x5C54); r.h = 0xC8; r.l = 0x54;
  return side1(m);
}
function side2(m) {                      // 9235: player 2 restarts with the ball
  const r = m.r;
  m.wr(0x9427, r.l); m.wr(0x9428, r.h);
  r.ix = 0x9425;
  r.a = 0x10; m.wr(0x9425, 0x10);
  r.a = xor8(r, r.a, r.a); m.wr(0x940B, 0);
  r.a = 1;
  return restartBall(m);
}
function side1(m) {                      // 9251
  const r = m.r;
  m.wr(0x9427, r.l); m.wr(0x9428, r.h);
  r.ix = 0x940B;
  r.a = 0x10; m.wr(0x940B, 0x10);
  r.a = xor8(r, r.a, r.a); m.wr(0x9425, 0);
  r.a = 0x81;
  return restartBall(m);
}
function restartBall(m) {                // 9263
  m.wr(BALL_STATE, m.r.a);
  m.call(0x93BE);
  return done(m);
}
function done(m) {                       // 9269
  const r = m.r;
  r.a = xor8(r, r.a, r.a);
  m.wr(EVENT, 0); m.wr(0x93D8, 0);
  return m.jp(0x939D);
}

function holdPoint(m) {                  // 8B26
  const r = m.r;
  r.a = add8(r, m.rd(0x93F1), 6);
  m.wr(0x93F0, r.a);
  m.wr(0x93EF, 0);
  r.h = 0x93; r.l = 0xEF;
}

function matchReset(m) {                 // 9273
  const r = m.r;
  r.h = 0x93; r.l = 0xEB; r.d = 0x93; r.e = 0xEC;
  m.wr(0x93EB, 0);
  r.b = 0; r.c = 0x4E;
  ldir(m);
  r.a = 2; m.wr(0x93D7, 2);
  r.a = 0x16; m.wr(0x9415, 0x16); m.wr(0x942F, 0x16);
  r.a = 0x19; m.wr(0x9408, 0x19); m.wr(0x9422, 0x19);
  return clockReload(m);
}
function clockReload(m) {                // 9295
  const r = m.r;
  r.h = 0x93; r.l = 0xE0; r.d = 0x93; r.e = 0xE5; r.b = 0; r.c = 5;
  ldir(m);
  r.a = xor8(r, r.a, r.a);
  m.wr(EVENT, 0);
  return m.jp(0x937F);
}

function newMatch(m) {                   // 92A7
  m.call(0x9273);
  return halfStart(m);
}
function halfStart(m) {                  // 92AA
  const r = m.r;
  r.a = 0x11; m.wr(0x3424, 0x11);
  m.call(0x3732);
  m.call(0x91B5);
  r.l = 0x01; r.l = 0x14;                // 932A is an empty stub
  m.call(0x939D);
  r.a = 0xF1; m.wr(0x3424, 0xF1);
  r.h = 0x0E; r.l = 0x11; r.d = 0x93; r.e = 0x48;
  m.call(0x9397);
  m.call(0x9379);
  m.call(0x93A9);
  m.call(0x93AC);
  m.call(0x93A6);
  m.pcall(0x01F2);
  m.call(0x9385);
  m.pcall(0x01EF);
}

function schedule(m) {                   // 94B0
  const r = m.r;
  let hl = LIST;
  const put = (a, de) => { m.wr(hl, a); m.wr(hl + 1, de & 0xff); m.wr(hl + 2, de >> 8); hl += 3; };
  r.a = 0x53; put(0x53, 0x84D3);
  r.a = m.rd(BALL_STATE);
  if (!bit(r, 0, r.a) && !bit(r, 2, r.a)) { r.a = m.rd(0x93F3); put(r.a, 0x84D6); }
  r.a = m.rd(0x940D); put(r.a, 0x9599);
  r.a = m.rd(0x9427); put(r.a, 0x958F);
  r.d = 0x95; r.e = 0x8F;
  m.wr(hl, 0);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.b = 1;
  do {                                   // 94E5: bubble passes
    let ix = LIST;
    for (;;) {
      let a = r.a = and8(r, m.rd(ix), m.rd(ix));
      if (!a) break;
      cp8(r, a, m.rd(ix + 3));
      if (a > m.rd(ix + 3)) {
        r.c = a;
        r.a = and8(r, m.rd(ix + 3), m.rd(ix + 3));
        if (!r.a) break;
        m.wr(ix + 3, r.c); m.wr(ix, r.a);
        r.l = m.rd(ix + 4); r.h = m.rd(ix + 5);
        r.e = m.rd(ix + 1); r.d = m.rd(ix + 2);
        m.wr(ix + 1, r.l); m.wr(ix + 2, r.h); m.wr(ix + 4, r.e); m.wr(ix + 5, r.d);
        r.b = inc8(r, r.b);
      }
      ix += 3;
    }
    r.ix = ix;
    r.b = (r.b - 1) & 0xff;
  } while (r.b);
  hl = LIST;                             // 9527: call the routines in order
  for (;;) {
    r.a = and8(r, m.rd(hl), m.rd(hl));
    if (!r.a) { r.h = hl >> 8; r.l = hl & 0xff; return; }
    const fn = m.rd16(hl + 1);
    hl += 3;
    r.d = hl >> 8; r.e = hl & 0xff; r.h = fn >> 8; r.l = fn & 0xff;
    m.push(hl);
    m.call(fn);
    hl = m.pop();
  }
}
function put3(m) {                       // 953C: (hl) = a, e, d; hl += 3
  const r = m.r;
  let hl = r.h << 8 | r.l;
  m.wr(hl, r.a); m.wr(hl + 1, r.e); m.wr(hl + 2, r.d);
  hl += 3; r.h = hl >> 8 & 0xff; r.l = hl & 0xff;
}

function input(m) {                      // 9543
  const r = m.r;
  m.call(0xAC4A);
  const merge = (cell, src) => {
    r.c = m.rd(cell);
    r.a = m.rd(src);
    if (bit(r, 4, r.a)) {
      const c7 = bit(r, 7, r.c);
      r.a |= 0x80;
      if (c7) r.a &= ~0x10;
    }
    m.wr(cell, r.a);
  };
  merge(0x9409, 0xAC4D);
  r.a = and8(r, m.rd(0x93EA), m.rd(0x93EA));
  if (r.a) m.call(0x84DF);
  merge(0x9423, 0xAC4E);
  r.a = and8(r, m.rd(RESTART), m.rd(RESTART));
  if (!r.a) return;
  r.a = and8(r, m.rd(0x9409), 0xF0); m.wr(0x9409, r.a);
  r.a = and8(r, m.rd(0x9423), 0xF0); m.wr(0x9423, r.a);
}

function player1(m) { m.r.ix = 0x940B; m.r.iy = 0x9425; return m.jp(0x95A1); }   // 9599
function player2(m) { m.r.ix = 0x9425; m.r.iy = 0x940B; return m.jp(0x95A1); }   // 958F

module.exports = {
  procs: {
    '91B5': restart, '9211': throwIn, '8B26': holdPoint, '9273': matchReset, '9295': clockReload,
    '92A7': newMatch, '92AA': halfStart, '94B0': schedule, '953C': put3, '9543': input,
    '9599': player1, '958F': player2,
  },
};
