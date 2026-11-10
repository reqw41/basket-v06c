'use strict';
/**
 * The game's main program, 84D0..8695.
 *   84D0 / 84E8  cold start: controls screen (A0A1), start-up (35C0, with the
 *                screen clear 3732 switched off), then 8515
 *   8508  back to the menu: tune 7EAF; 8515 menu (A095), match tune 7F49,
 *         speed (AC4F -> the CP at 8679), new match 92A7
 *   8554  the frame (the golden mark M): seed, crowd, ball, input, both players,
 *         ring, objects, clock, flush (01EF), pause key (8676), quit keys (8685);
 *         then the event handling: banner and tune for a score / foul / out,
 *         replay (852C), restarts (8538 / 8631), end of half / match (8657)
 */
const { C, Z, cp8, and8, xor8, inc8, dec8 } = require('./z80');

function coldStart(m) {                  // 84E8
  const r = m.r;
  m.call(0xA53A);
  r.a = 0xC9; m.wr(0x3732, 0xC9);
  m.call(0x35C0);
  r.a = 0xCD; m.wr(0x3732, 0xCD);
  r.h = 0x7E; r.l = 0xAF; m.wr16(0x3300, 0x7EAF);
  r.a = xor8(r, r.a, r.a);
  m.wr(0xAA82, 0);
  return program(m, 0x8515);
}
function toMenu(m) { return program(m, 0x8508); }       // 8508
function menuMatch(m) { return program(m, 0x8515); }    // 8515

function program(m, at) {
  const r = m.r;
  for (;;) {
    switch (at) {
      case 0x8508:
        r.h = 0x7E; r.l = 0xAF; m.wr16(0x3300, 0x7EAF);
        r.a = xor8(r, r.a, r.a);
        m.wr(0xAA82, 0);
        m.call(0xAA7C);
        // fall through
      case 0x8515:
        m.call(0xA5FD);
        r.h = 0x7F; r.l = 0x49; m.wr16(0x3300, 0x7F49);
        m.call(0xAA7C);
        r.a = m.rd(0xAC4F); m.wr(0x867A, r.a);
        m.call(0x92A7);
        at = 0x8547; break;
      case 0x852C:                       // replay, then the half goes on
        r.a = xor8(r, r.a, r.a);
        m.wr(0x93D8, 0);
        m.call(0xA82C);
        m.call(0x92AA);
        at = 0x8547; break;
      case 0x8538:                       // restart after an event
        m.call(0x91B5);
        m.pcall(0x01F2);
        m.call(0x94B0);
        m.call(0xA00E);
        m.call(0xA0BF);
        // fall through
      case 0x8547:
        r.a = and8(r, m.rd(0x93D6), m.rd(0x93D6));
        if (!r.a) m.call(0x9F60);
        m.call(0xA95E);
        m.call(0x869C);
        at = 0x8554; break;
      case 0x8554:
        at = frame(m); break;
      case 0x8657:                       // end of the half / the match
        r.a = xor8(r, r.a, r.a);
        m.wr(0x93D8, 0);
        m.call(0xA1AA);
        m.call(0x9295);
        r.a = dec8(r, m.rd(0x93D7));
        m.wr(0x93D7, r.a);
        if (!r.a) { at = 0x8508; break; }
        r.a = 0x16; m.wr(0x9415, 0x16); m.wr(0x942F, 0x16);
        at = 0x8538; break;
      default: throw new Error('main: bad label ' + at.toString(16));
    }
  }
}

function frame(m) {                      // 8554: one frame; returns where the program goes
  const r = m.r;
  m.mark(0x8554);
  m.call(0xA193);
  m.call(0xA502);
  m.call(0x8A23);
  r.a = m.rd(0x93EB) & ~0x20; m.wr(0x93EB, r.a);
  m.call(0x9543);
  r.ix = 0x940B; r.iy = 0x9425;
  m.call(0x9C83);
  r.ix = 0x9425; r.iy = 0x940B;
  m.call(0x9C83);
  m.call(0xA969);
  m.call(0x94B0);
  m.call(0x9F9A);
  m.pcall(0x01EF);
  m.call(0x8676);
  m.call(0x8685);
  if (r.f & Z) return 0x8508;
  r.a = and8(r, m.rd(0x93E5), m.rd(0x93E5));
  if (r.a) return 0x8657;
  r.a = and8(r, m.rd(0x9400), m.rd(0x9400));
  if (!r.a) return 0x8554;
  m.call(0x9F67);
  r.a = and8(r, m.rd(0x9451), m.rd(0x9451));
  if (r.a) {                             // the event banner countdown
    r.a = dec8(r, r.a);
    m.wr(0x9451, r.a);
    cp8(r, r.a, 0x13);
    if (r.a !== 0x13) return 0x8554;
    r.a = 0x91; m.wr(0x3424, 0x91);
    r.h = 0x01; r.l = 0x14;
    r.a = m.rd(0x9400);
    m.wr(0x3314, r.a);
    r.b = r.a;
    r.a = and8(r, r.a, 0x80);
    if (!r.a) r.h = 0x14;
    m.wr(0x4102, r.l); m.wr(0x4103, r.h);
    let hl = 0x946A;                     // the B-th message
    r.a = and8(r, r.b, 0x3F);
    r.b = r.a;
    for (;;) {
      do { r.a = inc8(r, m.rd(hl)); hl++; } while (r.a);
      r.b = (r.b - 1) & 0xff;
      if (!r.b) break;
    }
    r.h = r.d; r.l = r.e; r.d = hl >> 8; r.e = hl & 0xff;   // ex de,hl
    m.call(0xA022);
    r.a = and8(r, m.rd(0x9400), 7);
    r.e = 6;
    cp8(r, r.a, 4);
    if (r.a !== 4) {
      r.e = dec8(r, r.e);
      r.a = xor8(r, r.a, r.a);
      m.wr(0x93D3, 0);
    }
    r.a = r.e;
    m.wr(0xAA83, r.a);
    m.wr16(0x3300, 2);
    r.h = 0x80; r.l = 0x7D;
    cp8(r, r.a, 5);
    if (r.a !== 5) { r.a = 1; m.wr(0x93D8, 1); r.h = 0x7F; r.l = 0xBA; }
    m.wr(0x3302, r.l); m.wr(0x3303, r.h);
    m.call(0xAA80);
    return 0x8554;
  }
  r.a = and8(r, m.rd(0x93D3), m.rd(0x93D3));   // 860F
  if (r.a) return 0x852C;
  r.a = m.rd(0x93D6);
  r.e = r.a;
  r.a = and8(r, r.a, 7);
  if (!r.a) return 0x8538;
  r.e = dec8(r, r.e);
  r.a = r.e;
  m.wr(0x93D6, r.a);
  r.a = and8(r, r.a, 7);
  if (r.a) {
    r.a = and8(r, m.rd(0x9400), 7);
    cp8(r, r.a, 4);
    if (r.a === 4) {                     // the next throw-in of a series
      m.call(0x9211);
      m.call(0xA00E);
      return 0x8554;
    }
    r.a = xor8(r, r.a, r.a);
    m.wr(0x93D6, 0);
  }
  r.a = m.rd(0x9416);                    // 863E: five fouls end the match
  cp8(r, r.a, 5);
  if (r.a !== 5) {
    r.a = m.rd(0x9430);
    cp8(r, r.a, 5);
    if (r.a !== 5) return 0x8538;
  }
  r.a = 1; m.wr(0x93D7, 1);
  r.a = 0xFF; m.wr(0x93E5, 0xFF);
  return 0x8657;
}

function pause(m) {                      // 8676
  const r = m.r;
  r.a = m.rd(0x410F);
  cp8(r, r.a, m.rd(0x867A));
  if (r.a !== m.rd(0x867A)) return;
  m.call(0x9F67);
  m.call(0x3A2F);
  return m.jp(0x064D);
}
function quitKeys(m) {                   // 8685
  const r = m.r;
  r.a = 0x30;
  m.pcall(0x0660);
  if (!(r.f & Z)) return;
  r.a = 0x31;
  m.pcall(0x0669);
  if (!(r.f & Z)) return;
  r.a = 0x3A;
  return m.jp(0x0669);
}

module.exports = {
  procs: { '84D0': coldStart, '84E8': coldStart, '8508': toMenu, '8515': menuMatch, '8676': pause, '8685': quitKeys },
};
