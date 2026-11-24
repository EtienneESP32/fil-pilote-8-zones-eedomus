"""Croquis cote du placement (PNG) + distances secteur / TBT recalculees.
Usage : plan_placement.py board.kicad_pcb sortie.png (python de KiCad 10)"""
import sys, math, fnmatch
import wx, pcbnew
from PIL import Image, ImageDraw, ImageFont
sys.stdout.reconfigure(encoding="utf-8")
OX, OY, W, H = 60.0, 50.0, 156.0, 86.5
b = pcbnew.LoadBoard(sys.argv[1])
t = pcbnew.ToMM
SECT = ["MAINS_L", "MAINS_N", "PHASE_PROT", "MT_*", "FP?", "unconnected-(OC*Pad5)"]
Z = 12.0
M = 130
BAR = [(27.0, 0), (27.0, 33.2), (28.9, 39.81), (145.0, 39.81), (145.0, 67.6), (156, 67.6)]


def sect(n):
    return any(fnmatch.fnmatchcase(n, p) for p in SECT)


im = Image.new("RGB", (int(W * Z + 2 * M), int(H * Z + 2 * M + 150)), "white")
d = ImageDraw.Draw(im, "RGBA")


def F(s, bold=False):
    return ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf", s)


def X(x):
    return M + x * Z


def Y(y):
    return M + y * Z


def ctext(x, y, s, f, fill=(0, 0, 0)):
    d.text((X(x), Y(y)), s, font=f, fill=fill, anchor="mm")


d.polygon([(X(x), Y(y)) for x, y in BAR + [(156, 0)]], fill=(255, 225, 215))
d.polygon([(X(x), Y(y)) for x, y in BAR + [(156, 86.5), (0, 86.5), (0, 0)]], fill=(220, 235, 255))
d.rectangle([X(0), Y(0), X(W), Y(H)], outline=(0, 0, 0), width=3)
d.rectangle([X(0.1), Y(0.1), X(21.1), Y(17.2)], fill=(255, 250, 170), outline=(150, 130, 0), width=2)
for y in (14.75, 71.75):
    for k in range(0, int(W), 4):
        d.line([X(k), Y(y), X(min(k + 2, W)), Y(y)], fill=(90, 90, 90), width=2)
col, pads, draw = {}, [], []
for f in b.GetFootprints():
    r = f.GetReference()
    xs, ys = [], []
    for g in f.GraphicalItems():
        if g.GetLayer() == pcbnew.F_Fab and g.Type() == pcbnew.PCB_SHAPE_T:
            q = g.GetBoundingBox()
            w = g.GetWidth() // 2
            xs += [t(q.GetLeft() + w) - OX, t(q.GetRight() - w) - OX]
            ys += [t(q.GetTop() + w) - OY, t(q.GetBottom() - w) - OY]
    if r.startswith("H"):
        c = f.GetPosition()
        xs = [t(c.x) - OX - 3.5, t(c.x) - OX + 3.5]
        ys = [t(c.y) - OY - 6.7, t(c.y) - OY + 6.7]
    fill = (255, 255, 255, 120) if r != "JWS1" else (170, 200, 170, 70)
    d.rectangle([X(min(xs)), Y(min(ys)), X(max(xs)), Y(max(ys))], outline=(60, 60, 60), width=2, fill=fill)
    col[r] = (min(xs), min(ys), max(xs), max(ys))
    for p in f.Pads():
        c, s = p.GetPosition(), p.GetSize(pcbnew.F_Cu)
        sx, sy = t(s.x) / 2, t(s.y) / 2
        if round(p.GetOrientationDegrees()) % 180 == 90:
            sx, sy = sy, sx
        x, y, n = t(c.x) - OX, t(c.y) - OY, p.GetNetname()
        hole = p.GetAttribute() == pcbnew.PAD_ATTRIB_NPTH
        draw.append((x - sx, y - sy, x + sx, y + sy, min(sx, sy), (120, 120, 120) if hole else (200, 30, 20) if sect(n) else (20, 70, 200)))
        if not hole:
            pads.append((r, p.GetNumber(), n, p, sect(n)))
for x1, y1, x2, y2, rr, c in draw:
    d.rounded_rectangle([X(x1), Y(y1), X(x2), Y(y2)], radius=int(rr * Z), fill=c)
for r, (x1, y1, x2, y2) in col.items():
    cx, cy = (x1 + x2) / 2, (y1 + y2) / 2
    if r == "JWS1":
        ctext(cx, 45, "ESP32-S3-ETH-M", F(26, 1))
        ctext(cx, 48, "sur supports", F(22))
        ctext(cx, 82, "RJ45 + USB-C", F(24, 1))
        ctext(cx, 15.4, "antenne", F(22, 1), (150, 100, 0))
    elif r == "PS1":
        ctext(cx, cy - 1.2, "PS1  IRM-05-5", F(28, 1))
        ctext(cx, cy + 1.5, "hauteur 21,5", F(24))
    elif y2 - y1 > (x2 - x1) * 1.6 and r[0] in "RD":
        tm = Image.new("RGBA", (90, 26), (0, 0, 0, 0))
        ImageDraw.Draw(tm).text((45, 13), r, font=F(20, 1), fill=(0, 0, 0), anchor="mm")
        tm = tm.rotate(90, expand=True)
        im.paste(tm, (int(X(cx) - tm.width / 2), int(Y(cy) - tm.height / 2)), tm)
    else:
        ctext(cx + (-1.6 if r in ("OC81", "OC82") else 0), cy + (1.9 if r.startswith("OC") else -3.2 if r in ("J1", "J2", "J3", "J4", "J5") else 2.2 if r in ("U1", "F0") else 0), r, F(22, 1))
d.line([(X(x), Y(y)) for x, y in BAR], fill=(230, 0, 0), width=5)
for r, s in {"J5": "FP8 | FP7", "J4": "FP6 | FP5", "J3": "FP4 | FP3", "J2": "FP2 | FP1", "J1": "N | L"}.items():
    x1, y1, x2, y2 = col[r]
    ctext((x1 + x2) / 2, -2.6, s, F(24, 1), (180, 0, 0))
for x1, x2, n in ((1.3, 50.8, "fenêtre 1"), (53.7, 101.6, "fenêtre 2"), (104.6, 155.4, "fenêtre 3")):
    for yy in (-0.7, 87.2):
        d.line([X(x1), Y(yy), X(x2), Y(yy)], fill=(0, 140, 0), width=6)
    ctext((x1 + x2) / 2, 88.6, n + " (relevée à l'échelle)", F(20), (0, 110, 0))


def dim(x1, y1, x2, y2, s, dx=0, dy=0):
    d.line([X(x1), Y(y1), X(x2), Y(y2)], fill=(0, 0, 0), width=2)
    for x, y in ((x1, y1), (x2, y2)):
        d.ellipse([X(x) - 5, Y(y) - 5, X(x) + 5, Y(y) + 5], fill=(0, 0, 0))
    qx, qy = (x1 + x2) / 2 + dx, (y1 + y2) / 2 + dy
    bb = d.textbbox((X(qx), Y(qy)), s, font=F(22, 1), anchor="mm")
    d.rectangle([bb[0] - 4, bb[1] - 3, bb[2] + 4, bb[3] + 3], fill=(255, 255, 255, 230))
    ctext(qx, qy, s, F(22, 1))


dim(0, -6, 156, -6, "156,0")
dim(-5, 0, -5, 86.5, "86,5")
dim(29.35, 92, 37.55, 92, "pas 8,20", 7.5)
dim(0.1, 92, 21.1, 92, "21,0")
dim(0, 94.5, 106.9, 94.5, "106,9 (bord IRM)")
dim(159, 0, 159, 36.0, "36,0", 2.2)
dim(159, 36.0, 159, 43.62, "7,62", 2.2)
dim(159, 45.55, 159, 70.95, "25,4", 2.2)
y0 = H * Z + 2 * M - 5
for k, (s, bo) in enumerate((
        ("Rouge : pastilles secteur.   Bleu : très basse tension.   Trait rouge : barrière d'isolement (6 mm minimum, contrôlée par DRC).", 1),
        ("Pointillés gris : limites de la partie haute du coffret (y = 14,75 et 71,75). Au-delà, hauteur libre 15,7 mm au-dessus du PCB.   Jaune : zone sans cuivre (antenne).", 0),
        ("Hauteurs (mm) : IRM 21,5 ; U1 environ 20 (supposé) ; borniers 13,8 ; fusible 12,7 ; C1 C2 11 ; supports + circuits 10 (supposé) ; carte ESP32 12,7 (supposé).", 0),
        ("Vue de dessus. Zones 8 à 1 de gauche à droite : vues de l'extérieur, côté borniers, elles se lisent 1 à 8 de gauche à droite. H1, H2 : rectangle = encombrement de la tête de vis.", 0))):
    d.text((M, y0 + 37 * k), s, font=F(26, bo), fill=(0, 0, 0))
im.save(sys.argv[2])


# ---- distances recalculees, sans passer par le DRC (pastilles = capsules) ----
def cap(p):
    c, s = p.GetPosition(), p.GetSize(pcbnew.F_Cu)
    sx, sy, a = t(s.x), t(s.y), math.radians(p.GetOrientationDegrees())
    rr, L = min(sx, sy) / 2, abs(sx - sy) / 2
    vx, vy = (math.cos(a), -math.sin(a)) if sx >= sy else (math.sin(a), math.cos(a))
    x, y = t(c.x) - OX, t(c.y) - OY
    return [(x + vx * L * k / 4, y + vy * L * k / 4) for k in range(-4, 5)], rr


Q = [(r, n, s) + cap(p) for r, n, net, p, s in pads]
res = sorted((min(math.dist(i, j) for i in A[3] for j in B[3]) - A[4] - B[4], A[0] + "." + A[1], B[0] + "." + B[1])
             for A in Q if A[2] for B in Q if not B[2])
print("pastilles secteur", sum(q[2] for q in Q), "TBT", sum(not q[2] for q in Q))
print("min secteur/TBT", [(round(a, 3), x, y) for a, x, y in res[:3]])
print("hors meme composant", [(round(a, 2), x, y) for a, x, y in res if x.split(".")[0] != y.split(".")[0]][:8])
print("secteur / broches ESP32", [(round(a, 2), x, y) for a, x, y in res if y.startswith("JWS1")][0])
print("secteur / centre antenne", min((round(math.dist(j, (10.6, 14.5)) - q[4], 1), q[0]) for q in Q if q[2] for j in q[3]))
for r in ("PS1", "U1", "F0"):
    print(r, [round(v, 2) for v in col[r]])
