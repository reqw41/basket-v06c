'use strict';
/**
 * The MSX PSG player of the original (AA7C..AC04), driven from the IRQ hook
 * 3702/3703 (AB28 music, AB83 effects). PSG writes go through ABFF (E = value,
 * A = register, platform 0093). To be replaced by the VI53 player (track B).
 *   AA7C  start the tune at BLIT_Y (3300): AC05/AC07 position / loop start,
 *         three channel blocks at AC09 (8 bytes each), 30 bytes of the
 *         instrument table to AC25; AA82 = 1 plays once (then AB83)
 *   AA80 / AAF0  start an effect at BLIT_SRC (3302) unless one is playing (AC13),
 *         AA84 = 0 lets an effect replace an effect
 *   AB28  IRQ: the tune step (0726 = the tune engine), AB21 = EI / NOP (SMC)
 *   AB83  IRQ: the effect step (AC21 on, AC22 delay from AA83, AC23 pointer)
 */
const { C, Z, add16, cp8, and8, or8, xor8, dec8, srl, bit, ldir } = require('./z80');

function psg(m) {                        // ABFF: register A = C
  const r = m.r;
  r.e = r.c;
  m.pcall(0x0093);
  r.iff = 0;
}

function tune(m) { return tuneAt(m); }   // AA7C (jr AA85)
function tuneAt(m) {                     // AA85
  const r = m.r;
  const hl = m.rd16(0x3300);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.iff = 0;
  m.wr16(0xAC07, hl);
  return tuneFrom(m);
}
function tuneFrom(m) {                   // AA8C: (AC05) = HL
  const r = m.r;
  m.wr(0xAC05, r.l); m.wr(0xAC06, r.h);
  return tuneStep(m);
}
function tuneStep(m) {                   // AA8F
  const r = m.r;
  for (;;) {
    let hl = m.rd16(0xAC05);
    r.iy = 0xAC09;
    r.b = 3;
    let loop = false;
    do {
      m.wr(r.iy, 0); m.wr(r.iy + 1, 0);
      r.e = m.rd(hl); hl++; r.d = m.rd(hl); hl++;
      r.a = and8(r, r.e, r.d);
      cp8(r, r.a, 0xFF);
      if (r.a === 0xFF) {                // end of the tune
        r.a = or8(r, m.rd(0xAA82), m.rd(0xAA82));
        const once = !(r.f & Z);
        r.a = 0;
        m.wr(0xAA82, 0);
        r.h = hl >> 8; r.l = hl & 0xff;
        if (once) { r.h = 0xAB; r.l = 0x83; return hook(m); }
        const l = m.rd16(0xAC07);
        r.h = l >> 8; r.l = l & 0xff;
        m.wr16(0xAC05, l);
        loop = true;
        break;
      }
      m.wr(r.iy + 2, r.e); m.wr(r.iy + 3, r.d);
      r.d = 0; r.e = 8;
      r.iy = add16(r, r.iy, 8);
      r.b = (r.b - 1) & 0xff;
    } while (r.b);
    if (loop) continue;
    r.e = m.rd(hl); hl++; r.d = m.rd(hl); hl++;
    m.wr16(0xAC05, hl);
    r.h = r.d; r.l = r.e; r.d = 0xAC; r.e = 0x25;
    r.b = 0; r.c = 0x1E;
    ldir(m);
    r.h = 0xAB; r.l = 0x28;
    return hook(m);
  }
}
function hook(m) {                       // AADA: mixer on, hook HL into the IRQ
  const r = m.r;
  r.iff = 0;
  r.a = 7; r.c = 0xB8;
  m.call(0xABFF);
  r.a = xor8(r, r.a, r.a);
  m.wr(0xAC21, 0);
  m.wr(0x3703, r.l); m.wr(0x3704, r.h);
  m.pcall(0x0090);
  if (m.rd(0xAB21) === 0xFB) r.iff = 1;
}

function effect(m) { return effectAt(m); }   // AA80 (jr AAF0)
function effectAt(m) {                   // AAF0
  const r = m.r;
  let hl = m.rd16(0xAC13);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = or8(r, r.h, r.l);
  if (r.a) return;
  r.a = or8(r, m.rd(0xAC21), m.rd(0xAC21));
  if (r.a) {
    r.a = or8(r, m.rd(0xAA84), m.rd(0xAA84));
    if (r.a) return;
  }
  hl = m.rd16(0x3302);
  r.iff = 0;
  m.wr16(0xAC23, hl);
  r.h = 0; r.l = 1;
  m.wr16(0xAC21, 1);
  r.a = 9; r.c = 0x10; m.call(0xABFF);
  r.a = 6; r.c = 0x1F; m.call(0xABFF);
  r.iff = 1;
}

function musicIrq(m) {                   // AB28
  const r = m.r;
  m.pcall(0x0726);
  if (r.f & Z) {
    r.a = xor8(r, r.a, r.a);
    m.wr(0xAB21, 0);
    m.call(0xAA8F);
    r.a = 0xFB; m.wr(0xAB21, 0xFB);
  }
  return effectIrq(m);
}
function effectIrq(m) {                  // AB83
  const r = m.r;
  r.a = or8(r, m.rd(0xAC21), m.rd(0xAC21));
  if (!r.a) return;
  r.a = or8(r, m.rd(0xAC22), m.rd(0xAC22));
  if (r.a) { r.a = dec8(r, r.a); m.wr(0xAC22, r.a); return; }
  r.a = m.rd(0xAA83);
  m.wr(0xAC22, r.a);
  let hl = m.rd16(0xAC23);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = m.rd(hl);
  cp8(r, r.a, 0xFF);
  if (r.a === 0xFF) {
    r.a = xor8(r, r.a, r.a);
    m.wr(0xAC21, 0);
    r.c = 0;
  } else {
    r.d = r.a;
    r.c = bit(r, 2, r.d) ? 0xA8 : 0xB8;
    r.a = 7; m.call(0xABFF);
    hl++; r.c = m.rd(hl); hl++;
    r.h = hl >> 8; r.l = hl & 0xff;
    m.push(hl);
    r.a = 2; m.call(0xABFF);
    hl = m.pop();
    r.c = m.rd(hl); hl++;
    m.wr16(0xAC23, hl);
    r.h = hl >> 8; r.l = hl & 0xff;
    r.a = 3; m.call(0xABFF);
    r.c = r.d;
    r.c = srl(r, r.c); r.c = srl(r, r.c); r.c = srl(r, r.c); r.c = srl(r, r.c);
  }
  r.a = 9;
  return psg(m);
}

module.exports = {
  procs: {
    'ABFF': psg, 'AA7C': tune, 'AA85': tuneAt, 'AA8C': tuneFrom, 'AA8F': tuneStep, 'AA80': effect,
    'AAF0': effectAt, 'AB28': musicIrq, 'AB83': effectIrq,
  },
};
