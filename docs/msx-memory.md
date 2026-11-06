# MSX Executive memory map

The working reference is the three-stage Executive cassette load, not the
first MSX release. The cartridge wrapper reproduces the load sequence in RAM
and leaves the game at its original addresses.

| stage | RAM range | size | entry | role |
|---|---:|---:|---:|---|
| 0 | `B3B0..DD18` | 10,601 | `CF08` | VDP patterns/assets, then VDP fill |
| 1 | `8534..CFF3` | 19,136 | `CF08` | VDP data/assets, then VDP fill |
| 2 | `84D0..CD30` | 18,529 | `84D0` | main game |

The sequential overlay after all three loads is `84D0..DD18`, 22,601 bytes.
`HIMEM` is `84D0`; the Executive boot sequence is `SCREEN 2`, first-stage
`BLOAD+R`, second-stage `BLOAD+R`, then main-stage `BLOAD+R`.

`CF08` is not a tape continuation routine. It is the VDP upload/fill routine:
the stage calls it with the pattern/data source at `HL=B3B0` (or the
corresponding stage buffer), and it performs the `OUT (98h)/(99h)` VRAM
transfers/fill. The main game starts only after the third block is copied and
the cartridge is unmapped.

The 2+2 Vector display budget is compatible with this image: the loaded
overlay is about 22 KB, leaving room for the adapter and work areas in a
64-KB plan, subject to the later complete read/write inventory. This is a
budget observation, not yet the final Vector memory layout.
