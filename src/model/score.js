'use strict';
/**
 * Scoreboard printing (TEXT_ROW 4102 / TEXT_COL 4103, ink 3424, 3B53 prints A).
 *   9F9A  clock "M:SS" at 0E14 (not after the end of the match by fouls)
 *   9FC0  fouls 1..5 of both players at 0112 / 0114 (ink 91 for committed, F1 free)
 *   9FF2  scores at 0812 / 081B (A037: 3 digits, leading zeros as '0')
 *   A00E  player names (9452.., FF-terminated) at 0114 / 1414
 *   A02C / A037 / A03B  print A as decimal (A03B: leading spaces)
 *   A063  print A keeping all registers
 *   A0B0  A = A * C (8 x 8, CF = overflow)
 * Random helpers for the AI (HL kept): A133 chance by level, A160 (CF: h < 64h),
 * A169 / A172 bits of the random high byte, A17B (IX = 3), A193 seed += 7 (-> B1F2).
 */
const { C, S, Z, add8, sub8, cp8, and8, or8, xor8, inc8, dec8, rl, rrca, bitm, add16, sbc16 } = require('./z80');

const ROW = 0x4102, COL = 0x4103, INK = 0x3424;

function putc(m) {                       // A063
  const r = m.r;
  m.push(r.a << 8 | r.f); m.push(r.b << 8 | r.c); m.push(r.d << 8 | r.e); m.push(r.h << 8 | r.l);
  m.call(0x3B53);
  let v = m.pop(); r.h = v >> 8; r.l = v & 0xff;
  v = m.pop(); r.d = v >> 8; r.e = v & 0xff;
  v = m.pop(); r.b = v >> 8; r.c = v & 0xff;
  v = m.pop(); r.a = v >> 8; r.f = v & 0xff;
}
const pc = (m, a) => { m.r.a = a; m.call(0xA063); };

function clock(m) {                      // 9F9A
  const r = m.r;
  r.a = and8(r, m.rd(0x93E5), m.rd(0x93E5));
  if (r.a) return;
  m.wr16(ROW, 0x0E14);
  r.a = 0xF1; m.wr(INK, 0xF1);
  r.h = 0x93; r.l = 0xE7;
  pc(m, m.rd(0x93E7));
  pc(m, 0x3A);
  r.l = 0xE8; pc(m, m.rd(0x93E8));
  r.l = 0xE9; r.a = m.rd(0x93E9);
  return m.jp(0xA063);
}

function fouls(m) {                      // 9FC0
  const r = m.r;
  r.h = 0x01; r.l = 0x12;
  m.wr16(ROW, 0x0112);
  r.a = m.rd(0x9416);
  m.call(0x9FD4);
  r.a = 0x14; m.wr(COL, 0x14);
  r.a = m.rd(0x9430);
  return foulRow(m);
}
function foulRow(m) {                    // 9FD4: digits 1..5, the first A+1 ... in 91 ink
  const r = m.r;
  r.c = inc8(r, r.a);
  r.b = 5;
  do {
    m.push(r.b << 8 | r.c);
    r.a = sub8(r, 6, r.b);
    cp8(r, r.a, r.c);
    r.a = r.f & C ? 0x91 : 0xF1;
    m.wr(INK, r.a);
    const v = m.pop(); r.b = v >> 8; r.c = v & 0xff;
    r.a = add8(r, sub8(r, 6, r.b), 0x30);
    m.call(0xA063);
    r.b = (r.b - 1) & 0xff;
  } while (r.b);
}

function scores(m) {                     // 9FF2
  const r = m.r;
  r.h = 0x08; r.l = 0x12;
  m.wr16(ROW, 0x0812);
  r.a = 0xA1; m.wr(INK, 0xA1);
  r.a = m.rd(0x9401);
  m.call(0xA037);
  r.a = 0x1B; m.wr(COL, 0x1B);
  r.a = m.rd(0x9402);
  return m.jp(0xA037);
}

function names(m) {                      // A00E
  const r = m.r;
  r.a = 0xF1; m.wr(INK, 0xF1);
  r.d = 0x94; r.e = 0x52;
  r.h = 0x01; r.l = 0x14;
  m.call(0xA01F);
  r.h = 0x14; r.l = 0x14;
  return text(m);
}
function text(m) {                       // A01F: at HL, string at DE until FF
  const r = m.r;
  m.wr(ROW, r.l); m.wr(ROW + 1, r.h);
  return textCont(m);
}
function textCont(m) {                   // A022
  const r = m.r;
  for (;;) {
    let de = r.d << 8 | r.e;
    r.a = m.rd(de); de = (de + 1) & 0xffff;
    r.d = de >> 8; r.e = de & 0xff;
    cp8(r, r.a, 0xFF);
    if (r.a === 0xFF) return;
    m.call(0xA063);
  }
}

function dec2(m) {                       // A02C: 2 digits, leading '0'
  const r = m.r;
  m.push(r.h << 8 | r.l); m.push(r.d << 8 | r.e);
  r.l = r.a; r.h = 0; r.b = 0xFF; r.e = 0x30;
  return decTail(m);
}
function dec3z(m) { m.r.c = 0x30; return dec3(m); }      // A037
function dec3s(m) { m.r.c = 0x20; return dec3(m); }      // A03B
function dec3(m) {                       // A03D
  const r = m.r;
  m.push(r.h << 8 | r.l); m.push(r.d << 8 | r.e);
  r.l = r.a; r.h = 0; r.e = r.c;
  r.b = 0xFF; r.c = 0x9C;
  m.call(0xA055);
  return decTail(m);
}
function decTail(m) {                    // A049
  const r = m.r;
  r.c = 0xF6;
  m.call(0xA055);
  r.a = r.l;
  m.call(0xA05F);
  let v = m.pop(); r.d = v >> 8; r.e = v & 0xff;
  v = m.pop(); r.h = v >> 8; r.l = v & 0xff;
}
function digit(m) {                      // A055: A = HL / -BC, HL = remainder
  const r = m.r, bc = r.b << 8 | r.c;
  let hl = r.h << 8 | r.l;
  r.a = xor8(r, r.a, r.a);
  do { hl = add16(r, hl, bc); r.a = inc8(r, r.a); } while (r.f & C);
  hl = sbc16(r, hl, bc);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = dec8(r, r.a);
  if (!r.a) return digitOut(m);
  return digitZero(m);
}
function digitZero(m) { m.r.e = 0x30; return digitOut(m); }   // A05F
function digitOut(m) {                   // A061: print A + E unless negative
  const r = m.r;
  r.a = add8(r, r.a, r.e);
  if (r.f & S) return;
  return m.jp(0xA063);
}

function mul8(m) {                       // A0B0
  const r = m.r;
  r.l = r.a;
  r.a = xor8(r, r.a, r.a);
  r.b = 8;
  do {
    r.a = add8(r, r.a, r.a);
    if (r.f & C) return;
    r.c = rl(r, r.c);
    if (r.f & C) { r.a = add8(r, r.a, r.l); if (r.f & C) return; }
    r.b = (r.b - 1) & 0xff;
  } while (r.b);
}

// ---- random helpers ---------------------------------------------------------------
function rngH(m) { const r = m.r, h = r.h, l = r.l; m.call(0x386E); r.a = r.h; r.h = h; r.l = l; }
function chance(m) {                     // A133: Z (A = 0) = act now; A = 10h otherwise
  const r = m.r;
  const z = !bitm(r, 6, m.rd((r.ix + 1) & 0xffff));
  r.a = 0x10;
  if (z) return;
  r.a = and8(r, m.rd(0x93D2), 3);
  cp8(r, r.a, 2);
  if (r.f & C) {
    const h = r.h, l = r.l, d = r.d, e = r.e;
    r.a = inc8(r, r.a);
    rrca(r); rrca(r); rrca(r);
    r.e = r.a;
    m.call(0x386E);
    r.a = r.h;
    cp8(r, r.a, r.e);
    r.d = d; r.e = e; r.h = h; r.l = l;
    if (!(r.f & C)) { r.a = or8(r, r.a, 1); r.a = 0; return; }
  }
  r.a = or8(r, 0x10, 0x10);
}
function rnd64(m) { rngH(m); cp8(m.r, m.r.a, 0x64); }                       // A160
function rnd10(m) { rngH(m); m.r.a = and8(m.r, m.r.a, 0x10); }              // A169
function rnd0F(m) { rngH(m); m.r.a = and8(m.r, m.r.a, 0x0F); }              // A172
function rndIX(m) { rngH(m); m.r.ix = 3; }                                  // A17B
function seed7(m) {                      // A193
  const r = m.r;
  m.wr16(0x4114, add16(r, m.rd16(0x4114), 7));
  return m.jp(0xB1F2);
}

module.exports = {
  procs: {
    'A063': putc, '9F9A': clock, '9FC0': fouls, '9FD4': foulRow, '9FF2': scores, 'A00E': names,
    'A01F': text, 'A022': textCont, 'A02C': dec2, 'A037': dec3z, 'A03B': dec3s, 'A03D': dec3,
    'A049': decTail, 'A055': digit, 'A05F': digitZero, 'A061': digitOut, 'A0B0': mul8,
    'A133': chance, 'A160': rnd64, 'A169': rnd10, 'A172': rnd0F, 'A17B': rndIX, 'A193': seed7,
  },
};
