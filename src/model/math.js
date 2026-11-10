'use strict';
/**
 * System block arithmetic (MSX BIOS-like helpers of the original).
 *   398C  HL = BC * HL (16 x 16 -> low 16), DE kept; A = 0, BC = 0
 *   39A3  HL = HL / BC, remainder to 411A; DE kept. The caller's CF goes
 *         round the quotient shift and comes out in CF (as on the Z80).
 *   388A  random in [DE, HL): DE + rnd / (7FFF / (HL - DE)); also to BLIT_Y 3300
 */
const { add16, adc16, sbc16, dec8, xor8, rl, rr, sla, srl, ccf } = require('./z80');

function mul(m) {                        // 398C
  const r = m.r;
  const d0 = r.d, e0 = r.e;
  r.d = r.h; r.e = r.l; r.h = 0; r.l = 0;
  r.a = 0x10;
  do {
    r.b = srl(r, r.b); r.c = rr(r, r.c);
    if (r.f & 1) { const v = add16(r, r.h << 8 | r.l, r.d << 8 | r.e); r.h = v >> 8; r.l = v & 0xff; }
    r.e = sla(r, r.e); r.d = rl(r, r.d);
    r.a = dec8(r, r.a);
  } while (r.a);
  r.d = d0; r.e = e0;
}

function div(m) {                        // 39A3
  const r = m.r;
  const d0 = r.d, e0 = r.e;
  r.d = r.h; r.e = r.l; r.h = 0; r.l = 0;
  r.a = 0x10;
  const bc = r.b << 8 | r.c;
  do {
    r.e = rl(r, r.e); r.d = rl(r, r.d);
    let hl = adc16(r, r.h << 8 | r.l, r.h << 8 | r.l);
    hl = sbc16(r, hl, bc);
    if (r.f & 1) hl = add16(r, hl, bc);
    r.h = hl >> 8; r.l = hl & 0xff;
    ccf(r);
    r.a = dec8(r, r.a);
  } while (r.a);
  r.e = rl(r, r.e); r.d = rl(r, r.d);
  m.wr(0x411A, r.l); m.wr(0x411B, r.h);
  r.h = r.d; r.l = r.e;
  r.d = d0; r.e = e0;
}

function rndRange(m) {                   // 388A
  const r = m.r;
  const d0 = r.d, e0 = r.e;
  r.a = xor8(r, r.a, r.a);
  const span = sbc16(r, r.h << 8 | r.l, r.d << 8 | r.e);
  r.b = span >> 8; r.c = span & 0xff;
  r.h = 0x7F; r.l = 0xFF;
  m.call(0x39A3);
  const q = r.h << 8 | r.l;
  m.call(0x386E);
  r.b = q >> 8; r.c = q & 0xff;
  m.call(0x39A3);
  r.d = d0; r.e = e0;
  const hl = add16(r, r.h << 8 | r.l, r.d << 8 | r.e);
  r.h = hl >> 8; r.l = hl & 0xff;
  m.wr16(0x3300, hl);
}

module.exports = { procs: { '398C': mul, '39A3': div, '388A': rndRange } };
