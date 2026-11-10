'use strict';
/**
 * A1 replay machine: the game logic between the platform events of a golden,
 * run partly on a bare Z80 core (code not modelled yet) and partly by the JS
 * model (src/model/, procedures keyed by their Z80 entry address).
 *
 *   const { Machine } = require('./machine');
 *   new Machine(trace, { procs, oracle }).run()   // throws Mismatch on a difference
 *
 * Registers are one file `m.r` shared by the core and the model:
 *   a f b c d e h l  a_ f_ b_ c_ d_ e_ h_ l_  ix iy sp pc iff
 * A JS procedure `fn(m)` is entered as if CALLed (its return address is on
 * the Z80 stack); it returns normally (the machine pops the address) or
 * returns {pc, sp} to continue elsewhere. Inside it uses m.rd/m.wr/m.rd16/
 * m.wr16 for memory, m.call(addr) for another game procedure (JS or Z80),
 * m.platform(addr) for a platform call (checked against the golden; returns
 * the pc the platform came back to), m.mark(pc) at the main-loop mark.
 *
 * Compared at every game -> platform event: pc, registers (F/F' only with
 * {oracle: true}), every byte written since the previous event and every byte
 * of the golden diff. With JS procedures the stack BC00..BFFF is not compared
 * (the model does not keep Z80 return addresses and pushes).
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '../..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const TRACE_TOP = 0xC000, STACK_LO = 0xBC00;
const SHADOW = !!process.env.SHADOW;
const SENTINEL = 0xFFFF;                  // return address of m.call into Z80 code
const hx = (v, n = 4) => (v ?? -1).toString(16).toUpperCase().padStart(n, '0');

const RX = /^\t(\w+)\s*([^;]*?)\s*;\s*([0-9A-F]{4})\s+((?:[0-9A-F]{2}\s?)+)/;
const isGame = new Uint8Array(0x10000);
for (const line of fs.readFileSync(path.join(ROOT, 'disasm/v06/game.asm'), 'utf8').split('\n')) {
  const m = RX.exec(line);
  if (m && !['db', 'dw', 'ds'].includes(m[1])) isGame[parseInt(m[3], 16)] = 1;
}
for (const k of Object.keys(JSON.parse(fs.readFileSync(path.join(ROOT, 'cfg/native_waits.json'), 'utf8')))) {
  const [lo, hi] = k.split('-').map((h) => parseInt(h, 16));
  for (let a = lo; a <= hi; a++) isGame[a] = 0;
}

const REGS = ['a', 'f', 'b', 'c', 'd', 'e', 'h', 'l', 'a_', 'f_', 'b_', 'c_', 'd_', 'e_', 'h_', 'l_', 'ix', 'iy', 'sp', 'iff'];

class Mismatch extends Error {}
class Unwind { constructor(sp, pc) { this.sp = sp; this.pc = pc; } }
class Done extends Error {}

class Machine {
  constructor(tr, { procs = {}, oracle = false, stats = null, free = false } = {}) {
    // free: no golden; every platform call is logged and returns at once (RET)
    this.free = free; this.log = [];
    this.tr = tr;
    this.ev = tr.ev;
    this.i = 0;
    this.mem = new Uint8Array(0x10000);
    this.mem.set(Buffer.from(tr.mem0, 'base64'), 0);
    this.gold = this.mem.slice(0, TRACE_TOP);
    this.procs = procs;
    this.oracle = oracle;
    this.cmpTop = Object.keys(procs).length ? STACK_LO : TRACE_TOP;
    this.marks = new Set((tr.scenario.marks || ['8554']).map((h) => parseInt(h, 16)));
    this.written = [];
    this.r = { pc: 0 };
    this.steps = 0; this.segs = 0;
    this.stats = stats;                    // {addr: calls} of JS procedures
    const Z80 = require(path.join(V06, 'Z80_v06.js'));
    const mem = this.mem, written = this.written;
    this.cpu = Z80({
      mem_read: (a) => mem[a & 0xffff],
      mem_write: (a, v) => { a &= 0xffff; mem[a] = v & 0xff; written.push(a); },
      io_read: (p) => { throw new Mismatch(`logic reads port ${hx(p & 0xff, 2)} at ${hx(this.cpu.pc)}`); },
      io_write: (p) => { throw new Mismatch(`logic writes port ${hx(p & 0xff, 2)} at ${hx(this.cpu.pc)}`); },
    });
  }

  // ---- memory for the model --------------------------------------------------
  rd(a) { return this.mem[a & 0xffff]; }
  rd16(a) { return this.mem[a & 0xffff] | this.mem[(a + 1) & 0xffff] << 8; }
  wr(a, v) { a &= 0xffff; this.mem[a] = v & 0xff; this.written.push(a); }
  wr16(a, v) { this.wr(a, v); this.wr(a + 1, v >> 8); }
  push(v) { this.r.sp = (this.r.sp - 2) & 0xffff; this.wr16(this.r.sp, v); }
  pop() { const v = this.rd16(this.r.sp); this.r.sp = (this.r.sp + 2) & 0xffff; return v; }

  // ---- register file <-> core --------------------------------------------------
  toCore() {
    const r = this.r, st = this.cpu.getState();
    const fl = (f) => ({ S: f >> 7 & 1, Z: f >> 6 & 1, Y: f >> 5 & 1, H: f >> 4 & 1, X: f >> 3 & 1, P: f >> 2 & 1, N: f >> 1 & 1, C: f & 1 });
    Object.assign(st, { a: r.a, flags: fl(r.f), b: r.b, c: r.c, d: r.d, e: r.e, h: r.h, l: r.l,
      a_prime: r.a_, flags_prime: fl(r.f_), b_prime: r.b_, c_prime: r.c_, d_prime: r.d_, e_prime: r.e_, h_prime: r.h_, l_prime: r.l_,
      ix: r.ix, iy: r.iy, sp: r.sp, pc: r.pc, iff1: r.iff, iff2: r.iff, halted: false, imode: 1, do_delayed_di: false, do_delayed_ei: false });
    this.cpu.setState(st);
  }
  fromCore() {
    const s = this.cpu.getState(), r = this.r;
    const F = (f) => f.S << 7 | f.Z << 6 | f.Y << 5 | f.H << 4 | f.X << 3 | f.P << 2 | f.N << 1 | f.C;
    Object.assign(r, { a: s.a, f: F(s.flags), b: s.b, c: s.c, d: s.d, e: s.e, h: s.h, l: s.l,
      a_: s.a_prime, f_: F(s.flags_prime), b_: s.b_prime, c_: s.c_prime, d_: s.d_prime, e_: s.e_prime, h_: s.h_prime, l_: s.l_prime,
      ix: s.ix, iy: s.iy, sp: s.sp, pc: s.pc, iff: s.iff1 });
  }
  setRegs(pc, v) { REGS.forEach((n, j) => { this.r[n] = v[j]; }); this.r.pc = pc; }

  // ---- events --------------------------------------------------------------------
  where() { return `event ${this.i} ${this.ev[this.i] ? this.ev[this.i][0] + ' ' + hx(this.ev[this.i][1]) : 'end'}`; }
  next() { if (this.i >= this.ev.length) throw new Done(); return this.ev[this.i]; }
  apply(d, toMem) {
    for (let k = 0; k < d.length; k += 2) { this.gold[d[k]] = d[k + 1]; if (toMem) this.mem[d[k]] = d[k + 1]; }
  }
  // the logic arrived at a game -> platform event (kind O/L/M) at pc
  check(kind, pc, from) {
    const e = this.next();
    const [k, epc, regs, d, efrom] = e;
    if (k !== kind || epc !== pc) {
      throw new Mismatch(`${this.where()} (from ${hx(efrom)}): model ${kind} at ${hx(pc)} (from ${hx(from)})`);
    }
    const bad = [];
    REGS.forEach((n, j) => {
      if ((n === 'f' || n === 'f_') && !this.oracle) return;
      if (n === 'iff') return;
      if (this.r[n] !== regs[j]) bad.push(`${n} ${hx(this.r[n], 2)}/${hx(regs[j], 2)}`);
    });
    if (bad.length) throw new Mismatch(`${this.where()} (from ${hx(efrom)}): registers model/golden ${bad.join(' ')}`);
    this.apply(d, false);
    const top = this.cmpTop;
    const cmp = (a) => {
      if (a < top && this.mem[a] !== this.gold[a]) {
        throw new Mismatch(`${this.where()} (from ${hx(efrom)}): byte ${hx(a)} model ${hx(this.mem[a], 2)} golden ${hx(this.gold[a], 2)}`);
      }
    };
    for (const a of this.written) cmp(a);
    for (let j = 0; j < d.length; j += 2) cmp(d[j]);
    this.written.length = 0;
    this.i++;
    this.segs++;
  }

  // a platform call (game -> platform 'O' at target): verify it, then play the
  // platform's events up to its return 'R' (nested game entries run here);
  // returns the pc the platform came back to (registers are the golden's)
  platform(target, from) {
    if (this.free) {
      this.log.push([target, REGS.map((n) => this.r[n])]);
      this.r.pc = this.pop();
      return this.r.pc;
    }
    this.r.pc = target;
    // the return address the platform's RET will take is the model's own (a
    // JS caller pushes SENTINEL where the Z80 had its return address)
    this.check('O', target, from);
    for (;;) {
      const [k, pc, regs, d] = this.next();
      if (k === 'E') {                      // the platform enters game code
        this.apply(d, true); this.written.length = 0;
        this.setRegs(pc, regs); this.i++;
        // an ISR that woke a HALT returns into game code: that ends the call
        if (this.enter()) return this.r.pc;
      } else if (k === 'R') {
        // the platform's RET took the word under its SP: the model's own
        // SENTINEL there (not rewritten by the platform) means it came back into a model call
        this.apply(d, true); this.written.length = 0;
        const slot = (regs[18] - 2) & 0xffff;
        const gw = this.gold[slot] | this.gold[slot + 1] << 8;
        const back = gw === pc && this.rd16(slot) === SENTINEL ? SENTINEL : pc;
        this.setRegs(back, regs); this.i++;
        return back;
      } else {
        throw new Mismatch(`${this.where()}: ${k} inside a platform call to ${hx(target)}`);
      }
    }
  }
  // a nested game entry (from an 'E'): runs until it leaves to the platform ('L')
  // returns true when it came back into game code (the RET of an ISR out of a HALT)
  enter() {
    // the entry's frame ends at SP+2 (its RET). An entry whose return address is
    // in game code (an IRQ that woke a HALT) or the model's own SENTINEL (the
    // platform JP'd into game code from a model call) comes back by that RET.
    const pc = this.r.pc, ret = this.rd16(this.r.sp), frame = (this.r.sp + 2) & 0xffff;
    const back = { frame, sp: frame, ret, game: !!isGame[ret] || ret === SENTINEL };
    if (this.procs[pc]) {
      this.runProc(pc);
      if (back.game && this.r.pc === back.ret && this.r.sp === back.sp) return true;
      // a JS tail into Z80 code or into the platform (a JP out, not the RET)
      if (isGame[this.r.pc] || this.r.sp !== frame) return this.exec(back) === 'back';
      this.check('L', this.r.pc, pc);
      return false;
    }
    return this.exec(back) === 'back';
  }
  // JS procedure at pc, entered with its return address on the stack
  runProc(pc) {
    if (this.stats) this.stats[pc] = (this.stats[pc] || 0) + 1;
    if (SHADOW) return this.shadow(pc);
    this.invoke(pc);
  }
  // run the JS procedure at pc (its return address at SP) and set r.pc where it goes;
  // a platform return that skipped frames (Unwind) ends here when it skipped to our caller
  invoke(pc) {
    const back = (this.r.sp + 2) & 0xffff;
    const entry = this.r.sp;
    let res;
    try { res = this.procs[pc](this); } catch (e) {
      // back to our caller, or into our own frame (the rest runs as Z80 code)
      if (e instanceof Unwind && (e.sp === back || e.sp === entry)) { this.r.pc = e.pc; this.r.sp = e.sp; return; }
      throw e;
    }
    if (res && res.pc !== undefined) { this.r.pc = res.pc; if (res.sp !== undefined) this.r.sp = res.sp; }
    else this.r.pc = this.pop();
  }
  // SHADOW=1: run the JS procedure, then the same call on the bare Z80 core from
  // the same state (no JS procedures inside) and compare all registers with F
  // and every byte either side wrote. Skipped when the call reaches the platform.
  shadow(pc) {
    const r0 = { ...this.r }, m0 = this.mem.slice(), i0 = this.i, w0 = this.written.length;
    this.invoke(pc);
    if (this.i !== i0) return;
    const r1 = { ...this.r }, m1 = this.mem.slice(), jsw = this.written.slice(w0);
    this.mem.set(m0); Object.assign(this.r, r0); this.written.length = w0;
    this.toCore();
    const cpu = this.cpu;
    let n = 0, ok = true;
    while (!(cpu.pc === r1.pc && cpu.sp === r1.sp)) {
      if (!isGame[cpu.pc] || this.mem[cpu.pc] === 0x76 || ++n > 2e6) { ok = false; break; }
      cpu.run_instruction();
    }
    this.fromCore();
    const zr = { ...this.r }, zw = this.written.slice(w0), zm = this.mem.slice();
    this.mem.set(m1); Object.assign(this.r, r1); this.written.length = w0; this.written.push(...jsw);
    if (!ok) throw new Mismatch(`shadow ${hx(pc)}: Z80 did not come back to ${hx(r1.pc)} sp ${hx(r1.sp)} (at ${hx(zr.pc)})`);
    const bad = [];
    for (const n of REGS) if (n !== 'iff' && zr[n] !== r1[n]) bad.push(`${n} ${hx(r1[n], 2)}/${hx(zr[n], 2)}`);
    for (const a of new Set([...jsw, ...zw])) if (!(a >= STACK_LO && a < r1.sp) && m1[a] !== zm[a]) bad.push(`(${hx(a)}) ${hx(m1[a], 2)}/${hx(zm[a], 2)}`);
    if (bad.length) throw new Mismatch(`${this.where()} shadow ${hx(pc)}: JS/Z80 ${bad.join(' ')}`);
  }

  // model -> game procedure at addr (JS or Z80), as a CALL
  call(addr) {
    const sp = this.r.sp;
    this.push(SENTINEL);
    this.r.pc = addr;
    if (this.procs[addr]) {
      this.runProc(addr);
      if (this.r.pc === SENTINEL && this.r.sp === sp) return;
    }
    this.exec({ pc: SENTINEL, sp });
  }
  // model -> platform as a CALL; a platform that returns past our caller's
  // frame (pops two return addresses) unwinds the JS procedures to that frame
  pcall(target) {
    const sp0 = this.r.sp;
    this.push(SENTINEL);
    let pc;
    try { pc = this.platform(target, -1); } catch (u) {
      if (!(u instanceof Unwind)) throw u;
      pc = this.r.pc = u.pc; this.r.sp = u.sp;
    }
    if (pc === SENTINEL && this.r.sp === sp0) return pc;
    if (this.r.sp >= sp0) throw new Unwind(this.r.sp, pc);
    throw new Mismatch(`${this.where()}: platform ${hx(target)} came back to ${hx(pc)} with SP ${hx(this.r.sp)} below ${hx(sp0)}`);
  }
  // model -> game code at addr as a JP (tail): `return m.jp(addr)` in a procedure
  jp(addr) {
    if (this.procs[addr]) { if (this.stats) this.stats[addr] = (this.stats[addr] || 0) + 1; return this.procs[addr](this); }
    return { pc: addr };
  }
  // model -> platform: as a CALL (pushes a return address) or as a JP (tail call)
  pjump(target) { return this.platform(target, -1); }
  // model -> HALT at pc (the IRQ that ends it is RST 38h; the ISR returns to pc+1)
  halt(pc) {
    if (this.free) return;
    this.r.iff = 0;
    this.push((pc + 1) & 0xffff);
    const back = this.platform(0x38, pc);
    if (back !== ((pc + 1) & 0xffff)) throw new Mismatch(`${this.where()}: the IRQ out of HALT at ${hx(pc)} came back to ${hx(back)}`);
  }
  // model -> the main-loop mark
  mark(pc) { this.r.pc = pc; if (!this.free) this.check('M', pc, -1); }

  // run Z80 code from r.pc until `stop` ({pc, sp}) or a nested entry leaves ('L')
  exec(stop) {
    const cpu = this.cpu;
    this.toCore();
    let prev = -1, first = true;
    for (;;) {
      const pc = cpu.pc;
      if (stop && pc === stop.pc && cpu.sp === stop.sp) { this.fromCore(); return; }
      if (stop && stop.game && pc === stop.ret && cpu.sp === stop.sp) { this.fromCore(); return 'back'; }
      if (!first && this.procs[pc]) {      // a CALL/JP into modelled code
        this.fromCore(); this.runProc(pc); this.toCore(); prev = -1; continue;
      }
      if (!isGame[pc] && this.free) {
        this.fromCore(); this.platform(pc, prev); this.toCore(); prev = -1; first = true; continue;
      }
      if (this.free && this.mem[pc] === 0x76) { this.fromCore(); this.r.pc = (pc + 1) & 0xffff; this.toCore(); continue; }
      if (this.free && ++this.steps > 5e6) throw new Mismatch('free run: too long');
      if (!isGame[pc]) {
        this.fromCore();
        const e = this.next();
        if (e[0] === 'L') { this.check('L', pc, prev); return; }
        this.outside(stop, () => this.platform(pc, prev));
        this.toCore(); prev = -1; first = true; continue;
      }
      if (this.marks.has(pc) && prev !== -2 && !this.free) {
        this.fromCore(); this.check('M', pc, prev); prev = -2; continue;
      }
      if (this.mem[pc] === 0x76) {          // HALT: the IRQ that ends it is RST 38h
        cpu.run_instruction();
        this.fromCore();
        this.r.iff = 0;
        this.push((pc + 1) & 0xffff);
        this.outside(stop, () => this.platform(0x38, pc));
        this.toCore(); prev = -1; first = true; continue;
      }
      prev = pc; first = false;
      cpu.run_instruction(); this.steps++;
    }
  }

  // a platform call from Z80 code of an exec: where it came back (directly or by
  // an Unwind from a nested entry) must be inside this exec's frame, or one of
  // its normal exits (checked at the loop top); otherwise unwind further up
  outside(stop, fn) {
    try { fn(); } catch (u) {
      if (!(u instanceof Unwind)) throw u;
      this.r.pc = u.pc; this.r.sp = u.sp;
    }
    if (!stop) return;
    const top = stop.frame !== undefined ? stop.frame : stop.sp, { pc, sp } = this.r;
    if (sp < top) return;
    if (stop.pc === SENTINEL && pc === SENTINEL && sp === stop.sp) return;
    if (stop.game && pc === stop.ret && sp === stop.sp) return;
    throw new Unwind(sp, pc);
  }

  run() {
    const [k, pc, regs, d] = this.ev[0];
    if (k !== 'E') throw new Mismatch('golden does not start with an entry');
    this.apply(d, true);
    this.setRegs(pc, regs);
    this.i = 1;
    try { this.enter(); } catch (e) { if (!(e instanceof Done)) throw e; }
    if (this.i < this.ev.length) throw new Mismatch(`stopped at ${this.where()}`);
  }
}

module.exports = { Machine, Mismatch, isGame, hx };
