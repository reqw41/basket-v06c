"""Headless ZX Spectrum 48K run of a snapshot with SkoolKit's contended
simulator (CCMIOSimulator): frames, keys, screenshots, PC counts.
Library for the Basket Master ZX tempo measurement."""
import os, struct, subprocess, zlib
from skoolkit.snapshot import Snapshot
from skoolkit.simutils import from_snapshot
from skoolkit.cmiosimulator import CMIOSimulator
from skoolkit.trace import Tracer
from skoolkit import CCMIOSimulator, CSimulator

FRAME = 69888
KEYS = {  # (half-row index, bit)
    'SS': (0, 0), 'Z': (0, 1), 'X': (0, 2), 'C': (0, 3), 'V': (0, 4),
    'A': (1, 0), 'S': (1, 1), 'D': (1, 2), 'F': (1, 3), 'G': (1, 4),
    'Q': (2, 0), 'W': (2, 1), 'E': (2, 2), 'R': (2, 3), 'T': (2, 4),
    '1': (3, 0), '2': (3, 1), '3': (3, 2), '4': (3, 3), '5': (3, 4),
    '0': (4, 0), '9': (4, 1), '8': (4, 2), '7': (4, 3), '6': (4, 4),
    'P': (5, 0), 'O': (5, 1), 'I': (5, 2), 'U': (5, 3), 'Y': (5, 4),
    'ENTER': (6, 0), 'L': (6, 1), 'K': (6, 2), 'J': (6, 3), 'H': (6, 4),
    'SPACE': (7, 0), 'SYM': (7, 1), 'M': (7, 2), 'N': (7, 3), 'B': (7, 4),
}


class ZX:
    def __init__(self, sna, cmio=True):
        snap = Snapshot.get(sna)
        cls = (CCMIOSimulator or CMIOSimulator) if cmio else None
        if not cmio:
            cls = CSimulator
        self.sim = from_snapshot(cls, snap, {}, {'ay': [None] * 16}, {'fast_djnz': False, 'fast_ldir': False})
        self.tracer = Tracer(self.sim, snap.border, 0, 0, [0] * 16, 0, False)
        self.sim.set_tracer(self.tracer)
        self.kb = [0] * 8
        self.tracer.keyboard = self.kb
        self.mem = self.sim.memory
        self.reg = self.sim.registers
        self.pc = snap.pc

    @property
    def t(self):
        return self.reg[25]

    def keys(self, *names):
        for i in range(8):
            self.kb[i] = 0
        for n in names:
            r, b = KEYS[n]
            self.kb[r] |= 1 << b

    def run_until(self, t_end=0, stop=-1):
        """Run to T-state t_end or until PC == stop. Returns True when stopped at PC."""
        self.tracer.keyboard = self.kb
        cond, _ = self.sim.trace(self.reg[24], stop, 0, t_end, True, None, None, self.kb, None, None)
        return cond == 3

    def frames(self, n):
        self.run_until(self.t + n * FRAME)

    def png(self, path):
        m = self.mem
        pal = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
        rows = []
        for y in range(192):
            a = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
            row = bytearray([0])
            for x in range(32):
                at = m[0x5800 + (y >> 3) * 32 + x]
                ink, paper = pal[at & 7], pal[(at >> 3) & 7]
                if at & 0x40:
                    ink = tuple(min(255, c * 255 // 205) for c in ink); paper = tuple(min(255, c * 255 // 205) for c in paper)
                b = m[a + x]
                for k in range(8):
                    row += bytes(ink if b & (0x80 >> k) else paper)
            rows.append(bytes(row))
        raw = zlib.compress(b''.join(rows))
        def chunk(t, d):
            c = struct.pack('>I', len(d)) + t + d
            return c + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
        with open(path, 'wb') as f:
            f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 256, 192, 8, 2, 0, 0, 0)) + chunk(b'IDAT', raw) + chunk(b'IEND', b''))
