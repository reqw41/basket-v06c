'use strict';
/**
 * Main menu, A5FD..A79A.
 *   A5FD  menu: frame, players on the court, texts; A694 the key loop:
 *         1 / 2 = one / two players (names to 945F, 0FED = 1: match), 3 = level
 *         (93D2, tune 0A), 4 = enter names (A6E1: 38E8 line input, A739 copy)
 *   A739  copy the typed name (4146.., FF-terminated) to DE, pad to 9 with spaces
 *   A75F  box: ink A, at HL, size C x B (34BA draws it with the pass flag 0118)
 *   A77F  one menu frame: the court (A4A8), both players, flush (B1FE)
 */
const { C, Z, sub8, cp8, and8, xor8, inc8, dec8, neg, ldir } = require('./z80');

const INK = 0x3424, BLIT_Y = 0x3300;

function text(m, h, l, d, e) {
  const r = m.r;
  r.h = h; r.l = l;
  if (d !== undefined) { r.d = d; r.e = e; }
  m.call(0xA01F);
}

function menu(m) {                       // A5FD
  const r = m.r;
  r.a = 0xF1; m.wr(INK, 0xF1);
  m.call(0x3732);
  m.pcall(0x01FB);
  r.a = 7; m.wr(0x0FED, 7);
  r.h = 0x01; r.l = 0x60; r.b = 0x1E; r.c = 0x60; r.a = 0x17;
  m.call(0xA75F);
  return menuBox(m);
}
function menuBox(m) {                    // A618
  const r = m.r;
  r.h = 0x06; r.l = 0x60; m.wr16(BLIT_Y, 0x0660);
  r.h = 0; r.l = 0x58; m.wr16(0x3308, 0x58);
  r.l = 0x14; m.wr16(0x330A, 0x14);
  r.a = 0xF1; m.wr(INK, 0xF1);
  m.pcall(0x18F6);
  m.wr16(0x940D, 0x076E);
  m.wr16(0x9427, 0x6E6E);
  m.wr16(0x9409, 0x0C00);
  m.wr16(0x9423, 0x0400);
  r.a = 0x10; m.wr(0x940B, 0x10); m.wr(0x9425, 0x10);
  r.a = xor8(r, r.a, r.a);
  m.wr(0x9426, 0); m.wr(0xA49F, 0);
  r.a = inc8(r, r.a);
  m.wr(0x940C, 1);
  text(m, 0x08, 0x08, 0xA7, 0x97);
  r.l = 0x0A; m.call(0xA01F);
  return menuLevel(m);
}
function menuLevel(m) {                  // A669
  const r = m.r;
  text(m, 0x08, 0x0C, 0xA7, 0xAD);
  m.push(r.d << 8 | r.e);
  r.d = 0xA7; r.e = 0xDA;
  r.a = and8(r, m.rd(0x93D2), 3);
  if (r.a) {
    r.e = 0xE2;
    r.a = dec8(r, r.a);
    if (r.a) r.e = 0xEA;
  }
  m.call(0xA022);
  const de = m.pop(); r.d = de >> 8; r.e = de & 0xff;
  r.l = 0x0E; m.call(0xA01F);
  r.l = 0x10; m.call(0xA01F);
  return menuKeys(m);
}
function menuKeys(m) {                   // A694
  const r = m.r;
  for (;;) {
    m.call(0xA77F);
    m.pcall(0x06BB);
    cp8(r, r.a, 0x34);
    if (r.a === 0x34) return names(m);
    cp8(r, r.a, 0x33);
    if (r.a === 0x33) {                  // A6CD: level
      r.a = inc8(r, m.rd(0x93D2));
      cp8(r, r.a, 3);
      if (!(r.f & C)) r.a = xor8(r, r.a, r.a);
      m.wr(0x93D2, r.a);
      r.a = 0x0A;
      m.call(0x3A2C);
      return menuLevel(m);
    }
    r.c = 1;
    cp8(r, r.a, 0x31);
    if (r.a !== 0x31) {
      cp8(r, r.a, 0x32);
      if (r.a !== 0x32) continue;
      r.c = dec8(r, r.c);
    }
    r.a = r.c;                           // A6B2
    m.wr(0x93EA, r.a);
    and8(r, r.a, r.a);
    r.h = 0xA7; r.l = r.a ? 0xF2 : 0xFD;
    r.d = 0x94; r.e = 0x5F; r.b = 0; r.c = 0x0A;
    ldir(m);
    r.a = 1; m.wr(0x0FED, 1);
    return;
  }
}
function names(m) {                      // A6E1
  const r = m.r;
  r.h = 0x06; r.l = 0x60; m.wr16(BLIT_Y, 0x0660);
  r.h = 0; r.l = 0x50; m.wr16(0x3308, 0x50);
  r.l = 0x14; m.wr16(0x330A, 0x14);
  r.a = 0xF1; m.wr(INK, 0xF1);
  m.pcall(0x18F6);
  const ask = (row, d, e, dst) => {
    text(m, 0x08, row, d, e);
    r.h = 0x08; r.l = row + 2; m.wr16(0x4102, 0x0800 | (row + 2));
    r.h = 0; r.l = 9; m.wr16(BLIT_Y, 9);
    m.call(0x38E8);
    r.d = dst >> 8; r.e = dst & 0xff;
    m.call(0xA739);
  };
  ask(0x08, 0xA8, 0x08, 0x9453);
  ask(0x0C, 0xA8, 0x1A, 0xA7FD);
  return menuBox(m);
}

function copyName(m) {                   // A739
  const r = m.r;
  let hl = 0x4146, de = r.d << 8 | r.e;
  r.c = 0;
  for (;;) {
    r.a = m.rd(hl);
    cp8(r, r.a, 0xFF);
    if (r.a === 0xFF) break;
    m.wr(de, r.a); de++; hl++;
    r.c = inc8(r, r.c);
  }
  r.h = hl >> 8; r.l = hl & 0xff; r.d = de >> 8; r.e = de & 0xff;
  r.a = and8(r, r.c, r.c);
  if (!r.a) return;
  r.a = sub8(r, r.a, 9);
  if (!r.a) return;
  r.a = neg(r, r.a);
  let p = de;
  r.d = hl >> 8; r.e = hl & 0xff;
  do { m.wr(p, 0x20); p++; r.a = dec8(r, r.a); } while (r.a);
  r.h = p >> 8; r.l = p & 0xff;
}

function box(m) {                        // A75F
  const r = m.r;
  m.wr(INK, r.a);
  m.wr(BLIT_Y, r.l); m.wr(BLIT_Y + 1, r.h);
  r.h = 0; r.l = r.c; m.wr16(0x3308, r.l);
  r.l = r.b; m.wr16(0x330A, r.l);
  r.h = 0x01; r.l = 0x18; m.wr16(0x34DF, 0x0118);
  m.call(0x34BA);
  r.h = 0x88; r.l = 0xCD; m.wr16(0x34DF, 0x88CD);
}

function menuFrame(m) {                  // A77F
  const r = m.r;
  m.call(0xA4A8);
  r.d = 0x09; r.e = 0x01;
  r.d = 0x09; r.e = 0x1A;                // A493 is an empty stub
  m.call(0x9599);
  m.call(0x958F);
  return m.jp(0xB1FE);
}

module.exports = {
  procs: {
    'A5FD': menu, 'A618': menuBox, 'A669': menuLevel, 'A694': menuKeys, 'A6E1': names,
    'A739': copyName, 'A75F': box, 'A77F': menuFrame,
  },
};
