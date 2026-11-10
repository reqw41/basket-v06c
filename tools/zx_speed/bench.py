import sys, statistics, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from zxrun import ZX, FRAME
cmio = os.environ.get('CMIO','1')=='1'
z=ZX(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../ref/zx/bm.z80'), cmio=cmio)
z.frames(100); z.keys('SPACE'); z.frames(10); z.keys(); z.frames(60)
z.keys('1'); z.frames(10); z.keys(); z.frames(150)
LOOP=0x61F6
end = z.t + int(os.environ.get('NF','3000'))*FRAME
plan = os.environ.get('PLAN','')
seq = [('P',14),('Q',6),('O',14),('A',6)] if plan else []
flat = [k for k,n in seq for _ in range(n)]
ts=[]; k=0
while z.t < end:
    if z.run_until(end, LOOP):
        ts.append(z.t)
        if flat: z.keys(flat[k % len(flat)]); k+=1
        z.run_until(z.t+1)   # step off the stop PC
d=[b-a for a,b in zip(ts,ts[1:])]
med=statistics.median(d); live=[x for x in d if x < 3*med]
fr=lambda c: c/FRAME
print(f"cmio={cmio} plan={bool(plan)} iters={len(d)} mean={fr(statistics.mean(d)):.3f} fr/iter ({50/fr(statistics.mean(d)):.2f}/s)  median={fr(med):.3f} ({50/fr(med):.2f}/s)  live(<3x med) n={len(live)} mean={fr(statistics.mean(live)):.3f} ({50/fr(statistics.mean(live)):.2f}/s)")

