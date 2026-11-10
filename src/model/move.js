'use strict';
/**
 * Pushing, events and steering, 98B3..9A1A.
 *   98B3  push the other player (iy) by the stick direction of ix (pose ix-1)
 *   98D9  bump: when the two players overlap (|dy| < 6, |dx| < 3) push iy by B/C
 *   98F7  move iy by (C, B) and raise event E = 2 (foul) via 9919
 *   9919  event: 9400 = E (bit 7 = ix side), 9451 = 14h; a foul counts in ix+0B
 *         (up to 5) and is printed (9FC0)
 *   994A  stick to pose (ix-1) from the control bits (ix-2)
 *   99BC  shot value: 93D9 = 3 outside the arc, 2 inside, 1 on a restart
 */
const { io } = require('./ent');
const { C, Z, add8, sub8, cp8, and8, inc8, neg, bit, bitm } = require('./z80');

function pushOther(m) {                  // 98B3
  const r = m.r, { ix, iy } = io(m);
  r.e = iy(2); r.d = iy(3);
  r.b = 0; r.c = 0;
  r.a = ix(-1);
  if (bit(r, 0, r.a)) { r.c = 0xFE; if (bit(r, 1, r.a)) r.c = 2; }
  if (bit(r, 2, r.a)) { r.b = 0xFF; if (bit(r, 3, r.a)) r.b = 1; }
  return moveOther(m);
}

function bump(m) {                       // 98D9
  const r = m.r, { ix, iy } = io(m);
  r.l = ix(2); r.h = ix(3); r.e = iy(2); r.d = iy(3);
  r.a = sub8(r, r.h, r.d);
  if (r.f & C) r.a = neg(r, r.a);
  cp8(r, r.a, 6);
  if (!(r.f & C)) return;
  r.a = sub8(r, r.l, r.e);
  if (r.f & C) r.a = neg(r, r.a);
  cp8(r, r.a, 3);
  if (!(r.f & C)) return;
  return moveOther(m);
}

function moveOther(m) {                  // 98F7
  const r = m.r, { iy, wy } = io(m);
  r.a = add8(r, r.e, r.c); wy(2, r.a);
  r.a = add8(r, r.d, r.b); wy(3, r.a); wy(5, r.a);
  r.e = 2;
  if (!bitm(r, 0, iy(0))) {
    r.a = and8(r, iy(-2), 0x1F);
    if (!r.a) { r.a = iy(-1); wy(-2, r.a); }
  }
  return event(m);
}

function event(m) {                      // 9919
  const r = m.r, { ix, wx } = io(m);
  r.a = and8(r, m.rd(0x9400), m.rd(0x9400));
  if (r.a) return;
  if (bitm(r, 0, ix(1))) r.e |= 0x80;
  r.a = r.e; m.wr(0x9400, r.a);
  m.wr(0x9451, 0x14);
  r.a = r.e & 0x7F;
  cp8(r, r.a, 2);
  if (r.a !== 2) return;
  r.a = ix(0x0B);
  cp8(r, r.a, 5);
  if (r.a === 5) return;
  wx(0x0B, inc8(r, ix(0x0B)));
  m.push(r.ix); m.push(r.iy);
  m.call(0x9FC0);
  r.iy = m.pop(); r.ix = m.pop();
}

function steer(m) {                      // 994A
  const r = m.r, { ix, wx, rx } = io(m);
  if (bitm(r, 3, ix(1)) || bitm(r, 1, ix(1)) || bitm(r, 2, ix(1))) return;
  const a = r.a = and8(r, ix(-2), 0x0F);
  if (!a) return;
  const c = r.c = ix(-1);
  let to;
  if (bit(r, 2, a)) {
    if (bit(r, 0, c)) to = bit(r, 3, a) ? 0x999D : 0x99AE;
    else if (bit(r, 3, a)) { if (bit(r, 3, c)) return; to = 0x9983; } else { if (!bit(r, 3, c)) return; to = 0x9977; }
  } else if (bit(r, 2, c)) to = bit(r, 1, a) ? 0x9977 : 0x9983;
  else if (bit(r, 1, a)) { if (bit(r, 1, c)) return; to = 0x99AE; } else { if (!bit(r, 1, c)) return; to = 0x999D; }
  switch (to) {
    case 0x9977: wx(-1, 3); rx(0, 6); return;
    case 0x9983: wx(-1, 1); rx(0, 6); return;
    case 0x999D: wx(-1, 0x0C); if (bitm(r, 0, ix(1))) rx(0, 6); return;
    default: wx(-1, 4); if (!bitm(r, 0, ix(1))) rx(0, 6);
  }
}

function shotValue(m) {                  // 99BC
  const r = m.r, { ix } = io(m);
  r.a = m.rd(0x93D6);
  r.c = 1;
  and8(r, r.a, r.a);
  const lt = (v) => { cp8(r, r.a, v); return !!(r.f & C); };
  const two = (() => {                   // true: res 0,c (inside the arc)
    if (r.a) return false;
    r.c = 3;
    r.a = ix(2);
    if (lt(0x48) || !lt(0x66)) return false;
    r.a = ix(3);
    if (bitm(r, 0, ix(1))) {
      if (lt(0x52)) return false;
      if (!lt(0x58)) return true;
      r.a = ix(2);
      if (!lt(0x4C)) return lt(0x5E);
      r.a = ix(3);
      return !lt(0x56);
    }
    if (!lt(0x24)) return false;
    if (lt(0x1E)) return true;
    r.a = ix(2);
    if (!lt(0x4C)) return lt(0x5E);
    r.a = ix(3);
    return lt(0x22);
  })();
  if (two) r.c &= ~1;
  r.a = r.c;
  m.wr(0x93D9, r.a);
}

module.exports = {
  procs: { '98B3': pushOther, '98D9': bump, '98F7': moveOther, '9919': event, '994A': steer, '99BC': shotValue },
};
