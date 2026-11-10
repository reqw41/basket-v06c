'use strict';
/** Entity field access for the model: ix/iy-relative bytes and bits. */
function io(m) {
  const r = m.r;
  const at = (base, d) => (base + d) & 0xffff;
  return {
    ix: (d) => m.rd(at(r.ix, d)), iy: (d) => m.rd(at(r.iy, d)),
    wx: (d, v) => m.wr(at(r.ix, d), v), wy: (d, v) => m.wr(at(r.iy, d), v),
    sx: (d, b) => m.wr(at(r.ix, d), m.rd(at(r.ix, d)) | (1 << b)),
    rx: (d, b) => m.wr(at(r.ix, d), m.rd(at(r.ix, d)) & ~(1 << b)),
    sy: (d, b) => m.wr(at(r.iy, d), m.rd(at(r.iy, d)) | (1 << b)),
    ry: (d, b) => m.wr(at(r.iy, d), m.rd(at(r.iy, d)) & ~(1 << b)),
  };
}
const HLv = (r) => r.h << 8 | r.l;
function setHL(r, v) { r.h = (v >> 8) & 0xff; r.l = v & 0xff; }
module.exports = { io, HLv, setHL };
