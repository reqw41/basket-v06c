'use strict';
/**
 * Ball per frame, shot result, baskets, 8A23..8CF6.
 * Ball state 93EB: bit 0 loose, 1 in flight, 2 in the basket, 3 rebound,
 * 4 bounce (dribble), 5 contact this frame, 6 blocked, 7 side.
 *   8A23  ball step by state (bounce 93EF..93F3, flight 9A1B, rebound 9BF6), then
 *         the contact icons of both players (8AAE: HUD_ICON B455 by 8CF7)
 *   8ADD  ball + shadow draw; at the end of a flight (93F5 bit 1): rebound or
 *         the shot result: chance from 944D..9450 and a random factor (A0B0),
 *         stats ix+0C..12, made -> 8C16, missed -> rebound
 *   8BFE  crowd "oh" (AA80 tune 8070), 8C16 made: crowd cheer (8039)
 *   8C60  both baskets (8C77): the net animation from 93DA, the score added
 *         when the ball drops out (93D9 points, event 44h)
 */
const { io } = require('./ent');
const { C, Z, add8, sub8, cp8, and8, xor8, inc8, dec8, neg, rl, rlc, bit, bitm, add16, exx } = require('./z80');

const STATE = 0x93EB, BLIT_Y = 0x3300, BLIT_SRC = 0x3302;

function ballStep(m) {                   // 8A23
  const r = m.r;
  r.a = m.rd(STATE);
  if (!bit(r, 0, r.a) && !bit(r, 2, r.a)) {
    if (bit(r, 1, r.a)) {                // 8A8E
      exx(r);
      m.push(r.b << 8 | r.c);
      m.call(0x9A1B);
      const v = m.pop(); r.b = v >> 8; r.c = v & 0xff;
      exx(r);
    } else if (bit(r, 3, r.a)) m.call(0x9BF6);
    else if (bit(r, 4, r.a)) {           // bounce
      r.ix = 0x93F1;
      const { ix, wx, sx, rx } = io(m);
      if (!bitm(r, 0, ix(-2))) {
        r.a = add8(r, ix(0), 6);
        wx(0, r.a);
        cp8(r, r.a, ix(2));
        if (!(r.f & C)) {
          r.a = ix(2); wx(0, r.a);
          sx(-2, 0);
          return m.jp(0x8BFE);
        }
      } else {
        r.a = ix(0);
        cp8(r, r.a, ix(-1));
        if (!(r.f & C)) { r.a = sub8(r, r.a, 6); wx(0, r.a); } else {
          r.a = add8(r, ix(-1), 6);
          cp8(r, r.a, ix(2));
          if (!(r.f & C)) {              // 8A5E: the bounce has died out
            r.a = xor8(r, r.a, r.a);
            m.wr(STATE, 0);
            m.call(0x8BFE);
          } else { wx(-1, r.a); rx(-2, 0); }
        }
      }
    }
  }
  r.ix = 0x940B; r.iy = 0x9425;          // 8A95
  r.h = 0x06; r.l = 0x90;
  m.call(0x8AAE);
  r.ix = 0x9425; r.iy = 0x940B;
  r.h = 0x19; r.l = 0x90;
  return icon(m);
}
function icon(m) {                       // 8AAE
  const r = m.r, { sx, rx } = io(m);
  const h = r.h, l = r.l;
  m.call(0x8CF7);
  r.d = 0x77; r.e = 0x50;
  sx(1, 6);
  if (!(r.f & C)) { rx(1, 6); r.e = 0x58; }
  r.h = h; r.l = l;
  return m.jp(0xB455);
}

function ballDraw(m) {                   // 8ADD
  const r = m.r;
  let hl = m.rd16(0x93F3);
  r.h = hl >> 8;
  r.l = r.a = sub8(r, hl & 0xff, 4);
  m.wr(BLIT_Y, r.l); m.wr(BLIT_Y + 1, r.h);
  r.a = 0x49;
  m.call(0x9E6F);
  m.call(0xB01C);
  hl = m.rd16(0x93F3);
  r.a = and8(r, m.rd(STATE), 0x1A);
  if (r.a) hl = m.rd16(0x93F1);
  r.h = hl >> 8;
  r.l = r.a = sub8(r, hl & 0xff, 8);
  m.wr(BLIT_Y, r.l); m.wr(BLIT_Y + 1, r.h);
  r.a = 0x48;
  m.call(0x9E6F);
  m.call(0xB01C);
  r.ix = 0x93F5;
  if (!bitm(r, 1, m.rd(0x93F5))) return;
  m.wr(0x93F5, 0);
  r.a = m.rd(STATE);
  if (bit(r, 3, r.a)) {                  // rebound over: bounce from the hand
    r.a = and8(r, r.a, 0xE0) | 0x10;
    m.wr(STATE, r.a);
    r.a = add8(r, m.rd(0x93F1), 6);
    m.wr(0x93F0, r.a);
    m.wr(0x93EF, 0);
    r.h = 0x93; r.l = 0xEF;
    return;
  }
  // 8B32: the shot chance
  const term = (src, mul, adj, div) => {
    r.a = m.rd(src);
    if (adj !== null) { r.a = neg(r, r.a); r.a = add8(r, r.a, adj); }
    r.b = 0; r.c = mul; r.l = r.a; r.h = 0;
    m.call(0x398C);
    r.b = 0; r.c = div;
    m.call(0x39A3);
  };
  const plus = () => { const v = add16(r, r.h << 8 | r.l, r.d << 8 | r.e); r.h = v >> 8; r.l = v & 0xff; };
  const exDE = () => { const d = r.d, e = r.e; r.d = r.h; r.e = r.l; r.h = d; r.l = e; };
  term(0x944F, 0x32, null, 0x46); exDE();
  term(0x9450, 0x23, null, 0x08); plus(); exDE();
  r.a = m.rd(0x944E); r.b = 0; r.c = 0x0A;
  r.a = add8(r, neg(r, r.a), 0x16); r.l = r.a; r.h = 0;
  m.call(0x398C); r.b = 0; r.c = 0x17; m.call(0x39A3);
  plus(); exDE();
  r.a = m.rd(0x944D); r.b = 0; r.c = 5;
  r.a = add8(r, neg(r, r.a), 0x32); r.l = r.a; r.h = 0;
  m.call(0x398C); r.b = 0; r.c = 0x32; m.call(0x39A3);
  plus();
  m.call(0xA172);
  r.a = add8(r, r.a, 4);
  r.c = r.l;
  m.call(0xA0B0);
  r.c = rl(r, r.c);                      // c bit 0 = missed (the product overflowed)
  r.a = m.rd(STATE);
  bit(r, 7, r.a);
  if (r.f & Z) { r.ix = 0x9425; r.iy = 0x940B; } else { r.ix = 0x940B; r.iy = 0x9425; }
  const { ix, iy, wx, wy } = io(m);
  const inc = (d) => wx(d, inc8(r, ix(d)));
  r.a = m.rd(0x93D9);
  cp8(r, r.a, 3);
  if (r.a === 3) { inc(0x11); if (!bit(r, 0, r.c)) inc(0x12); } else {
    cp8(r, r.a, 1);
    if (r.a === 1) { inc(0x0E); if (!bit(r, 0, r.c)) inc(0x0F); } else inc(0x0C);
  }
  if (!bit(r, 0, r.c)) return made(m);
  r.a = (m.rd(STATE) & ~0x02) | 0x08;    // missed: rebound
  m.wr(STATE, r.a);
  r.a = sub8(r, ix(-3), 2);
  if (r.f & C) r.a = xor8(r, r.a, r.a);
  wx(-3, r.a);
  r.a = inc8(r, iy(-3));
  cp8(r, r.a, 0x33);
  if (r.a !== 0x33) wy(-3, r.a);
  m.call(0x8BFE);
  r.a = and8(r, m.rd(0x93D6), m.rd(0x93D6));
  if (!r.a) return;
  r.e = 3;
  return m.jp(0x9919);
}

function crowdOh(m) {                    // 8BFE
  const r = m.r;
  r.a = and8(r, m.rd(0x93D8), m.rd(0x93D8));
  if (r.a) return;
  r.a = inc8(r, r.a);
  m.wr(0xAA83, r.a);
  m.wr16(BLIT_Y, 2);
  r.h = 0x80; r.l = 0x70;
  m.wr16(BLIT_SRC, 0x8070);
  return m.jp(0xAA80);
}

function made(m) {                       // 8C16
  const r = m.r, { ix, iy, wx, wy } = io(m);
  r.a = m.rd(0x93D9);
  cp8(r, r.a, 2);
  if (r.a === 2) wx(0x0D, inc8(r, ix(0x0D)));
  r.a = (m.rd(STATE) & ~0x02) | 0x04;
  m.wr(STATE, r.a);
  r.d = 0x93; r.e = 0xDC;
  m.wr16(0x93DA, 0x93DC);
  r.a = add8(r, ix(-3), 2);
  cp8(r, r.a, 0x32);
  if (!(r.f & C)) r.a = 0x32;
  wx(-3, r.a);
  r.a = and8(r, iy(-3), iy(-3));
  if (r.a) wy(-3, dec8(r, iy(-3)));
  if (bitm(r, 5, ix(0))) return;
  r.a = xor8(r, r.a, r.a);
  m.wr(0xAA83, 0);
  m.wr16(BLIT_Y, 2);
  r.h = 0x80; r.l = 0x39;
  m.wr16(BLIT_SRC, 0x8039);
  return m.jp(0xAA80);
}

function baskets(m) {                    // 8C60
  const r = m.r;
  r.h = 0x04; r.l = 0x18; r.d = 0x94; r.e = 0x02; r.ix = 0x9425;
  m.call(0x8C77);
  r.h = 0x70; r.l = 0x18; r.d = 0x94; r.e = 0x01; r.ix = 0x940B;
  return basket(m);
}
function basket(m) {                     // 8C77: HL = position, DE = the score cell
  const r = m.r, { ix } = io(m);
  m.push(r.h << 8 | r.l);
  r.a = m.rd(STATE);
  r.c = r.a;
  bit(r, 2, r.a);
  let frame = 0x3E;
  r.a = 0x3E;
  if (!(r.f & Z)) {
    r.c = rlc(r, r.c);
    r.a = and8(r, xor8(r, ix(1), r.c), 1);
    r.a = 0x3E;
    if (r.f & Z) {
      let hl = m.rd16(0x93DA);
      r.a = m.rd(hl); hl++;
      m.wr16(0x93DA, hl);
      r.h = hl >> 8; r.l = hl & 0xff;
      cp8(r, r.a, 0xFF);
      frame = r.a;
      if (r.a === 0xFF) {                // the ball drops out of the net
        r.a = 0x2A; m.wr(0x93F1, 0x2A);
        r.a = add8(r, r.a, 8); m.wr(0x93F0, r.a);
        m.wr(0x93EF, 0);
        r.h = 0x93; r.l = 0xEF;
        r.a = (m.rd(STATE) & ~0x04) | 0x10;
        m.wr(STATE, r.a);
        r.a = and8(r, m.rd(0x9400), m.rd(0x9400));
        let score = true;
        if (r.a) {
          r.c = r.a = and8(r, r.a, 0x80);
          r.a = and8(r, m.rd(STATE), 0x80);
          r.a = xor8(r, r.a, r.c);
          if (!r.a) score = false;
        }
        if (score) {                     // 8CC2
          r.a = m.rd(0x93D9);
          const d = r.d, e = r.e; r.d = r.h; r.e = r.l; r.h = d; r.l = e;
          const at = r.h << 8 | r.l;
          r.a = add8(r, r.a, m.rd(at));
          m.wr(at, r.a);
          r.a = dec8(r, m.rd(0x93D3));
          if (r.a) m.call(0x9FF2);
          r.e = 0x44;
          m.call(0x9919);
        }
        r.h = m.rd(0x93F4); r.a = r.h;   // 8CD4
        r.l = 0x22;
        m.wr(BLIT_Y, r.l); m.wr(BLIT_Y + 1, r.h);
        r.a = 0x48;
        m.call(0x9E6F);
        m.call(0xB01C);
        frame = 0x42;
      }
    }
  }
  r.a = frame;                           // 8CE7
  const hl = m.pop(); r.h = hl >> 8; r.l = hl & 0xff;
  m.wr16(BLIT_Y, hl);
  if (bit(r, 6, r.h)) r.a = add8(r, r.a, 5);
  m.call(0x9E6F);
  return m.jp(0xB01C);
}

module.exports = {
  procs: { '8A23': ballStep, '8AAE': icon, '8ADD': ballDraw, '8BFE': crowdOh, '8C16': made, '8C60': baskets, '8C77': basket },
};
