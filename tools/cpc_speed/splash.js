// Headless capture of the CPC title animation (player spinning the ball).
// node splash.js <site-dir> <cdt> <out-dir> [frames=500]
// Loads the tape like bench.js, then saves one canvas PNG per 50 Hz frame
// (out-dir/f000.png ...) while the post-load title animates. The images are
// the input of tools/make_splash_anim.py; they are not kept in git.
const http = require("http"), fs = require("fs"), path = require("path");
const puppeteer = require("puppeteer");
const [site, cdt, OUT, NF = "500"] = process.argv.slice(2);

const types = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };
const srv = http.createServer((q, r) => {
  const p = path.join(site, decodeURIComponent(q.url.split("?")[0]).replace(/^\/$/, "/index.html"));
  fs.readFile(p, (e, b) => { if (e) { r.writeHead(404); r.end(); return; }
    r.writeHead(200, { "Content-Type": types[path.extname(p)] || "application/octet-stream" }); r.end(b); });
}).listen(0, "127.0.0.1");

(async () => {
  await new Promise(r => srv.listening ? r() : srv.once("listening", r));
  const port = srv.address().port;
  const browser = await puppeteer.launch({ headless: true, args: ["--mute-audio"] });
  const page = await browser.newPage();
  page.on("pageerror", e => console.error("pageerror:", e.message));
  await page.evaluateOnNewDocument(() => { window.AUTO_START_ENABLED = false; });
  await page.goto(`http://127.0.0.1:${port}/index.html`, { waitUntil: "load" });
  const tape = Array.from(fs.readFileSync(cdt));
  const loaded = await page.evaluate((tape) => {
    $("#snapshot").val("boot_cpc6128");
    qH.ez(); qH.oM();
    pI.es = CDT.load(new Uint8Array(tape));
    pO.eC(); pO.eA(pO.eB);
    const K = pT.hj;
    const KEY = { shift: [2, 5], ret: [2, 2], at: [3, 2], T: [6, 3], A: [8, 5], P: [3, 3], E: [7, 2],
      R: [6, 2], U: [5, 2], N: [5, 6], "2": [8, 1], space: [5, 7] };
    const down = k => { K[KEY[k][0]] &= ~(1 << KEY[k][1]) & 255; };
    const up = k => { K[KEY[k][0]] |= 1 << KEY[k][1]; };
    const run = us => { const end = qH.aP + us; while (qH.aP < end) pX.exec(); };
    const F = 20000;
    const tap = (keys, hold = 4) => { keys.forEach(down); run(hold * F); keys.forEach(up); run(4 * F); };
    run(100 * F);
    tap(["shift", "at"]);
    for (const c of "TAPE") tap([c]);
    tap(["ret"]);
    run(50 * F);
    for (const c of "RUN") tap([c]);
    tap(["shift", "2"]);
    tap(["ret"]);
    run(30 * F);
    pO.eA(pO.eF);                                 // press PLAY
    tap(["space"]);
    const t0 = qH.aP;
    while (!(pO.eI === false && qH.aP - t0 > 300e6) && qH.aP - t0 < 500e6) run(1e6);
    return (qH.aP - t0) / 1e6;
  }, tape);
  console.log(`tape loaded in ${loaded.toFixed(1)} s (emulated)`);
  fs.mkdirSync(OUT, { recursive: true });
  for (let i = 0; i < +NF; i++) {
    const img = await page.evaluate(() => {
      const end = qH.aP + 20000; while (qH.aP < end) pX.exec();
      return document.querySelector("canvas").toDataURL();
    });
    fs.writeFileSync(path.join(OUT, `f${String(i).padStart(3, "0")}.png`), Buffer.from(img.split(",")[1], "base64"));
  }
  console.log(`${NF} frames -> ${OUT}`);
  await browser.close(); srv.close();
})().catch(e => { console.error(e); process.exit(1); });
