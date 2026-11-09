// Headless, silent CPC speed bench on CPCBox (+cdt.js).
// node bench.js <site-dir> <cdt> <still|motion> [out.json]
// Counts entries to the CPC main loop 02A3 (= MSX 8554) in emulated seconds
// 2.4..12.4 after the first entry past the 1P start, like msxspeed_*.tcl.
const http = require("http"), fs = require("fs"), path = require("path");
const puppeteer = require("puppeteer");
const [site, cdt, MODE = "still", OUT] = process.argv.slice(2);

const types = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };
const srv = http.createServer((q, r) => {
  const p = path.join(site, decodeURIComponent(q.url.split("?")[0]).replace(/^\/$/, "/index.html"));
  fs.readFile(p, (e, b) => { if (e) { r.writeHead(404); r.end(); return; }
    r.writeHead(200, { "Content-Type": types[path.extname(p)] || "application/octet-stream" }); r.end(b); });
}).listen(0, "127.0.0.1");

(async () => {
  await new Promise(r => srv.listening ? r() : srv.once("listening", r));
  const port = srv.address().port;
  const browser = await puppeteer.launch({ headless: true, args: ["--mute-audio", "--autoplay-policy=user-gesture-required"] });
  const page = await browser.newPage();
  page.on("dialog", d => { console.error("dialog:", d.message()); d.dismiss(); });
  page.on("pageerror", e => console.error("pageerror:", e.message));
  await page.evaluateOnNewDocument(() => { window.AUTO_START_ENABLED = false; });
  await page.goto(`http://127.0.0.1:${port}/index.html`, { waitUntil: "load" });
  const tape = Array.from(fs.readFileSync(cdt));
  const res = await page.evaluate((tape, MODE) => {
    // boot a 6128, stop CPCBox's own timers, drive the CPU ourselves
    $("#snapshot").val("boot_cpc6128");
    qH.ez(); qH.oM();
    pI.es = CDT.load(new Uint8Array(tape));
    pO.eC(); pO.eA(pO.eB);
    const K = pT.hj;
    const KEY = { // CPC matrix [row, bit]
      shift: [2, 5], ret: [2, 2], at: [3, 2], T: [6, 3], A: [8, 5], P: [3, 3], E: [7, 2],
      R: [6, 2], U: [5, 2], N: [5, 6], "2": [8, 1], "1": [8, 0], space: [5, 7],
      jright: [9, 3], jfire1: [9, 4], jfire2: [9, 5] };
    window.__down = k => down(k);
    const down = k => { K[KEY[k][0]] &= ~(1 << KEY[k][1]) & 255; };
    const up = k => { K[KEY[k][0]] |= 1 << KEY[k][1]; };
    const run = us => { const end = qH.aP + us; while (qH.aP < end) pX.exec(); };
    const F = 20000;
    const tap = (keys, hold = 4) => { keys.forEach(down); run(hold * F); keys.forEach(up); run(4 * F); };
    run(100 * F);
    tap(["shift", "at"]);                         // |
    for (const c of "TAPE") tap([c]);
    tap(["ret"]);
    run(50 * F);
    for (const c of "RUN") tap([c]);
    tap(["shift", "2"]);                          // "
    tap(["ret"]);
    run(30 * F);
    pO.eA(pO.eF);                                 // press PLAY
    tap(["space"]);                               // "Press PLAY then any key"
    const t0load = qH.aP;
    // loaded = motor off for good (after the last block), see dbg runs: ~358 s
    while (!(pO.eI === false && qH.aP - t0load > 300e6) && qH.aP - t0load < 500e6) run(1e6);
    const loaded = (qH.aP - t0load) / 1e6;
    run(10e6);
    tap(["space"]);                               // splash -> menu
    run(5e6);
    tap(["1"], 50);                                 // 1 JUGADOR: the match starts by itself
    // measure
    let t0 = null, n = 0, released = false, first = [], snaps = {}, marks = [0.5, 2, 3.5, 6, 9, 12];
    const cv = document.querySelector("canvas");
    const limit = qH.aP + 60e6;
    while (qH.aP < limit) {
      if (pX.dG === 0x02A3) {
        const t = qH.aP / 1e6;
        if (t0 === null) { t0 = t; if (MODE === "motion") down("jright"); }
        const dt = t - t0;
        if (MODE === "motion" && !released && dt >= 3.4) { up("jright"); released = true; }
        if (marks.length && dt >= marks[0]) snaps[marks.shift()] = cv.toDataURL();
        if (dt >= 2.4 && dt < 12.4) { n++; if (first.length < 400) first.push(+dt.toFixed(3)); }
        if (dt >= 12.4) break;
        if (MODE === "motion" && dt >= 1.5 && !window.__shot) { window.__shot = 1; }
      }
      pX.exec();
    }
    return { loaded, t0, n, hz: n / 10, times: first, snaps };
  }, tape, MODE);
  await (await page.$("#screen")).screenshot({ path: (OUT || "/tmp/x").replace(/\.json$/, "") + ".png" });
  console.log(JSON.stringify({ mode: MODE, loaded_s: res.loaded, t0: res.t0, n: res.n, hz: res.hz }));
  if (OUT) { for (const [k, v] of Object.entries(res.snaps || {})) fs.writeFileSync(OUT.replace(/\.json$/, `_t${k}.png`), Buffer.from(v.split(",")[1], "base64")); delete res.snaps; fs.writeFileSync(OUT, JSON.stringify(res)); }
  await browser.close(); srv.close();
})().catch(e => { console.error(e); process.exit(1); });
