'use strict';
/**
 * Computer opponent (player 2, ix = 9425, iy = 940B), 869C..8A22.
 * It writes a stick byte to AC4E (the controls of player 2) every frame.
 * State in the code area: 8696 last stick, 8697 hold counter, 8698 fire
 * divider, 8699 shot choice, 869A/869B random targets; 88D7 (the CP
 * immediate at 88D6) = 3 - level.
 *   869C  per-match setup: level, shot choice (8699), targets (86D0 via 388A)
 *   870E  the controller: restart / defence / attack / take the ball
 *   88F4  attack path to HL around the defender; 8963 defence path;
 *   8A01 / 8A0E  stick from the target HL (bits: 1 left, 3 right, 4 up, C down;
 *         ix-7 bit 0 = only x)
 */
const { io } = require('./ent');
const { C, Z, add8, sub8, cp8, and8, or8, xor8, inc8, dec8, neg, srl, rlca, bit, bitm } = require('./z80');

const LEVEL = 0x88D7;

function setup(m) {                      // 869C
  const r = m.r;
  r.h = 0; r.l = 0;
  m.wr16(0x8696, 0);
  r.a = and8(r, m.rd(0x93D2), 3);
  r.a = sub8(r, r.a, 4);
  r.a = neg(r, r.a);
  r.a = dec8(r, r.a);
  m.wr(LEVEL, r.a);
  m.call(0x386E);
  r.a = and8(r, r.a, 3);
  r.c = 0x0C;
  if (r.a) {
    cp8(r, r.a, 2);
    r.c = 1;
    if (!(r.f & C)) { r.c = 4; if (!(r.f & Z)) r.c = 3; }
  }
  r.a = r.c;
  m.wr(0x8699, r.a);
  r.ix = 0x9425; r.iy = 0x940B;
  return targets(m);
}

function targets(m) {                    // 86D0
  const r = m.r, { ix, iy } = io(m);
  m.call(0xA160);
  m.push(r.a << 8 | r.f);
  const cy = r.f & C;
  r.d = 0; r.e = 0x46; r.h = 0; r.l = 0x66;
  if (!cy) {
    r.a = ix(2);
    cp8(r, r.a, iy(2));
    r.h = 0; r.l = 0x4E;
    if (!(r.f & C)) { r.d = 0; r.e = 0x5E; r.h = 0; r.l = 0x68; }
  }
  m.call(0x388A);
  r.h = 0x14; r.l &= ~1;
  m.wr(0x869A, r.l); m.wr(0x869B, r.h);
  const af = m.pop(); r.a = af >> 8; r.f = af & 0xff;
  r.d = 0; r.e = 0x18;
  if (!(r.f & C)) r.e = 0x0A;
  r.h = 0; r.l = 0x22;
  m.call(0x388A);
  r.l &= ~1;
  r.a = r.l;
  m.wr(0x869B, r.a);
}

function control(m) {                    // 870E
  const r = m.r;
  r.ix = 0x9425; r.iy = 0x940B;
  const { ix, iy, wx, rx } = io(m);
  let to = 0, a;
  const go = (t, v) => { if (v !== undefined) r.a = v; to = t; };
  r.a = and8(r, m.rd(0x93D6), m.rd(0x93D6));
  if (r.a) {                             // a restart in progress
    if (!bitm(r, 4, ix(0))) go(0x877F);
    else if (bitm(r, 0, ix(0))) go(0x8776);
    else go(0x88E5, 0x10);
  } else {
    r.a = and8(r, m.rd(0x9400), m.rd(0x9400));
    if (r.a) {                           // 872D: an event: only a throw-in of ours
      if (bit(r, 7, r.a)) return;
      r.a = and8(r, r.a, 7);
      cp8(r, r.a, 4);
      if (r.a !== 4) return;
      r.h = 0x64; r.l = 0x54;
      rx(1, 6); rx(2, 0);
      go(0x889F);
    } else if (!bitm(r, 4, ix(0))) go(0x8873);
    else if (!bitm(r, 0, ix(0))) go(0x8783);
    else {
      const z = !bitm(r, 5, ix(0));
      r.a = m.rd(0x8699);
      if (!z) go(0x88E5);
      else if (bitm(r, 3, ix(0))) go(0x8776);
      else {
        r.a = ix(3);
        cp8(r, r.a, 0x20);
        if (!(r.f & C)) go(0x877F);
        else { m.call(0xA169); go(r.f & Z ? 0x877F : 0x88C6); }
      }
    }
  }
  for (;;) {
    switch (to) {
      case 0x8776: {
        const z = !bitm(r, 1, ix(0));
        r.a = 0x10;
        go(z ? 0x877F : 0x88E5);
        break;
      }
      case 0x877F: r.a = xor8(r, r.a, r.a); go(0x88E5); break;
      case 0x8783: {                     // with the ball: hold, dribble, drive
        r.a = and8(r, m.rd(0x8697), m.rd(0x8697));
        let hold = false;
        if (r.a) { r.a = dec8(r, r.a); m.wr(0x8697, r.a); hold = !!r.a; }
        if (!hold) {
          r.a = ix(0x0A);
          cp8(r, r.a, 4);
          if (!(r.f & C)) { go(0x87FE); break; }
          r.c = r.a;
          m.call(0xA172);
          r.a = or8(r, r.a, 3);
          r.a = add8(r, r.a, r.c);
          rlca(r);
          m.wr(0x8697, r.a);
        }
        r.a = sub8(r, ix(2), iy(2));     // 87A2
        r.e = 1;
        if (r.f & C) { r.e = dec8(r, r.e); r.a = neg(r, r.a); }
        cp8(r, r.a, 6);
        if (!(r.f & C)) { go(0x877F); break; }
        r.a = sub8(r, add8(r, ix(3), 2), iy(3));
        r.d = 1;
        if (r.f & C) { r.d = dec8(r, r.d); r.a = neg(r, r.a); }
        cp8(r, r.a, 0x0E);
        if (!(r.f & C)) { go(0x877F); break; }
        cp8(r, r.a, 6);
        if (!(r.f & C)) {
          and8(r, r.d, r.d);
          const nz = !(r.f & Z);
          r.a = ix(-1);
          if (nz) { r.a = xor8(r, r.a, 0x0C); go(r.a ? 0x88C6 : 0x877F, r.a ? 0x1C : undefined); } else {
            r.a = xor8(r, r.a, 4); go(r.a ? 0x88C6 : 0x877F, r.a ? 0x14 : undefined);
          }
        } else {
          and8(r, r.e, r.e);
          const nz = !(r.f & Z);
          r.a = ix(-1);
          if (nz) { r.a = xor8(r, r.a, 3); go(r.a ? 0x88C6 : 0x877F, r.a ? 0x13 : undefined); } else {
            r.a = xor8(r, r.a, 1); go(r.a ? 0x88C6 : 0x877F, r.a ? 0x11 : undefined);
          }
        }
        break;
      }
      case 0x87FE: {                     // tired: walk to the basket / shoot
        r.a = and8(r, ix(-1), 0x0C);
        cp8(r, r.a, 4);
        if (r.a !== 4) {
          r.a = m.rd(0x8696);
          if (!bit(r, 3, r.a)) { go(0x88C6, 0x14); break; }
        }
        r.h = 0x07; r.l = 0x54;          // 8813
        r.a = ix(2);
        cp8(r, r.a, r.l);
        if (r.a === r.l) {
          r.a = ix(3);
          cp8(r, r.a, r.h);
          const z = !!(r.f & Z);
          r.a = 0x10;
          if (z) { go(0x88E5); break; }
        }
        r.a = inc8(r, m.rd(LEVEL));      // 8825
        r.a = neg(r, r.a);
        r.a = add8(r, r.a, iy(3));
        let far = false;
        cp8(r, r.a, 0x0E);
        if (r.f & C) {
          cp8(r, r.a, 4);
          if (!(r.f & C)) {
            r.a = iy(2);
            cp8(r, r.a, 0x51);
            if (!(r.f & C)) { cp8(r, r.a, 0x58); if (r.f & C) far = true; }
          }
        }
        if (far) { r.l = m.rd(0x869A); r.h = m.rd(0x869B); }
        r.a = m.rd(LEVEL);               // 8844
        r.c = r.a; r.b = r.a;
        r.c = inc8(r, r.c);
        cp8(r, r.a, 3);
        if (!(r.f & C)) r.c = inc8(r, r.c);
        r.a = add8(r, r.a, ix(2));
        r.a = sub8(r, r.a, r.l);
        let there = false;
        if (!(r.f & C)) {
          cp8(r, r.a, r.c);
          if (r.f & C) {
            r.a = add8(r, ix(3), r.b);
            r.a = sub8(r, r.a, r.h);
            if (!(r.f & C)) { cp8(r, r.a, r.c); if (r.f & C) there = true; }
          }
        }
        if (there) { m.call(0x86D0); go(0x88E5, 0x10); break; }
        m.call(0x88F4);                  // 8869
        r.a = and8(r, r.a, r.a);
        if (!r.a) r.a = 0x10;
        go(0x88C6);
        break;
      }
      case 0x8873: {                     // no ball: go for it or defend
        r.l = m.rd(0x93F3); r.h = m.rd(0x93F4);
        r.a = m.rd(0x93EB);
        if (bit(r, 2, r.a)) return;
        if (bit(r, 4, r.a)) { go(0x889F); break; }
        if (!bit(r, 3, r.a)) {
          if (!bit(r, 1, r.a) || !bit(r, 7, r.a)) { go(0x889F); break; }
        }
        r.a = sub8(r, ix(3), r.h);       // 888C
        r.e = 4;
        if (r.f & C) r.a = neg(r, r.a);
        cp8(r, r.a, 4);
        if (!(r.f & C)) { go(0x889F); break; }
        r.a = or8(r, 0x10, r.e);
        go(0x88C6);
        break;
      }
      case 0x889F: {
        m.call(0xA133);
        if (!(r.f & Z)) { go(0x88C6); break; }
        m.call(0x8963);
        r.a = and8(r, r.a, r.a);
        if (!r.a) {
          r.a = xor8(r, ix(3), 1); wx(3, r.a);
          r.a = xor8(r, ix(2), 1); wx(2, r.a);
          r.a = xor8(r, r.a, r.a);
        }
        if (bitm(r, 6, ix(1))) r.a = or8(r, r.a, 0x10);   // 88BE
        go(0x88C6);
        break;
      }
      case 0x88C6: {                     // fire only every few frames with the ball loose
        r.c = r.a;
        r.a = and8(r, r.a, r.a);
        if (!r.a) { go(0x88E5); break; }
        r.a = m.rd(0x93EB);
        const z = !bit(r, 0, r.a);
        r.a = r.c;
        if (z) { go(0x88E5); break; }
        r.a = inc8(r, m.rd(0x8698));
        cp8(r, r.a, m.rd(LEVEL));
        if (!(r.f & C)) r.a = xor8(r, r.a, r.a);
        m.wr(0x8698, r.a);
        r.a = and8(r, r.a, r.a);
        const zz = !r.a;
        r.a = r.c;
        if (!zz) r.a = m.rd(0x8696);
        go(0x88E5);
        break;
      }
      case 0x88E5:
        a = r.a;
        if (bitm(r, 7, ix(-2))) a &= ~0x10;
        r.a = a;
        m.wr(0xAC4E, a); m.wr(0x8696, a);
        return;
      default: throw new Error('ai: bad label ' + to.toString(16));
    }
  }
}

// ---- paths ------------------------------------------------------------------------------
function attack(m) {                     // 88F4: HL = target
  const r = m.r, { ix, iy } = io(m);
  r.c = 0x0C;
  r.a = ix(2);
  cp8(r, r.a, 0x54);
  if (r.f & C) { r.a = iy(2); cp8(r, r.a, 0x51); if (r.f & C) r.c = 0x10; }
  r.a = sub8(r, sub8(r, r.h, 6), iy(3));
  if (!(r.f & C)) return stickTo(m);
  r.a = neg(r, r.a);
  r.b = r.a;
  r.a = sub8(r, add8(r, ix(3), 6), iy(3));
  if (r.f & C) return stickTo(m);
  r.a = r.b;
  cp8(r, r.a, r.c);
  if (r.f & C) {
    r.a = sub8(r, ix(2), iy(2));
    r.e = 1;
    if (r.f & C) { r.e = dec8(r, r.e); r.a = neg(r, r.a); }
    r.a = iy(2);
    cp8(r, r.a, r.l);
    r.a = 1;
    if (r.f & C) r.a = dec8(r, r.a);
    r.a = add8(r, r.a, r.e);
    cp8(r, r.a, 1);
    if (r.a === 1) return stickTo(m);
    const nc = !(r.f & C);
    r.a = nc ? 0x0D : 0x0F;
    return;
  }
  r.e = 1;                               // 8944: go round
  r.a = sub8(r, r.l, iy(2));
  if (r.f & C) { r.e = dec8(r, r.e); r.a = neg(r, r.a); }
  r.a = inc8(r, r.a) & ~1;
  cp8(r, r.a, 6);
  if (!(r.f & C)) return stickTo(m);
  r.a = add8(r, r.a, 6);
  r.e = dec8(r, r.e);
  if (r.e) r.a = neg(r, r.a);
  r.l = r.a = add8(r, r.a, r.l);
  return stickTo(m);
}

function defend(m) {                     // 8963: HL = ball
  const r = m.r, { ix, iy } = io(m);
  r.c = 8;
  if (bitm(r, 4, iy(0))) r.c = 0x0A;
  r.a = sub8(r, ix(3), iy(3));
  if (r.f & C) r.a = neg(r, r.a);
  cp8(r, r.a, r.c);
  r.d = r.a;
  if (!(r.f & C)) return stickTo(m);
  r.b = iy(2) & ~0x10;
  r.b = srl(r, r.b); r.b = srl(r, r.b); r.b = srl(r, r.b); r.b = srl(r, r.b);
  const block = (b) => { r.b = b; r.h = r.a = sub8(r, r.h, r.b); return stickFrom(m); };   // 89AE
  if (bitm(r, 4, iy(0)) && !bitm(r, 2, iy(-1))) {
    r.a = ix(2);
    cp8(r, r.a, r.l);
    if (bitm(r, 1, iy(-1))) {
      r.l = inc8(r, r.l); r.l = inc8(r, r.l);
      if (!(r.f & C)) return stickTo(m);
      r.a = r.d;
      cp8(r, r.a, 6);
      if (!(r.f & C)) return stickTo(m);
      r.e = 3;
      return block(sub8(r, 0x14, r.b));
    }
    if (r.f & C) return stickTo(m);      // 89B3
    r.a = r.d;
    cp8(r, r.a, 6);
    if (!(r.f & C)) { r.l = dec8(r, r.l); r.l = dec8(r, r.l); return stickTo(m); }
    r.e = 1;
    r.a = add8(r, 0x62, r.b);
    r.b = 0x0F;
    cp8(r, r.a, iy(3));
    if (r.f & C) return block(0x0F);
    r.h = inc8(r, r.h); r.h = inc8(r, r.h);
    return stickFrom(m);
  }
  r.a = sub8(r, ix(2), iy(2));           // 89CE
  if (r.f & C) r.a = neg(r, r.a);
  r.a = inc8(r, r.a) & ~1;
  cp8(r, r.a, 4);
  if (!(r.f & C)) return stickTo(m);
  r.a = sub8(r, iy(2), r.l);
  r.e = 1;
  if (r.f & C) { r.e = dec8(r, r.e); r.a = neg(r, r.a); }
  r.a = inc8(r, r.a) & ~1;
  cp8(r, r.a, 4);
  if (!(r.f & C)) return stickTo(m);
  r.a = and8(r, r.a, r.a);
  if (!r.a) { r.e = 3; return stickFrom(m); }
  r.e = dec8(r, r.e);
  const nz = !(r.f & Z);
  r.e = nz ? 3 : 1;
  return stickFrom(m);
}

function stickTo(m) {                    // 8A01: x part from L
  const r = m.r, { ix } = io(m);
  r.a = r.l;
  r.e = 0;
  cp8(r, r.a, ix(2));
  if (!(r.f & Z)) { r.e = inc8(r, r.e); if (!(r.f & C)) r.e = 3; }
  return stickFrom(m);
}
function stickFrom(m) {                  // 8A0E: y part from H, A = stick
  const r = m.r, { ix } = io(m);
  r.a = ix(3);
  cp8(r, r.a, r.h);
  r.a = r.e;
  if (!(r.f & Z)) r.a = r.f & C ? 0x0C : 0x04;
  r.a = or8(r, r.a, r.e);
  if (!bitm(r, 0, ix(-7))) return;
  r.a = r.e;
}

module.exports = {
  procs: { '869C': setup, '86D0': targets, '870E': control, '88F4': attack, '8963': defend, '8A01': stickTo, '8A0E': stickFrom },
};
