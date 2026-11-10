'use strict';
/**
 * System block 3300..3F7F (the MSX BIOS-like layer of the original, moved here
 * by the port): start-up, the IRQ handler, screen clear, keys, text output,
 * line input, waits. Platform entry points: 0018 (RST 18 print), 02DE (glyph),
 * 02FC / 031B (fills), 063E / 063F (key scan), 3A4A (delay, a platform wait),
 * 34BD (box).
 *   35C0  start-up: own stack at C000 (the caller's SP kept in 348F), clears,
 *         IRQ hook 4141 = JP 36F3, then 3732
 *   36F3  IRQ: the music hook (3702: CALL (3703)), the clock hook (3705: CALL
 *         (3706)), keys (372C: 063F returns straight to 370B, past 372C)
 *   3732  clear the screen (SMC: C9 at 3732 turns it off), 3758 / 3769 screen on/off
 *   3811  key decode: rows 4104..410E -> G_KEY_CODE 410F, G_KEY_ASCII 4110 (table 3436)
 *   38E8  line input to 4146 (FF-terminated), max (3300) characters
 *   3A2C  wait A x 1/50 s or (A = 0) a key press and release (3A2F)
 *   3B53  print A at TEXT_ROW/COL 4102/4103 (CR, BS, DEL; 341D columns)
 *   A0BF  wipe: 31h steps of A0D0 + A132, one HALT each
 */
const { C, Z, S, add8, sub8, cp8, and8, or8, xor8, inc8, dec8, rlca, rrca, add16, ldir } = require('./z80');

const ROW = 0x4102, COL = 0x4103, INK = 0x3424, KEY_CODE = 0x410F, KEY_ASCII = 0x4110;
const rst18 = (m) => m.pcall(0x0018);

function box3E(m) { m.r.h = 0; m.r.l = 0x3E; return m.jp(0x34BD); }   // 34AF
function box7E(m) { m.r.h = 0; m.r.l = 0x7E; return m.jp(0x34BD); }   // 34BA

function startup(m) {                    // 35C0
  const r = m.r;
  r.iff = 0;
  const ret = m.pop();
  r.h = ret >> 8; r.l = ret & 0xff;
  m.wr16(0x348F, r.sp);
  r.sp = 0xC000;
  m.push(ret);
  r.b = 1;
  r.a = xor8(r, r.a, r.a);               // 3634
  m.wr(0x3489, 0);
  r.a = 0x40; m.wr(0x348D, 0x40);
  r.a = xor8(r, r.a, r.a);               // 3662: no carry
  r.a = m.rd(0x348E); m.wr(0x348A, r.a);
  r.h = 0x41; r.l = 0x11; r.b = 0; r.c = 5;
  m.call(0x37A4);
  m.call(0x3770);
  r.a = 0xC3; m.wr(0x0FF0, 0xC3);
  r.h = 0x3B; r.l = 0x47; m.wr16(0x0FF1, 0x3B47);
  let hl = 0x4000;
  r.b = 0; r.c = 0x41;
  do { m.wr(hl, r.c); hl++; r.b = (r.b - 1) & 0xff; } while (r.b);
  m.wr(hl, r.c);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = 0xC3; m.wr(0x4141, 0xC3);
  r.h = 0x36; r.l = 0xF3; m.wr16(0x4142, 0x36F3);
  r.a = 0x40;
  r.iff = 1;
  return m.jp(0x3732);
}
function zeroA(m) { const r = m.r; r.a = xor8(r, r.a, r.a); }   // 3634 / 3662

function irq(m) {                        // 36F3
  const r = m.r;
  r.iff = 0;
  m.push(r.a << 8 | r.f);
  r.a = and8(r, 0x80, 0x80);             // jp p,3712 is never taken
  m.push(r.b << 8 | r.c); m.push(r.h << 8 | r.l); m.push(r.d << 8 | r.e); m.push(r.ix); m.push(r.iy);
  m.call(m.rd16(0x3703));
  m.call(m.rd16(0x3706));
  m.call(0x372C);
  r.iy = m.pop(); r.ix = m.pop();
  let v = m.pop(); r.d = v >> 8; r.e = v & 0xff;
  v = m.pop(); r.h = v >> 8; r.l = v & 0xff;
  v = m.pop(); r.b = v >> 8; r.c = v & 0xff;
  v = m.pop(); r.a = v >> 8; r.f = v & 0xff;
  r.iff = 1;
}
function noop() {}                       // 3714 / 3760
function keysIrq(m) {                    // 372C
  m.pcall(0x063F);
  return m.jp(0x3811);
}

function cls(m) {                        // 3732
  const r = m.r;
  if (m.rd(0x3732) === 0xC9) return;     // switched off by 84ED
  m.call(0x3769);
  r.h = 0; r.l = 0; m.wr16(ROW, 0);
  r.b = 0x18; r.c = 0; r.a = xor8(r, r.a, r.a);
  m.call(0x377F);
  r.h = 0x20; r.l = 0; r.b = 0x18; r.c = 0; r.a = m.rd(INK);
  m.call(0x377F);
  r.h = 0x18; r.l = 0; r.b = 0x03; r.c = 0; r.a = xor8(r, r.a, r.a);
  m.call(0x3791);
  return screenOn(m);
}
function screenOn(m) {                   // 3758
  const r = m.r;
  r.h = 0x34; r.l = 0x2D;
  m.wr(0x342D, m.rd(0x342D) | 0x40);
  return modeReg(m);
}
function modeReg(m) { const r = m.r; r.b = m.rd(r.h << 8 | r.l); r.c = 1; }   // 375D
function screenOff(m) {                  // 3769
  const r = m.r;
  r.h = 0x34; r.l = 0x2D;
  m.wr(0x342D, m.rd(0x342D) & ~0x40);
  return modeReg(m);
}
function vdpRegs(m) {                    // 3770: B = (3433..342C), C = 7..0 (no writes on this port)
  const r = m.r;
  let hl = 0x3433;
  r.c = 7;
  for (;;) {
    r.b = m.rd(hl);
    hl--;
    r.c = dec8(r, r.c);
    if (r.f & S) break;
  }
  r.h = hl >> 8; r.l = hl & 0xff;
}
function fill(m) {                       // 377F: not the pattern table when 0FEE says so
  const r = m.r;
  const af = r.a << 8 | r.f;
  r.a = or8(r, r.h, r.l);
  let skip = false;
  if (!r.a) { r.a = or8(r, m.rd(0x0FEE), m.rd(0x0FEE)); if (r.a) skip = true; }
  r.a = af >> 8; r.f = af & 0xff;
  if (skip) return;
  return m.jp(0x02FC);
}
function clear(m) {                      // 37A4: HL..HL+BC-1 = 0
  const r = m.r;
  m.wr(r.h << 8 | r.l, 0);
  let de = ((r.h << 8 | r.l) + 1) & 0xffff;
  r.d = de >> 8; r.e = de & 0xff;
  const bc = ((r.b << 8 | r.c) - 1) & 0xffff;
  r.b = bc >> 8; r.c = bc & 0xff;
  ldir(m);
}
function paper(m) {                      // 37BD: ink high nibble = A
  const r = m.r;
  rlca(r); rlca(r); rlca(r); rlca(r);
  r.b = r.a;
  r.a = or8(r, and8(r, m.rd(INK), 0x0F), r.b);
  m.wr(INK, r.a);
}
function scan(m) {                       // 37CC
  m.r.iff = 0;
  m.call(0x37D2);
  m.r.iff = 1;
}

function keys(m) {                       // 3811
  const r = m.r;
  let hl = 0x4104;
  r.b = 0x0B;
  do {
    r.a = m.rd(hl);
    cp8(r, r.a, 0xFF);
    if (r.a !== 0xFF) {
      r.c = 0;
      for (;;) { rrca(r); if (!(r.f & C)) break; r.c = inc8(r, r.c); }
      r.a = sub8(r, 0x0B, r.b);
      rlca(r); rlca(r); rlca(r);
      r.a = add8(r, r.a, r.c);
      m.wr(KEY_CODE, r.a);
      r.e = r.a; r.d = 0;
      hl = add16(r, m.rd16(0x3436), r.e);
      r.h = hl >> 8; r.l = hl & 0xff;
      r.a = m.rd(hl);
      cp8(r, r.a, 5);
      if (r.a === 5) throw new Error('key 05 (36D7) is not modelled');
      m.wr(KEY_ASCII, r.a);
      return;
    }
    hl++;
    r.b = (r.b - 1) & 0xff;
  } while (r.b);
  r.h = hl >> 8; r.l = hl & 0xff;
  m.wr(KEY_CODE, r.a);
  m.wr(KEY_ASCII, r.a);
}

function lineInput(m) {                  // 38E8
  const r = m.r;
  r.b = 0; r.c = 0;
  r.a = m.rd(0x3300);
  r.d = 0x39; r.e = 0x24;
  m.wr(0x411E, r.a);
  m.wr(0x411F, 0); m.wr(0x4120, 0);
  r.d = 0x41; r.e = 0x46;
  r.b = 0;
  let to = 0x3901;
  for (;;) {
    if (to === 0x3901) {
      r.a = 0x5F; rst18(m);
      r.a = 0x08; rst18(m);
      r.a = 0xFF; m.wr(r.d << 8 | r.e, 0xFF);
    }
    m.call(0x3A2F);                      // 390A
    cp8(r, r.a, 0x0D);
    if (r.a === 0x0D) break;
    cp8(r, r.a, 0x10);
    if (r.a === 0x10) {                  // 397A: delete
      r.a = or8(r, r.b, r.b);
      if (r.a) {
        let de = ((r.d << 8 | r.e) - 1) & 0xffff;
        r.d = de >> 8; r.e = de & 0xff;
        r.b = dec8(r, r.b);
        r.a = 0x20; rst18(m);
        r.a = 0x08; rst18(m);
        r.a = 0x10; rst18(m);
      }
      to = 0x3901;
      continue;
    }
    cp8(r, r.a, 0x20);
    if (r.f & C) { to = 0x390A; continue; }
    cp8(r, r.a, 0x5B);
    if (!(r.f & C)) { to = 0x390A; continue; }
    rst18(m);                            // 3924
    let de = r.d << 8 | r.e;
    m.wr(de, r.a); de = (de + 1) & 0xffff;
    r.d = de >> 8; r.e = de & 0xff;
    r.a = 0xFF; m.wr(de, 0xFF);
    r.b = inc8(r, r.b);
    r.a = r.b;
    r.h = 0x41; r.l = 0x1E;
    cp8(r, r.a, m.rd(0x411E));
    if (r.f & C) { to = 0x3901; continue; }
    m.wr(0x4123, r.a);
    break;
  }
  r.a = 0x20; rst18(m);                  // 3935
  r.a = or8(r, m.rd(0x411F), m.rd(0x411F));
  if (r.a) throw new Error('numeric input (3943) is not modelled');
  r.a = r.b;
  m.wr(0x3300, r.a);
}

function wait(m) {                       // 3A2C
  const r = m.r;
  r.a = or8(r, r.a, r.a);
  if (r.a) return m.jp(0x3A4A);
  return keyWait(m);
}
function keyWait(m) {                    // 3A2F
  const r = m.r;
  m.push(r.h << 8 | r.l); m.push(r.b << 8 | r.c); m.push(r.d << 8 | r.e);
  do { m.call(0x3A56); r.a = m.rd(KEY_ASCII); cp8(r, r.a, 0xFF); } while (r.a !== 0xFF);
  do { m.call(0x3A56); r.a = m.rd(KEY_ASCII); cp8(r, r.a, 0xFF); } while (r.a === 0xFF);
  let v = m.pop(); r.d = v >> 8; r.e = v & 0xff;
  v = m.pop(); r.b = v >> 8; r.c = v & 0xff;
  v = m.pop(); r.h = v >> 8; r.l = v & 0xff;
}
function frameKeys(m) {                  // 3A56
  m.r.a = 5;
  m.pcall(0x3A4A);
  m.call(0x37CC);
  return m.jp(0x3811);
}

function print(m) {                      // 3B53
  const r = m.r;
  cp8(r, r.a, 0x20);
  if (r.f & C) {
    cp8(r, r.a, 0x0D); if (r.a === 0x0D) return newLine(m);
    cp8(r, r.a, 0x08); if (r.a === 0x08) return back(m);
    cp8(r, r.a, 0x09); if (r.a === 0x09) throw new Error('TAB (3BFE) is not modelled');
    cp8(r, r.a, 0x10); if (r.a === 0x10) { m.call(0x3BE1); r.a = 0x20; m.call(0x3B53); return back(m); }
  }
  let hl = r.a;                          // 3B6B
  r.h = 0; r.l = r.a;
  hl = add16(r, hl, hl); hl = add16(r, hl, hl); hl = add16(r, hl, hl);
  const de = m.rd16(0x3434);
  r.d = de >> 8; r.e = de & 0xff;
  hl = add16(r, hl, de);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = or8(r, m.rd(0x341C), m.rd(0x341C));
  if (r.a) throw new Error('bitmap text (3B9D) is not modelled');
  m.pcall(0x02DE);
  r.a = inc8(r, m.rd(COL));              // 3BC2
  r.h = 0x34; r.l = 0x1D;
  cp8(r, r.a, m.rd(0x341D));
  if (r.f & C) return setCol(m);
  return newLine(m);
}
function newLine(m) {                    // 3BCC
  const r = m.r;
  r.a = xor8(r, r.a, r.a);
  m.wr(COL, 0);
  r.a = inc8(r, m.rd(ROW));
  cp8(r, r.a, 0x18);
  if (!(r.f & C)) r.a = xor8(r, r.a, r.a);
  return setRow(m);
}
function setRow(m) { m.wr(ROW, m.r.a); }   // 3BD9
function setCol(m) { m.wr(COL, m.r.a); }   // 3BDD
function back(m) {                       // 3BE1
  const r = m.r;
  r.a = or8(r, m.rd(COL), m.rd(COL));
  if (r.a) { r.a = dec8(r, r.a); return setCol(m); }
  r.a = dec8(r, m.rd(0x341D));
  m.wr(COL, r.a);
  r.a = or8(r, m.rd(ROW), m.rd(ROW));
  if (r.a) { r.a = dec8(r, r.a); return setRow(m); }
  r.a = 0x17;
  return setRow(m);
}

function wipe(m) {                       // A0BF
  const r = m.r;
  r.ix = 0x3314;
  r.c = 0x31;
  do {
    m.pcall(0xA0D0);
    m.pcall(0xA132);
    m.halt(0xA0CB);
    r.c = dec8(r, r.c);
  } while (r.c);
}

module.exports = {
  procs: {
    '34AF': box3E, '34BA': box7E, '35C0': startup, '3634': zeroA, '3662': zeroA, '36F3': irq, '3714': noop,
    '372C': keysIrq, '3732': cls, '3758': screenOn, '375D': modeReg, '3760': noop, '3769': screenOff,
    '3770': vdpRegs, '377F': fill, '37A4': clear, '37BD': paper, '37CC': scan, '3811': keys,
    '38E8': lineInput, '3A2C': wait, '3A2F': keyWait, '3A56': frameKeys, '3B53': print,
    '3BCC': newLine, '3BD9': setRow, '3BDD': setCol, '3BE1': back, 'A0BF': wipe,
  },
};
