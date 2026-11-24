"""Etape 4d : serigraphie. Usage : silk.py entree.kicad_pcb sortie.kicad_pcb"""
import sys
import wx, pcbnew
mm, t = pcbnew.FromMM, pcbnew.ToMM
V = lambda x, y: pcbnew.VECTOR2I(mm(60 + x), mm(50 + y))
b = pcbnew.LoadBoard(sys.argv[1])
F = {f.GetReference(): f for f in b.GetFootprints()}


def ref(r, x, y, a=0, h=1.0):
    q = F[r].Reference()
    q.SetKeepUpright(False)
    q.SetTextAngleDegrees(a)
    q.SetTextSize(pcbnew.VECTOR2I(mm(h), mm(h)))
    q.SetTextThickness(mm(0.15))
    q.SetPosition(V(x, y))


def text(s, x, y, h=1.2, layer=pcbnew.F_SilkS, a=0):
    q = pcbnew.PCB_TEXT(b)
    q.SetText(s); q.SetLayer(layer); q.SetPosition(V(x, y))
    q.SetTextSize(pcbnew.VECTOR2I(mm(h), mm(h))); q.SetTextThickness(mm(max(0.15, h * 0.15)))
    q.SetTextAngleDegrees(a)
    q.SetMirrored(layer == pcbnew.B_SilkS)
    b.Add(q)


for r, f in F.items():
    if r.startswith(("OC", "U2", "U3", "U4", "U5")):
        bb = [p.GetPosition() for p in f.Pads()]
        ref(r, (min(t(p.x) for p in bb) + max(t(p.x) for p in bb)) / 2 - 60, (min(t(p.y) for p in bb) + max(t(p.y) for p in bb)) / 2 - 50)
for r in ("H1", "H2"):
    F[r].Reference().SetVisible(False)
for r, x, y in (("U1", 73.4, 59.3), ("C2", 77.6, 72.6), ("C4", 71.25, 73.2), ("C1", 81.6, 83.1), ("C3", 46.4, 72.9), ("JWS1", 10.6, 44),
                ("RPU1", 29.28, 76.0), ("RPU2", 29.28, 80.0), ("PS1", 129, 56), ("F0", 119.6, 18.6),
                ("J5", 54.4, 6.6), ("J4", 75.4, 6.6), ("J3", 100.8, 6.6), ("J2", 127.5, 6.6), ("J1", 146.2, 1.6)):
    ref(r, x, y)
ref("DPWR1", 95.75, 76.2, 0, 0.8)
for s, x, y in (("FP8 FP7", 54.4, 4.6), ("FP6 FP5", 75.4, 4.6), ("FP4 FP3", 100.8, 4.6), ("FP2 FP1", 127.5, 4.6)):
    text(s, x, y, 1.1)
text("N  L", 146.2, 5.0, 1.1)
text("T 250 mA", 130.2, 18.6, 1.0)
text("SECTEUR 230 V", 79.5, 15.2, 2.0)
text("FIL PILOTE 8 ZONES  v4", 79.5, 18.4, 1.3)
text("Coupez le 230 V avant d'ouvrir", 79.5, 12.4, 1.0)
text("ESP32-S3-ETH-M", 10.6, 46.5, 1.0)
text("Visser H2 avant", 13.3, 83.4, 0.9)
text("SECTEUR 230 V", 79.5, 15.2, 2.0, pcbnew.B_SilkS)
text("TRES BASSE TENSION", 60, 56, 1.5, pcbnew.B_SilkS)
pcbnew.SaveBoard(sys.argv[2], b)
