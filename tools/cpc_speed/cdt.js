// CDT/TZX support for CPCBox: render the tape to the 8-bit level stream the
// WAV path produces (pn object, 125 kHz = CPCBox tape tick). Load after
// cpcbox.js. Timings in CDT are Z80 T-states at 3.5 MHz (TZX convention).
"use strict";
var CDT = (function () {
    var RATE = 125000, TPS = 3500000;

    function render(d) {
        if (String.fromCharCode.apply(null, d.subarray(0, 7)) != "ZXTape!")
            throw "CDT: bad signature";
        var out = [], level = 0, t = 0; // t in T-states (float)
        var pos = 0; // samples emitted
        function emit(T) { // hold current level for T T-states, then toggle
            t += T;
            var end = Math.round(t * RATE / TPS);
            for (; pos < end; pos++) out.push(level ? 255 : 0);
            level ^= 1;
        }
        function hold(T, lvl) {
            level = lvl;
            t += T;
            var end = Math.round(t * RATE / TPS);
            for (; pos < end; pos++) out.push(level ? 255 : 0);
        }
        function pause(ms) {
            if (!ms) return;
            // finish the last edge with 1 ms, then silence (low)
            hold(TPS / 1000, level);
            hold((ms - 1) * TPS / 1000, 0);
            level = 0;
        }
        function data(p, len, zero, one, used) {
            for (var i = 0; i < len; i++) {
                var b = d[p + i], bits = i == len - 1 ? used : 8;
                for (var k = 0; k < bits; k++) {
                    var T = (b & (0x80 >> k)) ? one : zero;
                    emit(T); emit(T);
                }
            }
        }
        var w = function (i) { return d[i] | d[i + 1] << 8; };
        var l3 = function (i) { return d[i] | d[i + 1] << 8 | d[i + 2] << 16; };
        var i = 10;
        while (i < d.length) {
            var id = d[i++], k, n, len;
            switch (id) {
            case 0x10: // standard speed
                len = w(i + 2);
                for (k = 0; k < (d[i + 4] < 128 ? 8063 : 3223); k++) emit(2168);
                emit(667); emit(735);
                data(i + 4, len, 855, 1710, 8);
                pause(w(i));
                i += 4 + len; break;
            case 0x11: // turbo speed
                len = l3(i + 15);
                for (k = 0; k < w(i + 10); k++) emit(w(i));
                emit(w(i + 2)); emit(w(i + 4));
                data(i + 18, len, w(i + 6), w(i + 8), d[i + 12]);
                pause(w(i + 13));
                i += 18 + len; break;
            case 0x12: // pure tone
                for (k = 0; k < w(i + 2); k++) emit(w(i));
                i += 4; break;
            case 0x13: // pulse sequence
                n = d[i];
                for (k = 0; k < n; k++) emit(w(i + 1 + 2 * k));
                i += 1 + 2 * n; break;
            case 0x14: // pure data
                len = l3(i + 7);
                data(i + 10, len, w(i), w(i + 2), d[i + 4]);
                pause(w(i + 5));
                i += 10 + len; break;
            case 0x15: // direct recording
                len = l3(i + 5);
                var tpb = w(i), used = d[i + 4];
                for (k = 0; k < len; k++) {
                    var bits = k == len - 1 ? used : 8;
                    for (n = 0; n < bits; n++) hold(tpb, (d[i + 8 + k] >> (7 - n)) & 1);
                }
                pause(w(i + 2));
                i += 8 + len; break;
            case 0x20: pause(w(i)); i += 2; break;
            case 0x21: i += 1 + d[i]; break;          // group start
            case 0x22: break;                          // group end
            case 0x24: i += 2; break;                  // loop start (unused here)
            case 0x25: break;
            case 0x2A: i += 4; break;                  // stop if 48K
            case 0x2B: i += 5; break;                  // signal level
            case 0x30: i += 1 + d[i]; break;           // text
            case 0x31: i += 2 + d[i + 1]; break;       // message
            case 0x32: i += 2 + w(i); break;           // archive info
            case 0x33: i += 1 + 3 * d[i]; break;       // hardware
            case 0x35: i += 0x14 + (d[i + 0x10] | d[i + 0x11] << 8 | d[i + 0x12] << 16 | d[i + 0x13] << 24); break;
            case 0x5A: i += 9; break;
            default: throw "CDT: unsupported block 0x" + id.toString(16);
            }
        }
        pause(1000);
        return new Uint8Array(out);
    }

    function load(a) {
        if (a[0] == 0x52 && a[1] == 0x49) return pD.cZ(a); // RIFF/WAV
        var s = render(a), b = Object.create(pn);
        b.aa(s, RATE, 125E3);
        return b;
    }
    pI.ep = ["wav", "cdt", "tzx"];
    pI.eq = load;
    return { render: render, load: load };
})();
