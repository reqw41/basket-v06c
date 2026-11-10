'use strict';
/**
 * Game RNG and the IRQ clocks (system block of the port).
 *   386E  RNG: x = (x * 41) & 7FFF at 4114 (HL = x, A = low byte; DE kept)
 *   A186  IRQ seed bump outside a match (0FED <> 1): 4114 += 1 (port, rng_patch)
 *   3715  frame counter 4111 += 1 (carry into 4113), then A186
 */
const { add16, dec8, inc8, or8 } = require('./z80');

const SEED = 0x4114, FRAMES = 0x4111, CARRY = 0x4113, MATCH_MODE = 0x0FED;

function rng(m) {
  const r = m.r;
  const x = m.rd16(SEED);
  let hl = add16(r, x, x);              // add hl,hl
  hl = add16(r, hl, hl);                // add hl,hl
  hl = add16(r, hl, x);                 // add hl,de
  hl = add16(r, hl, hl);
  hl = add16(r, hl, hl);
  hl = add16(r, hl, hl);
  hl = add16(r, hl, x);
  hl &= 0x7fff;                         // res 7,h
  m.wr16(SEED, hl);
  r.h = hl >> 8; r.l = hl & 0xff; r.a = r.l;
}

function seedBump(m) {
  const r = m.r;
  r.a = dec8(r, m.rd(MATCH_MODE));      // ld a,(0FED) / dec a
  if (r.a === 0) return;                // ret z
  const hl = (m.rd16(SEED) + 1) & 0xffff;   // inc hl: no flags
  m.wr16(SEED, hl);
  r.h = hl >> 8; r.l = hl & 0xff;
}

function frameTick(m) {
  const r = m.r;
  const hl = (m.rd16(FRAMES) + 1) & 0xffff;   // ld hl,(4111) / inc hl / ld (4111),hl
  m.wr16(FRAMES, hl);
  r.h = hl >> 8; r.l = hl & 0xff;
  r.a = or8(r, r.h, r.l);                    // ld a,h / or l
  if (!r.a) {                                // jr nz: wrapped, inc (4113)
    r.h = 0x41; r.l = 0x13;
    m.wr(CARRY, inc8(r, m.rd(CARRY)));
  }
  seedBump(m);                               // jp A186 (its RET is ours)
}

module.exports = { procs: { '386E': rng, 'A186': seedBump, '3715': frameTick } };
