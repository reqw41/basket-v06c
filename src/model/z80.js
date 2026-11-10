'use strict';
/**
 * Z80 helpers for the model: ALU with flags exactly as the reference core
 * (vector06js Z80_v06.js) sets them, register pairs, block moves.
 * F = S Z Y H X P N C (bits 7..0); `r` is the machine register file m.r.
 *
 * A procedure leaves F as the last flag-changing Z80 instruction before its
 * exit would (callers still in Z80 may branch on it; SHADOW=1 checks it).
 */
const S = 0x80, Z = 0x40, Y = 0x20, H = 0x10, X = 0x08, P = 0x04, N = 0x02, C = 0x01;
const PAR = new Uint8Array(256);
for (let i = 0; i < 256; i++) { let p = 1; for (let b = i; b; b >>= 1) p ^= b & 1; PAR[i] = p ? P : 0; }
const xy = (v) => v & (X | Y);
const sz = (v) => (v & S) | (v ? 0 : Z);

// ---- 8-bit ALU (return the result; CP returns nothing) ----------------------------
function add8(r, a, b, cy = 0) {
  const s = a + b + cy, v = s & 0xff;
  r.f = sz(v) | xy(v) | (((a & 0x0f) + (b & 0x0f) + cy) & 0x10 ? H : 0)
    | ((a & 0x80) === (b & 0x80) && (a & 0x80) !== (s & 0x80) ? P : 0) | (s & 0x100 ? C : 0);
  return v;
}
const adc8 = (r, a, b) => add8(r, a, b, r.f & C);
function sub8(r, a, b, cy = 0) {
  const s = a - b - cy, v = s & 0xff;
  r.f = sz(v) | xy(v) | N | (((a & 0x0f) - (b & 0x0f) - cy) & 0x10 ? H : 0)
    | ((a & 0x80) !== (b & 0x80) && (a & 0x80) !== (s & 0x80) ? P : 0) | (s & 0x100 ? C : 0);
  return v;
}
const sbc8 = (r, a, b) => sub8(r, a, b, r.f & C);
function cp8(r, a, b) { sub8(r, a, b); r.f = (r.f & ~(X | Y)) | xy(b); }
function and8(r, a, b) { const v = a & b & 0xff; r.f = sz(v) | xy(v) | H | PAR[v]; return v; }
function or8(r, a, b) { const v = (a | b) & 0xff; r.f = sz(v) | xy(v) | PAR[v]; return v; }
function xor8(r, a, b) { const v = (a ^ b) & 0xff; r.f = sz(v) | xy(v) | PAR[v]; return v; }
function inc8(r, v) {
  const s = (v + 1) & 0xff;
  r.f = (r.f & C) | sz(s) | xy(s) | ((v & 0x0f) === 0x0f ? H : 0) | (v === 0x7f ? P : 0);
  return s;
}
function dec8(r, v) {
  const s = (v - 1) & 0xff;
  r.f = (r.f & C) | sz(s) | xy(s) | N | ((v & 0x0f) === 0 ? H : 0) | (v === 0x80 ? P : 0);
  return s;
}
function neg(r, a) {
  const v = (-a) & 0xff;
  r.f = sz(v) | xy(v) | N | ((a & 0x0f) ? H : 0) | (v === 0x80 ? P : 0) | (v ? C : 0);
  return v;
}
function cpl(r, a) { const v = ~a & 0xff; r.f = (r.f & (S | Z | P | C)) | H | N | xy(v); return v; }
function scf(r) { r.f = (r.f & (S | Z | P)) | xy(r.a) | C; }
function ccf(r) { const c = r.f & C; r.f = (r.f & (S | Z | P)) | xy(r.a) | (c ? H : C); }

// ---- shifts and rotates (CB group: full flags) ----------------------------------------
function shf(r, v, c) { r.f = sz(v) | xy(v) | PAR[v] | c; return v; }
const rlc = (r, v) => shf(r, ((v << 1) | (v >> 7)) & 0xff, v >> 7);
const rrc = (r, v) => shf(r, (v >> 1) | ((v & 1) << 7), v & 1);
const rl = (r, v) => shf(r, ((v << 1) | (r.f & C)) & 0xff, v >> 7);
const rr = (r, v) => shf(r, (v >> 1) | ((r.f & C) << 7), v & 1);
const sla = (r, v) => shf(r, (v << 1) & 0xff, v >> 7);
const sra = (r, v) => shf(r, (v >> 1) | (v & 0x80), v & 1);
const srl = (r, v) => shf(r, v >> 1, v & 1);
// accumulator rotates keep S Z P
function acc(r, fn) { const k = r.f & (S | Z | P); r.a = fn(r, r.a); r.f = (r.f & ~(S | Z | P)) | k; }
const rlca = (r) => acc(r, rlc), rrca = (r) => acc(r, rrc), rla = (r) => acc(r, rl), rra = (r) => acc(r, rr);
// BIT n,r (X Y as the core sets them) and BIT n,(ix+d)/(hl) through bitm (X Y kept)
function bit(r, n, v) {
  const z = !(v & (1 << n));
  r.f = (r.f & C) | H | (z ? Z | P : 0) | (n === 7 && !z ? S : 0) | (n === 5 && !z ? Y : 0) | (n === 3 && !z ? X : 0);
  return !z;
}
function bitm(r, n, v) {                 // BIT n,(IX+d)
  const z = !(v & (1 << n));
  r.f = (r.f & (C | X | Y)) | H | (z ? Z | P : 0) | (n === 7 && !z ? S : 0);
  return !z;
}
function bithl(r, n, v) { return bit(r, n, v); }   // BIT n,(HL): the core treats it as a register

// ---- 16-bit ----------------------------------------------------------------------------
function add16(r, x, y) {                // ADD HL/IX/IY,rr: S Z P kept
  const s = x + y;
  r.f = (r.f & (S | Z | P)) | (((x & 0xfff) + (y & 0xfff)) & 0x1000 ? H : 0) | (s & 0x10000 ? C : 0) | xy(s >> 8);
  return s & 0xffff;
}
function adc16(r, x, y) {
  const o = y + (r.f & C), s = x + o, v = s & 0xffff;
  r.f = (s & 0x8000 ? S : 0) | (v ? 0 : Z) | (((x & 0xfff) + (o & 0xfff)) & 0x1000 ? H : 0)
    | ((x & 0x8000) === (o & 0x8000) && (s & 0x8000) !== (x & 0x8000) ? P : 0) | (s & 0x10000 ? C : 0) | xy(v >> 8);
  return v;
}
function sbc16(r, x, y) {
  const o = y + (r.f & C), s = x - o, v = s & 0xffff;
  r.f = (s & 0x8000 ? S : 0) | (v ? 0 : Z) | N | (((x & 0xfff) - (o & 0xfff)) & 0x1000 ? H : 0)
    | ((x & 0x8000) !== (o & 0x8000) && (s & 0x8000) !== (x & 0x8000) ? P : 0) | (s & 0x10000 ? C : 0) | xy(v >> 8);
  return v;
}

// ---- register pairs -----------------------------------------------------------------------
const BC = (r) => r.b << 8 | r.c, DE = (r) => r.d << 8 | r.e, HL = (r) => r.h << 8 | r.l;
function setBC(r, v) { r.b = (v >> 8) & 0xff; r.c = v & 0xff; }
function setDE(r, v) { r.d = (v >> 8) & 0xff; r.e = v & 0xff; }
function setHL(r, v) { r.h = (v >> 8) & 0xff; r.l = v & 0xff; }
function exDEHL(r) { const d = r.d, e = r.e; r.d = r.h; r.e = r.l; r.h = d; r.l = e; }
function exx(r) {
  for (const k of ['b', 'c', 'd', 'e', 'h', 'l']) { const t = r[k]; r[k] = r[k + '_']; r[k + '_'] = t; }
}
function exAF(r) { let t = r.a; r.a = r.a_; r.a_ = t; t = r.f; r.f = r.f_; r.f_ = t; }
const sx = (d) => (d & 0x80 ? d - 0x100 : d);          // signed byte

// LDIR / LDDR (BC > 0 on entry; flags as the core leaves them after the last LDI/LDD)
function ldir(m, dir = 1) {
  const r = m.r;
  let hl = HL(r), de = DE(r), bc = BC(r), v = 0;
  do {
    v = m.rd(hl); m.wr(de, v);
    hl = (hl + dir) & 0xffff; de = (de + dir) & 0xffff; bc = (bc - 1) & 0xffff;
  } while (bc);
  setHL(r, hl); setDE(r, de); setBC(r, 0);
  const t = (r.a + v) & 0xff;
  r.f = (r.f & (S | Z | C)) | (t & 0x02 ? Y : 0) | (t & 0x08 ? X : 0);
}
const lddr = (m) => ldir(m, -1);

module.exports = {
  S, Z, Y, H, X, P, N, C, PAR,
  add8, adc8, sub8, sbc8, cp8, and8, or8, xor8, inc8, dec8, neg, cpl, scf, ccf,
  rlc, rrc, rl, rr, sla, sra, srl, rlca, rrca, rla, rra, bit, bitm, bithl,
  add16, adc16, sbc16, BC, DE, HL, setBC, setDE, setHL, exDEHL, exx, exAF, sx, ldir, lddr,
};
