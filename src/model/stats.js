'use strict';
/**
 * End of the match: statistics screen and the result banner, A1AA..A547.
 *   A1AA  screen: titles, names, wipe (A0BF), the walk-in (A419), two stat
 *         columns (A25D), then the result banner (A232) until a key
 *   A232  banner: winner by fouls (93E5 bit 7) blinks, else the end tune (3A2C, 5)
 *   A25D  one player's column: shots, 3-pointers, fouls, free throws ... (ix+0B..12)
 *   A32C / A337  B dots / spaces; A341 percentage C of B (398C / 39A3)
 *   A419  the walk-in of both players, A472 redraw with HL/DE/IX kept, A4E7 one frame
 *   A502  crowd: on tick 4 a random spectator cheers (A521, platform)
 *   A53A  set up the controls screen (3433, ink) and go to AC44
 */
const { C, Z, add8, sub8, cp8, and8, xor8, inc8, dec8, bit } = require('./z80');

const INK = 0x3424;
const text = (m, h, l) => { m.r.h = h; m.r.l = l; m.call(0xA01F); };
const putc = (m, a) => { m.r.a = a; m.call(0xA063); };

function statsScreen(m) {                // A1AA
  const r = m.r;
  r.a = m.rd(0x93E5);
  if (bit(r, 7, r.a)) {
    r.d = 0xA3; r.e = 0x7B;
    text(m, 0x08, 0x06);
    r.l = inc8(r, r.l);
  } else {
    r.h = 0x0B; r.l = 0x07; r.d = 0xA3; r.e = 0xBF;
  }
  m.call(0xA01F); r.l = inc8(r, r.l);
  m.call(0xA01F); r.l = inc8(r, r.l);
  m.call(0xA01F);
  m.call(0xA9AD);
  r.a = xor8(r, r.a, r.a);
  m.wr(0x0FEF, 0);
  m.call(0xA00E);
  m.call(0xA0BF);
  r.h = 0x7E; r.l = 0xF9;
  m.wr16(0x3300, 0x7EF9);
  m.call(0xAA7C);
  m.call(0xA419);
  r.h = 0x01; r.l = 0x10; r.b = 0x05; r.c = 0x28; r.a = 0x17;
  m.call(0xA75F);
  r.ix = 0x940B; r.h = 0x06; r.l = 0x02;
  m.call(0xA25D);
  r.h = 0x1A; r.l = 0x48; r.b = 0x05; r.c = 0x28; r.a = 0x17;
  m.call(0xA75F);
  r.ix = 0x9425; r.h = 0x01; r.l = 0x09;
  m.call(0xA25D);
  r.a = 0xFF; m.wr(0x9451, 0xFF);
  do {
    m.call(0xA472);
    m.call(0xA232);
    m.call(0x37CC);
    m.call(0x3811);
    r.a = inc8(r, m.rd(0x4110));
  } while (!r.a);
}

function banner(m) {                     // A232
  const r = m.r;
  r.a = m.rd(0x93E5);
  if (!bit(r, 7, r.a)) { r.a = 5; return m.jp(0x3A2C); }
  r.a = and8(r, inc8(r, m.rd(0x9451)), 0x0F);
  m.wr(0x9451, r.a);
  m.call(0x37BD);
  r.d = 0xA3; r.e = 0x62;
  r.h = 0x07; r.l = 0x03;
  r.a = m.rd(0x9400);
  if (bit(r, 7, r.a)) { r.h = 0x02; r.l = 0x0A; }
  return m.jp(0xA01F);
}

function column(m) {                     // A25D
  const r = m.r, ix = (d) => m.rd((r.ix + d) & 0xffff);
  const ink = () => { r.a = 0xF1; m.wr(INK, 0xF1); };
  const ratio = (made, att) => {         // "att/made pct%"
    ink();
    r.a = ix(att); m.call(0xA02C);
    putc(m, 0x2F);
    r.a = ix(made); m.call(0xA02C);
    putc(m, 0x20);
    r.c = ix(made); r.b = ix(att);
  };
  const line = (dots) => {
    m.call(0xA472);
    r.l = inc8(r, r.l);
    m.call(0xA01F);
    r.b = dots; m.call(0xA32C);
  };
  m.call(0xA472);
  ink();
  r.d = 0xA3; r.e = 0xE3;
  m.call(0xA01F);
  r.b = 6; m.call(0xA32C);
  ratio(0x0C, 0x0D);
  m.call(0xA341);
  line(7);
  ink(); r.a = ix(0x0B); m.call(0xA02C);
  r.b = 5; m.call(0xA337);
  line(2);
  ratio(0x0E, 0x0F);
  m.call(0xA341);
  line(0x0A);
  ink(); r.a = ix(0x10); m.call(0xA02C);
  r.b = 5; m.call(0xA337);
  line(7);
  ratio(0x11, 0x12);
  return m.jp(0xA341);
}

function dots(m) {                       // A32C
  const r = m.r;
  r.a = 0x71; m.wr(INK, 0x71);
  r.a = 0x2E;
  return fill(m);
}
function spaces(m) { m.r.a = 0x20; return fill(m); }   // A337
function fill(m) {                       // A339: B times A
  const r = m.r;
  do {
    const af = r.a << 8 | r.f;
    m.push(af);
    m.call(0xA063);
    const v = m.pop(); r.a = v >> 8; r.f = v & 0xff;
    r.b = (r.b - 1) & 0xff;
  } while (r.b);
}

function percent(m) {                    // A341: C made of B
  const r = m.r;
  m.push(r.h << 8 | r.l); m.push(r.d << 8 | r.e);
  r.e = r.c; r.l = r.b;
  r.b = 0; r.c = 0x64;
  r.a = and8(r, r.e, r.e);
  if (r.a) {
    r.d = 0; r.h = 0;
    m.call(0x398C);
    r.c = r.e; r.b = r.d;
    m.call(0x39A3);
    r.a = r.l;
  }
  m.call(0xA03B);
  putc(m, 0x25);
  let v = m.pop(); r.d = v >> 8; r.e = v & 0xff;
  v = m.pop(); r.h = v >> 8; r.l = v & 0xff;
}

function walkIn(m) {                     // A419
  const r = m.r;
  m.wr16(0x940D, 0x7E2C); m.wr16(0x9427, 0xF864);
  r.h = 0xF8; r.l = 0x64;
  r.a = 0x10; m.wr(0x940B, 0x10); m.wr(0x9425, 0x10);
  m.wr16(0x9409, 0x0404);
  r.h = 0x0C; r.l = 0x0C;
  m.wr16(0x9423, 0x0C0C);
  do {
    m.call(0xA4E7);
    r.a = dec8(r, dec8(r, m.rd(0x940E))); m.wr(0x940E, r.a);
    r.a = inc8(r, inc8(r, m.rd(0x9428))); m.wr(0x9428, r.a);
    cp8(r, r.a, 0x6E);
  } while (r.a !== 0x6E);
  r.a = 3; m.wr(0x940A, 3); m.wr(0x9424, 3);
  m.call(0xA4E7);
  r.a = 0x0C; m.wr(0x940A, 0x0C);
  r.a = 4; m.wr(0x9424, 4);
  m.call(0xA4E7);
  r.a = xor8(r, r.a, r.a);
  m.wr(0x9409, 0); m.wr(0x9423, 0);
  return walkFrame(m);
}

function redraw(m) {                     // A472
  const r = m.r;
  m.push(r.h << 8 | r.l); m.push(r.d << 8 | r.e); m.push(r.ix);
  m.call(0xA4A8);
  r.d = 0x01; r.e = 0x01;
  r.d = 0x08; r.e = 0x1A;                // A493 is an empty stub
  m.call(0x9599);
  m.call(0x958F);
  m.call(0xB1FE);
  r.ix = m.pop();
  let v = m.pop(); r.d = v >> 8; r.e = v & 0xff;
  v = m.pop(); r.h = v >> 8; r.l = v & 0xff;
}

function walkFrame(m) {                  // A4E7
  const r = m.r;
  m.call(0x9599);
  m.call(0x958F);
  m.call(0xB1FE);
  r.a = xor8(r, r.a, r.a);
  m.wr(0x0FEF, 0);
  r.a = 5;
  return m.jp(0x3A2C);
}

function crowd(m) {                      // A502
  const r = m.r;
  m.pcall(0x74BA);
  r.a = and8(r, r.a, 0x0F);
  cp8(r, r.a, 4);
  if (r.a !== 4) return;
  r.a = m.rd(0x9451);
  if (bit(r, 0, r.a)) return;
  m.call(0xA17B);
  r.ix = (r.ix & 0xff00) | r.a;
  r.h = 0x01; r.l = 0x05;
  m.pcall(0xA521);
  r.h = 0x01; r.l = 0x10;
  return m.jp(0xA521);
}

function controlsScreen(m) {             // A53A
  const r = m.r;
  r.a = 1; m.wr(0x3433, 1);
  r.a = 0xF1; m.wr(INK, 0xF1);
  return m.jp(0xAC44);
}

module.exports = {
  procs: {
    'A1AA': statsScreen, 'A232': banner, 'A25D': column, 'A32C': dots, 'A337': spaces, 'A339': fill,
    'A341': percent, 'A419': walkIn, 'A472': redraw, 'A4E7': walkFrame, 'A502': crowd, 'A53A': controlsScreen,
  },
};
