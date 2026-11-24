"""Relit les Gerbers et percages sans KiCad : distances secteur / TBT, percages, vernis, contour, apercu PNG.
Usage : check_gerbers.py dossier [apercu.png]"""
import sys, os, re, glob, math, fnmatch, collections
import numpy as np
from PIL import Image, ImageDraw
sys.stdout.reconfigure(encoding="utf-8")
D = sys.argv[1]
SECT = ["MAINS_L", "MAINS_N", "PHASE_PROT", "MT_*", "FP?", "unconnected-(OC*Pad5)"]


def sect(n):
    return any(fnmatch.fnmatchcase(n, p) for p in SECT)


def unesc(s):
    return re.sub(r"\\u([0-9A-Fa-f]{4})", lambda m: chr(int(m[1], 16)), s)


def P(a, b):
    return (a - 60, -b - 50)


def read(path):
    """-> liste (type, net, points, rayon, pastille, noir). Points en mm depuis le coin de la carte.
    Types : R region, L trait, P pastille ronde ou ovale, Q pastille polygonale."""
    t = open(path, encoding="utf-8").read()
    ap, out, net, pad = {}, [], "", ""
    x = y = 0.0
    cur, region, poly, mode, dark = None, False, [], 1, True
    for ext, w in re.findall(r"%([^%]*)%|([^*%]+)\*", t):
        if ext:
            ext = ext.strip().rstrip("*")
            if ext.startswith("ADD"):
                m = re.match(r"ADD(\d+)([A-Za-z_]\w*),?(.*)", ext)
                ap[int(m[1])] = (m[2], [float(v) for v in m[3].split("X")] if m[3] else [])
            elif ext.startswith("TO.N,"):
                net = unesc(ext[5:].split(",")[0])
            elif ext.startswith("TO.P,"):
                pad = ".".join(ext[5:].split(",")[:2])
            elif ext.startswith("TD"):
                if ext == "TD" or ".N" in ext:
                    net = ""
                if ext == "TD" or ".P" in ext:
                    pad = ""
            elif ext.startswith("LP"):
                dark = ext == "LPD"
            continue
        w = w.strip()
        if w.startswith("G04"):
            continue
        for g in re.findall(r"G(\d\d)", w):
            g = int(g)
            if g in (1, 2, 3):
                mode = g
            elif g == 36:
                region, poly = True, []
            elif g == 37:
                if len(poly) > 2:
                    out.append(("R", net, poly, 0.0, pad, dark))
                region, poly = False, []
        m = re.match(r"^D(\d+)$", w)
        if m and int(m[1]) >= 10:
            cur = int(m[1])
            continue
        m = re.match(r"^(?:G\d\d)*(?:X(-?\d+))?(?:Y(-?\d+))?(?:I(-?\d+))?(?:J(-?\d+))?D0?([123])$", w)
        if not m:
            continue
        nx = int(m[1]) / 1e6 if m[1] else x
        ny = int(m[2]) / 1e6 if m[2] else y
        op = m[5]
        pts = [(x, y), (nx, ny)]
        if op == "1" and mode in (2, 3) and (m[3] or m[4]):
            cx, cy = x + int(m[3] or 0) / 1e6, y + int(m[4] or 0) / 1e6
            a0, a1, r = math.atan2(y - cy, x - cx), math.atan2(ny - cy, nx - cx), math.hypot(x - cx, y - cy)
            if mode == 3 and a1 <= a0:
                a1 += 2 * math.pi
            if mode == 2 and a1 >= a0:
                a1 -= 2 * math.pi
            pts = [(cx + r * math.cos(a0 + (a1 - a0) * k / 32), cy + r * math.sin(a0 + (a1 - a0) * k / 32)) for k in range(33)]
        if region:
            if op == "2":
                if len(poly) > 2:
                    out.append(("R", net, poly, 0.0, pad, dark))
                poly = [P(nx, ny)]
            else:
                poly += [P(*q) for q in pts[1:]]
        elif op == "1":
            k, a = ap[cur]
            assert k == "C", k
            out.append(("L", net, [P(*q) for q in pts], a[0] / 2, pad, dark))
        elif op == "3":
            k, a = ap[cur]
            c = P(nx, ny)
            if k == "C":
                out.append(("P", net, [c], a[0] / 2, pad, dark))
            elif k == "O":
                r, dx, dy = min(a[:2]) / 2, max(0, a[0] - a[1]) / 2, max(0, a[1] - a[0]) / 2
                out.append(("P", net, [(c[0] - dx, c[1] - dy), (c[0] + dx, c[1] + dy)], r, pad, dark))
            elif k == "R":
                out.append(("Q", net, [(c[0] + sx * a[0] / 2, c[1] + sy * a[1] / 2) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))], 0.0, pad, dark))
            elif k == "RoundRect":
                q = a[1:9]
                out.append(("Q", net, [(c[0] + q[i], c[1] - q[i + 1]) for i in (0, 2, 4, 6)], a[0], pad, dark))
            else:
                raise SystemExit("ouverture non geree " + k)
        x, y = nx, ny
    return out


def edges(o):
    p = o[2]
    if len(p) == 1:
        p = [p[0], p[0]]
    q = list(zip(p, p[1:])) + ([(p[-1], p[0])] if o[0] in "RQ" else [])
    return np.array([a + b for a, b in q])


def pseg(A, S):
    a, d = S[None, :, :2], (S[:, 2:] - S[:, :2])[None]
    v = A[:, None, :] - a
    n = (d ** 2).sum(-1)
    n = np.where(n == 0, 1, n)
    k = np.clip((v * d).sum(-1) / n, 0, 1)
    return np.sqrt(((v - k[..., None] * d) ** 2).sum(-1)).min()


def dist(A, B):
    m = 1e9
    for i in range(0, len(B), 1500):
        q = B[i:i + 1500]
        m = min(m, pseg(A[:, :2], q), pseg(A[:, 2:], q), pseg(q[:, :2], A), pseg(q[:, 2:], A))
    return float(m)


def f(s):
    return glob.glob(os.path.join(D, "*" + s))[0]


L = {k: read(f(v)) for k, v in {"F.Cu": "F_Cu.gtl", "B.Cu": "B_Cu.gbl", "F.Mask": "F_Mask.gts", "B.Mask": "B_Mask.gbs",
                                "F.Silk": "F_Silkscreen.gto", "B.Silk": "B_Silkscreen.gbo", "Edge": "Edge_Cuts.gm1"}.items()}
cu = [(l,) + o for l in ("F.Cu", "B.Cu") for o in L[l]]
print("objets cuivre :", collections.Counter((o[0], o[1]) for o in cu))
print("objets cuivre sans net :", collections.Counter((o[0], o[1]) for o in cu if not o[2]))
print("couches avec polarite claire :", [l for l in L if any(not o[5] for o in L[l])])
E_ = [(o, edges(o[1:])) for o in cu]
S_ = [q for q in E_ if sect(q[0][2])]
T_ = [q for q in E_ if not sect(q[0][2])]
R = []
for o, e in S_:
    for p, g in T_:
        gx = max(g[:, ::2].min() - e[:, ::2].max(), e[:, ::2].min() - g[:, ::2].max())
        gy = max(g[:, 1::2].min() - e[:, 1::2].max(), e[:, 1::2].min() - g[:, 1::2].max())
        if max(gx, gy) - o[4] - p[4] < 6.5:
            R.append((round(dist(e, g) - o[4] - p[4], 3), o[2], o[5], o[0], p[2], p[5], p[0]))
R.sort()
print("objets secteur", len(S_), "TBT", len(T_))
print("min SECTEUR / TBT, faces confondues :", R[0])


def meme(r):
    return r[2] and r[5] and r[2].split(".")[0] == r[5].split(".")[0] and r[2].startswith("OC")


print("   hors pastilles d'un meme opto :", [r for r in R if not meme(r)][0])
b = np.array([p for o in L["Edge"] for p in o[2]])
print("contour :", b.min(0).round(3), b.max(0).round(3))
print("secteur / bord :", round(min(min(e[:, ::2].min(), e[:, 1::2].min(), 156 - e[:, ::2].max(), 86.5 - e[:, 1::2].max()) - o[4] for o, e in S_), 3))
H = []
for n in ("-PTH.drl", "-NPTH.drl"):
    T, cur = {}, None
    for l in open(f(n)):
        l = l.strip()
        m = re.match(r"T(\d+)C([\d.]+)", l)
        k = re.match(r"T(\d+)$", l)
        q = re.match(r"X([-\d.]+)Y([-\d.]+)(G85X([-\d.]+)Y([-\d.]+))?", l)
        if m:
            T[m[1]] = float(m[2])
        elif k:
            cur = T.get(k[1])
        elif q:
            H.append((n[1:-4], cur) + P(float(q[1]), float(q[2])) + ((P(float(q[4]), float(q[5])) if q[3] else None),))
print("trous :", sorted(collections.Counter((h[0], h[1]) for h in H).items()))


def ctr(o):
    return np.mean(np.array(o[2]), 0)


def has(layer, x, y):
    return [o for o in L[layer] if o[0] in "PQ" and np.hypot(*(ctr(o) - (x, y))) < .01]


bad = []
for h in H:
    if h[0] != "PTH":
        continue
    n = [len(has(l, h[2], h[3])) for l in ("F.Cu", "B.Cu", "F.Mask", "B.Mask")]
    if n != ([1, 1, 1, 1] if h[1] > .5 else [1, 1, 0, 0]):
        bad.append((h, n))
    if len({o[1] for l in ("F.Cu", "B.Cu") for o in has(l, h[2], h[3])}) > 1:
        bad.append((h, "net"))
print("trous metallises incoherents (cuivre 2 faces, vernis ouvert sauf vias) :", bad)
print("ouvertures de vernis :", {l: dict(collections.Counter(o[0] for o in L[l])) for l in ("F.Mask", "B.Mask")})
mx = 0
for l, c in (("F.Mask", "F.Cu"), ("B.Mask", "B.Cu")):
    for o in L[l]:
        q = has(c, *ctr(o))
        if q:
            mx = max(mx, abs(edges(o)[:, ::2].max() + o[3] - edges(q[0])[:, ::2].max() - q[0][3]))
print("debord max du vernis autour des pastilles :", round(mx, 3))
if len(sys.argv) > 2:
    Z = 14
    W, Hh = int(156 * Z), int(86.5 * Z)
    ims = []
    for lay, mir in ((("F.Cu", "F.Mask", "F.Silk"), 0), (("B.Cu", "B.Mask", "B.Silk"), 1)):
        im = Image.new("RGB", (W, Hh), (20, 90, 45))
        d = ImageDraw.Draw(im)
        for l, col in zip(lay, (None, (200, 170, 90), (255, 255, 255))):
            for o in L[l]:
                c = col or ((200, 60, 40) if sect(o[1]) else (60, 130, 210))
                p = [(x * Z, y * Z) for x, y in o[2]]
                r = o[3] * Z
                if o[0] in "RQ":
                    d.polygon(p, fill=c)
                if o[0] != "R" and len(p) > 1 and r > 0:
                    for u, v in zip(p, p[1:] + (p[:1] if o[0] == "Q" else [])):
                        d.line([u, v], fill=c, width=max(1, int(2 * r)))
                if o[0] != "R" and len(p) < 40:
                    for x, y in p:
                        d.ellipse([x - r, y - r, x + r, y + r], fill=c)
        for h in H:
            r = h[1] / 2 * Z
            for x, y in [(h[2], h[3])] + ([h[4]] if h[4] else []):
                d.ellipse([x * Z - r, y * Z - r, x * Z + r, y * Z + r], fill=(0, 0, 0))
            if h[4]:
                d.line([(h[2] * Z, h[3] * Z), (h[4][0] * Z, h[4][1] * Z)], fill=(0, 0, 0), width=int(2 * r))
        ims.append(im.transpose(Image.FLIP_LEFT_RIGHT) if mir else im)
    o = Image.new("RGB", (W, 2 * Hh + 30), "white")
    o.paste(ims[0], (0, 0))
    o.paste(ims[1], (0, Hh + 30))
    o.save(sys.argv[2])
