"""Distances recalculees sans le DRC, sur les contours reels (pastilles, pistes, vias, plans remplis).
Usage : check_dist.py carte.kicad_pcb"""
import sys, fnmatch
import numpy as np
import wx, pcbnew
sys.stdout.reconfigure(encoding="utf-8")
b = pcbnew.LoadBoard(sys.argv[1])
SECT = ["MAINS_L", "MAINS_N", "PHASE_PROT", "MT_*", "FP?", "unconnected-(OC*Pad5)"]
sect = lambda n: any(fnmatch.fnmatchcase(n, p) for p in SECT)
CU = (pcbnew.F_Cu, pcbnew.B_Cu)


def edges(ps):
    E = []
    for i in range(ps.OutlineCount()):
        for o in [ps.Outline(i)] + [ps.Hole(i, h) for h in range(ps.HoleCount(i))]:
            q = [(o.CPoint(k).x / 1e6 - 60, o.CPoint(k).y / 1e6 - 50) for k in range(o.PointCount())]
            E += list(zip(q, q[1:] + q[:1]))
    return np.array(E).reshape(-1, 4)


IT = []
for f in b.GetFootprints():
    for p in f.Pads():
        if p.GetAttribute() == pcbnew.PAD_ATTRIB_NPTH:
            continue
        ps = pcbnew.SHAPE_POLY_SET()
        p.TransformShapeToPolygon(ps, pcbnew.F_Cu, 0, 2000, pcbnew.ERROR_OUTSIDE)
        e = edges(ps)
        for l in CU:
            IT.append((f.GetReference() + "." + p.GetNumber(), p.GetNetname(), l, e, "pad"))
for x in b.GetTracks():
    for l in CU:
        if x.IsOnLayer(l):
            ps = pcbnew.SHAPE_POLY_SET()
            x.TransformShapeToPolygon(ps, l, 0, 2000, pcbnew.ERROR_OUTSIDE)
            IT.append(("piste", x.GetNetname(), l, edges(ps), "piste"))
for z in b.Zones():
    if not z.GetIsRuleArea():
        for l in CU:
            if z.IsOnLayer(l):
                IT.append(("plan " + z.GetZoneName(), z.GetNetname(), l, edges(z.GetFilledPolysList(l)), "plan"))


def pt_seg(P, S):
    a, d = S[None, :, :2], (S[:, 2:] - S[:, :2])[None]
    v = P[:, None, :] - a
    L = (d ** 2).sum(-1)
    L = np.where(L == 0, 1, L)
    k = np.clip((v * d).sum(-1) / L, 0, 1)
    return np.sqrt(((v - k[..., None] * d) ** 2).sum(-1)).min()


def dist(A, B):   # les contours ne se coupent pas (verifie par le DRC) : min sommets / aretes
    m = 1e9
    for i in range(0, len(B), 2000):
        q = B[i:i + 2000]
        m = min(m, pt_seg(A[:, :2], q), pt_seg(q[:, :2], A))
    return m


def bbd(A, B):
    ax, ay, bx, by = A[:, ::2], A[:, 1::2], B[:, ::2], B[:, 1::2]
    return max(0, bx.min() - ax.max(), ax.min() - bx.max()) + 0 * ay.min(), max(0, by.min() - ay.max(), ay.min() - by.max())


def report(title, pa, pb, same_layer, lim, skip=lambda a, c: False, n=4):
    R = []
    for A in IT:
        if not pa(A):
            continue
        for B in IT:
            if not pb(B) or (A[1] == B[1]) or (same_layer and A[2] != B[2]) or skip(A, B):
                continue
            if max(bbd(A[3], B[3])) > lim:
                continue
            R.append((round(float(dist(A[3], B[3])), 3), A[0] + " " + A[1], B[0] + " " + B[1]))
    print(title)
    seen = set()
    for r in sorted(R):
        k = tuple(sorted(r[1:]))
        if k in seen:
            continue
        seen.add(k)
        print("   ", r)
        if len(seen) == n:
            break


S_, T_ = (lambda A: sect(A[1])), (lambda A: not sect(A[1]))
oc = lambda A: A[0].startswith("OC")
report("SECTEUR / TBT, projection des deux faces confondues (plus severe que la regle) :", S_, T_, False, 8)
report("SECTEUR / TBT, hors pastilles d'un meme opto :", S_, T_, False, 8, lambda a, c: oc(a) and a[0].split(".")[0] == c[0].split(".")[0])
report("SECTEUR / TBT, pistes et plans seulement (sans pastille d'opto des deux cotes) :", S_, T_, False, 10, lambda a, c: oc(a) and oc(c))
report("NEUTRE / autre secteur, meme face :", lambda A: A[1] == "MAINS_N", lambda B: sect(B[1]), True, 6, n=3)
report("PHASE AVANT FUSIBLE / autre secteur, meme face :", lambda A: A[1] == "MAINS_L", lambda B: sect(B[1]), True, 6, n=3)
report("SECTEUR / SECTEUR, sans pastille d'opto, meme face :", lambda A: sect(A[1]) and not oc(A), lambda B: sect(B[1]) and not oc(B), True, 4, n=5)
report("SECTEUR / pastille d'opto, meme face :", lambda A: sect(A[1]) and not oc(A), lambda B: sect(B[1]) and oc(B), True, 3, n=3)
report("pastilles d'optos differents :", lambda A: sect(A[1]) and oc(A), lambda B: sect(B[1]) and oc(B), True, 3, lambda a, c: a[0].split(".")[0] == c[0].split(".")[0], n=2)
bout = lambda a, c: any(q[0] == "piste" and q[1] == "PHASE_PROT" and q[3][:, 1].max() > 34 for q in (a, c))
report("SECTEUR / SECTEUR, idem, hors sorties PHASE des optos :", lambda A: sect(A[1]) and not oc(A), lambda B: sect(B[1]) and not oc(B), True, 4, bout, n=5)
ant = np.array([[10.6, 14.5]])
print("secteur / centre antenne :", min((round(float(pt_seg(ant, A[3])), 1), A[0], A[1]) for A in IT if sect(A[1])))
