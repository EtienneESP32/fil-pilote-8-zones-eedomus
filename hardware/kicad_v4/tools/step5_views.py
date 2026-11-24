"""Etape 5 : copies de travail pour la vue 3D dans le coffret et l'impression 1:1 (la carte n'est pas modifiee).
Usage : step5_views.py carte.kicad_pcb dossier_de_travail (python de KiCad 10)
Coffret CNMB/9, cotes lues p. 393 et 394 : 159.2 x 90, paliers 26.5 / 48 / 58, largeurs 90 / 62 / 45, cache 52.8 x 13.8 x 20, carte A a 10.8.
A l'echelle du dessin : epaisseurs, x des fenetres, languette interieure du cache."""
import os, sys
import wx, pcbnew
src, out = sys.argv[1], sys.argv[2]
mm = pcbnew.FromMM
OX, OY, W, H = 60.0, 50.0, 156.0, 86.5
PCB0 = -12.4          # base du coffret sous le dessus du PCB, si 10,8 = dessous du PCB (cas le plus serre)
CW = ((26.05, "1"), (77.65, "2"), (130.0, "3"))       # centres des fenetres
LIP = (10.0, 12.5, 15.8, 10.6)       # languette : y debut, y fin, demi-longueur, profondeur sous le dessus du cache
U = 2.54
B_ = []


def box(x1, y1, z1, x2, y2, z2, c, tr):
    c_ = [(x1 + x2) / 2 / U, -(y1 + y2) / 2 / U, (z1 + z2) / 2 / U]
    s = [abs(x2 - x1) / U, abs(y2 - y1) / U, abs(z2 - z1) / U]
    B_.append("Transform { translation %.4f %.4f %.4f children [ Shape { appearance Appearance { material Material { diffuseColor %s transparency %.2f } } geometry Box { size %.4f %.4f %.4f } } ] }\n" % (*c_, c, tr, *s))


z = lambda h: PCB0 + h
G, T = "0.75 0.78 0.82", 0.72
X0, X1, Y0, Y1 = -1.6, 157.6, -1.75, 88.25
box(X0, Y0, z(5), X1, Y1, z(6.5), G, 0.0)                     # fond
for a in (Y0, Y1 - 1.5):
    box(X0, a, z(5), X1, a + 1.5, z(10.5), G, 0.3)          # bas des longs cotes
for a, s_ in ((Y0, 1), (Y1, -1)):                              # corps : paliers 62 puis 45
    box(X0, a + s_ * 14, z(26.5), X1, a + s_ * 15.5, z(48), G, T)
    box(X0, a + s_ * 14, z(46.5), X1, a + s_ * 22.5, z(48), G, T)
    box(X0, a + s_ * 22.5, z(48), X1, a + s_ * 24, z(58), G, T)
box(X0, Y0, z(5), X0 + 1.4, Y1, z(26.5), G, T)                # flanc gauche seulement (coupe cote droit)
box(X0, Y0 + 14, z(26.5), X0 + 1.4, Y1 - 14, z(48), G, T)
for cx, n in CW:                                                # caches : secteur x3, TBT fenetres 2 et 3
    for side in (0, 1):
        if side and n == "1":
            continue
        f = (lambda y: Y0 + y) if not side else (lambda y: Y1 - y)
        col = "0.95 0.65 0.15" if not side else "0.35 0.6 0.95"
        box(cx - 26.4, f(0.1), z(25.3), cx + 26.4, f(13.9), z(26.5), col, 0.45)
        box(cx - 22.7, f(0.1), z(10.8 + 4.5), cx + 22.7, f(1.6), z(25.3), col, 0.6)
        box(cx - LIP[2], f(LIP[0] + 1.75), z(26.5 - LIP[3]), cx + LIP[2], f(LIP[1] + 1.75), z(25.3), "0.9 0.1 0.1", 0.1)
open(os.path.join(out, "coffret.wrl"), "w").write("#VRML V2.0 utf8\n" + "".join(B_))

b = pcbnew.LoadBoard(src)
f = pcbnew.FOOTPRINT(b)
f.SetReference("BOX1"); f.Reference().SetVisible(False); f.Value().SetVisible(False)
m = pcbnew.FP_3DMODEL(); m.m_Filename = os.path.join(out, "coffret.wrl").replace("\\", "/")
f.Models().push_back(m)
b.Add(f); f.SetPosition(pcbnew.VECTOR2I(mm(OX), mm(OY)))
f.SetAttributes(pcbnew.FP_THROUGH_HOLE)
b.Save(os.path.join(out, "vue3d.kicad_pcb"))

# ---- impression 1:1 ----
b = pcbnew.LoadBoard(src)
V = lambda x, y: pcbnew.VECTOR2I(mm(x + OX), mm(y + OY))
UL = pcbnew.User_1 if hasattr(pcbnew, "User_1") else pcbnew.Dwgs_User
for d in list(b.GetDrawings()):
    if d.GetLayer() in (pcbnew.Dwgs_User, pcbnew.Cmts_User):
        b.Delete(d)


def seg(x1, y1, x2, y2, w=0.15, l=pcbnew.Dwgs_User):
    s = pcbnew.PCB_SHAPE(b, pcbnew.SHAPE_T_SEGMENT); s.SetStart(V(x1, y1)); s.SetEnd(V(x2, y2)); s.SetWidth(mm(w)); s.SetLayer(l); b.Add(s)


def dash(x1, y1, x2, y2):
    n = int(max(abs(x2 - x1), abs(y2 - y1)) / 2) + 1
    for k in range(0, n, 1):
        a, c = k / n, (k + .55) / n
        seg(x1 + (x2 - x1) * a, y1 + (y2 - y1) * a, x1 + (x2 - x1) * c, y1 + (y2 - y1) * c)


def txt(s, x, y, h=2.0, l=pcbnew.Dwgs_User):
    q = pcbnew.PCB_TEXT(b); q.SetText(s); q.SetPosition(V(x, y)); q.SetLayer(l)
    q.SetTextSize(pcbnew.VECTOR2I(mm(h), mm(h))); q.SetTextThickness(mm(h * .13)); q.SetHorizJustify(pcbnew.GR_TEXT_H_ALIGN_LEFT); b.Add(q)


for y in (14.75, 71.75):
    dash(0, y, W, y)
seg(0, 95, 100, 95, 0.2)
for k in range(0, 101, 5):
    seg(k, 95, k, 95 + (3 if k % 10 == 0 else 1.5), 0.2)
txt("0", -0.6, 100); txt("100 mm : mesurer cette règle d'abord (imprimer à 100 %)", 98, 100.5)
txt("Fil pilote 8 zones v4 : impression 1:1, vue de dessus. Carte 156,0 x 86,5 mm, bord secteur en haut.", -40, -14, 2.4)
txt("Poser chaque pièce : les broches doivent tomber dans les ronds (trous au diamètre réel).", -40, -9)
txt("Pointillés longs : paroi du corps haut du coffret.", -40, -5, 1.8)
txt("A VÉRIFIER SUR LE VRAI COFFRET :", -40, 108, 2.4)
for i, s in enumerate(("1. Carte posée dans le fond : elle entre, et les vis tombent dans les oblongs H1 et H2.",
                       "2. Caches montés : les 5 borniers sont en face des fenêtres et des trous de tournevis.",
                       "3. Du dessus de la carte au dessous du cache : 13,8 mm au moins (borniers). Mesuré : ______ mm",
                       "4. Support d'opto : plus petite distance entre métaux des deux rangées ______ mm (6 mm demandés).")):
    txt(s, -40, 113 + 4.5 * i)
for fp in b.GetFootprints():          # trous au diametre reel
    for p in fp.Pads():
        c, dr = p.GetPosition(), p.GetDrillSize()
        x, y = pcbnew.ToMM(c.x) - OX, pcbnew.ToMM(c.y) - OY
        if dr.x == dr.y:
            s = pcbnew.PCB_SHAPE(b, pcbnew.SHAPE_T_CIRCLE); s.SetCenter(c); s.SetEnd(pcbnew.VECTOR2I(c.x + dr.x // 2, c.y))
            s.SetWidth(mm(0.1)); s.SetLayer(pcbnew.Dwgs_User); b.Add(s)
        else:
            rx, ly = pcbnew.ToMM(dr.x) / 2, pcbnew.ToMM(dr.y) / 2 - pcbnew.ToMM(dr.x) / 2
            for sx in (-rx, rx):
                seg(x + sx, y - ly, x + sx, y + ly, 0.1)
            for sy in (-1, 1):
                s = pcbnew.PCB_SHAPE(b, pcbnew.SHAPE_T_ARC); s.SetArcGeometry(V(x - rx, y + sy * ly), V(x, y + sy * (ly + rx)), V(x + rx, y + sy * ly))
                s.SetWidth(mm(0.1)); s.SetLayer(pcbnew.Dwgs_User); b.Add(s)
b.Save(os.path.join(out, "print.kicad_pcb"))
