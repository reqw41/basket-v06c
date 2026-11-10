'use strict';
/**
 * Stamina bars and the match clock, 9E82..9F97.
 *   9E82  stamina back (+1 every few calls, ix+09 the rate counter, ix+0A level)
 *   9ED4  stamina down while running; both redraw one bar cell (9F48: jp 02CE,
 *         the platform's cell print: HL = row/col, C = tile)
 *   9F25  draw both bars from 9415 / 942F
 *   9F60 / 9F67  clock on / off (the ISR hook 3705+1 -> 9F6E / 9F6D)
 *   9F6E  ISR clock: 3715, then 50 frames = 1 s off the clock 93E7..93E9
 *         ("M:SS" digits); at 0:00 93E5 = 1 (end of the half) and the clock stops
 */
const { io } = require('./ent');
const { C, Z, add8, sub8, cp8, and8, xor8, inc8, dec8, srl, bit, bitm, add16 } = require('./z80');

function cell(m) { return m.jp(0x9F48); }

function staminaUp(m) {                  // 9E82
  const r = m.r, { ix, wx } = io(m);
  r.a = and8(r, m.rd(0x93D6), m.rd(0x93D6));
  if (r.a) return;
  r.a = dec8(r, m.rd(0x93D3));
  if (!r.a) return;
  r.a = ix(0x0A);
  cp8(r, r.a, 0x16);
  if (!(r.f & C)) return;
  r.a = 1; r.b = 1;
  r.c = ix(9);
  if (bit(r, 7, r.c)) {
    r.b = r.a;
    r.c &= 0x7F;
    r.a = sub8(r, r.a, r.c);
    if (r.f & C) r.a = xor8(r, r.a, r.a);
    r.c = r.a;
    r.a = r.b;
  }
  r.c = inc8(r, r.c);
  cp8(r, r.a, r.c);
  if (r.f & C) r.c = 0;
  wx(9, r.c);
  if (!(r.f & C)) return;
  r.h = 0x10; r.l = 0x01;
  if (!bitm(r, 0, ix(1))) r.l = 0x14;
  r.a = inc8(r, ix(0x0A));
  wx(0x0A, r.a);
  r.a = dec8(r, r.a);
  r.d = 0; r.e = srl(r, r.a);
  const hl = add16(r, r.h << 8 | r.l, r.e);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.c = 0xE0;
  if (bit(r, 0, r.a)) r.c = 0xEE;
  return cell(m);
}

function staminaDown(m) {                // 9ED4
  const r = m.r, { ix, wx } = io(m);
  r.a = and8(r, m.rd(0x93D6), m.rd(0x93D6));
  if (r.a) return;
  r.a = dec8(r, m.rd(0x93D3));
  if (!r.a) return;
  r.a = and8(r, ix(0x0A), ix(0x0A));
  if (!r.a) return;
  r.a = 7; r.b = 7;
  r.c = ix(9);
  if (!bit(r, 7, r.c)) {
    r.b = r.a;
    r.a = sub8(r, r.a, r.c);
    if (r.f & C) r.a = xor8(r, r.a, r.a);
    r.c = r.a;
    r.a = r.b;
  }
  r.c &= 0x7F;
  r.c = inc8(r, r.c);
  cp8(r, r.a, r.c);
  if (r.f & C) r.c = 0;
  r.c |= 0x80;
  wx(9, r.c);
  if (!(r.f & C)) return;
  r.h = 0x10; r.l = 0x01;
  if (!bitm(r, 0, ix(1))) r.l = 0x14;
  r.a = dec8(r, ix(0x0A));
  wx(0x0A, r.a);
  r.a = inc8(r, r.a);
  r.d = 0; r.e = srl(r, r.a);
  const hl = add16(r, r.h << 8 | r.l, r.e);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.c = 0;
  if (!bit(r, 0, r.a)) { r.c = 0xE0; r.l = dec8(r, r.l); }
  return cell(m);
}

function bars(m) {                       // 9F25
  const r = m.r;
  r.h = 0x10; r.l = 0x01;
  r.a = m.rd(0x9415);
  r.c = 0xEE;
  m.call(0x9F36);
  r.h = 0x10; r.l = 0x14;
  r.a = m.rd(0x942F);
  return bar(m);
}
function bar(m) {                        // 9F36: A half-cells from HL
  const r = m.r;
  r.a = and8(r, r.a, r.a);
  if (!r.a) return;
  r.b = srl(r, r.a);
  if (r.b) {
    do {
      m.call(0x9F48);
      r.l = inc8(r, r.l);
      r.b = (r.b - 1) & 0xff;
    } while (r.b);
  }
  if (!bit(r, 0, r.a)) return;
  r.c = 0xE0;
  return cell(m);
}

function clockOn(m) { m.r.h = 0x9F; m.r.l = 0x6E; m.wr16(0x3706, 0x9F6E); }     // 9F60
function clockOff(m) { m.r.h = 0x9F; m.r.l = 0x6D; m.wr16(0x3706, 0x9F6D); }    // 9F67

function clockTick(m) {                  // 9F6E
  const r = m.r;
  m.call(0x3715);
  r.a = inc8(r, m.rd(0x93E6));
  cp8(r, r.a, 0x32);
  if (!(r.f & C)) r.a = xor8(r, r.a, r.a);
  m.wr(0x93E6, r.a);
  if (r.f & C) return;
  r.a = 0x2F;
  const digit = (at, top) => {           // dec (hl); cp (hl): NZ = no borrow
    const v = dec8(r, m.rd(at));
    m.wr(at, v);
    cp8(r, r.a, v);
    if (r.a !== v) return false;
    m.wr(at, top);
    return true;
  };
  r.h = 0x93; r.l = 0xE9;
  if (!digit(0x93E9, 0x39)) return;
  r.l = 0xE8;
  if (!digit(0x93E8, 0x35)) return;
  r.l = 0xE7;
  const v = dec8(r, m.rd(0x93E7));
  m.wr(0x93E7, v);
  cp8(r, r.a, v);
  if (r.a !== v) return;
  r.a = 1;
  m.wr(0x93E5, 1);
  return clockOff(m);
}

module.exports = {
  procs: {
    '9E82': staminaUp, '9ED4': staminaDown, '9F25': bars, '9F36': bar,
    '9F60': clockOn, '9F67': clockOff, '9F6E': clockTick,
  },
};
