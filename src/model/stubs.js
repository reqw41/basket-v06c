'use strict';
/**
 * Jump stubs of the game window: the vector tables (84D0.., 9376..93C7, A08C..)
 * and single JP procedures into the platform. Each continues at its target
 * (the model's procedure or the platform). Generated from disasm/v06/game.asm.
 */
const T = {
  'AC44': 0xAE19, 'B1F2': 0x01E6,
  '3791': 0x031B, '37D2': 0x063E, '84D0': 0x84E8, '84D3': 0x8C60, '84D6': 0x8ADD, '84D9': 0x90EF,
  '84DC': 0x8C16, '84DF': 0x870E, '84E2': 0x8F76, '84E5': 0x8E5A, '9376': 0xA063, '9379': 0x9F9A,
  '937C': 0x9F60, '937F': 0x9F67, '9382': 0x9543, '9385': 0x94B0, '9388': 0x9A1B, '938B': 0x98D9,
  '938E': 0x994A, '9391': 0x99BC, '9394': 0x9E6F, '9397': 0xA01F, '939A': 0xA022, '939D': 0x9F25,
  '93A0': 0x9E82, '93A3': 0x9ED4, '93A6': 0xA00E, '93A9': 0x9FC0, '93AC': 0x9FF2, '93AF': 0xA03B,
  '93B2': 0x9919, '93B5': 0x9BF6, '93B8': 0x98B3, '93BB': 0x9C83, '93BE': 0x9DC2, '93C1': 0xA02C,
  '93C4': 0x9599, '93C7': 0x958F, '9F48': 0x02CE, 'A08C': 0xA0BF, 'A08F': 0xA1AA, 'A092': 0xA502,
  'A095': 0xA5FD, 'A098': 0xA82C, 'A09B': 0xA95E, 'A09E': 0xA969, 'A0A1': 0xA53A, 'A0AA': 0xA0B0,
  'A4A8': 0x01F8, 'A8C8': 0x0903, 'A8F4': 0x0885, 'A991': 0x752D, 'AB25': 0xABFF, 'AC4A': 0xAF05,
  'B01C': 0x01E9, 'B1FE': 0x01EF,
};
const procs = {};
for (const [a, to] of Object.entries(T)) procs[a] = (m) => m.jp(to);
module.exports = { procs, T };
