"""Cree FilPilote.pretty a partir des empreintes officielles KiCad (API pcbnew).
Reference : docs/13_Empreintes-etape1.md. Usage : python.exe make_lib.py (python de KiCad 10)."""
import os
import pcbnew

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "FilPilote.pretty")
KI = os.path.expandvars(r"%LOCALAPPDATA%\Programs\KiCad\10.0\share\kicad\footprints")
mm = pcbnew.FromMM
os.makedirs(OUT, exist_ok=True)
IO = pcbnew.PCB_IO_MGR.FindPlugin(pcbnew.PCB_IO_MGR.KICAD_SEXP)


def load(lib, name):
    f = pcbnew.FootprintLoad(os.path.join(KI, lib + ".pretty"), name)
    assert f is not None, name
    return f


def save(f, name, note):
    f.SetFPID(pcbnew.LIB_ID("FilPilote", name))
    f.SetLibDescription(f.GetLibDescription() + " | " + note)
    IO.FootprintSave(OUT, f)


def V(x, y):
    return pcbnew.VECTOR2I(mm(x), mm(y))


def plated(f):
    return [p for p in f.Pads() if p.GetAttribute() == pcbnew.PAD_ATTRIB_PTH]


# Supports DIP ASSMANN : trou 1,0 (plan ASS 0810 CO), pastille 1,6 inchangee
for n in (6, 16, 28):
    f = load("Package_DIP", "DIP-%d_W7.62mm_Socket" % n)
    for p in plated(f):
        p.SetDrillSize(V(1.0, 1.0))
        p.SetSize(pcbnew.F_Cu, V(1.6, 1.6))
    save(f, "DIP-%d_W7.62mm_Support_ASSMANN" % n, "trou 1,0 mm, ASSMANN ASS 0810 CO")

# Bornier Phoenix 1715721 : pastille ovale 2,0 x 3,0, trou 1,3
f = load("TerminalBlock_Phoenix", "TerminalBlock_Phoenix_MKDS-1,5-2-5.08_1x02_P5.08mm_Horizontal")
for p in plated(f):
    p.SetShape(pcbnew.F_Cu, pcbnew.PAD_SHAPE_OVAL)
    p.SetSize(pcbnew.F_Cu, V(2.0, 3.0))
    p.SetDrillSize(V(1.3, 1.3))
save(f, "Phoenix_1715721_MKDS-1.5-2-5.08", "pastille ovale 2,0 x 3,0")

# Porte-fusible Schurter 0031.8201 : trou 1,35
f = load("Fuse", "Fuseholder_Cylinder-5x20mm_Schurter_0031_8201_Horizontal_Open")
for p in plated(f):
    p.SetDrillSize(V(1.35, 1.35))
save(f, "Schurter_0031.8201", "trou 1,35 (fiche : 1,3 +0,1/0)")

# LF33CV TO-220 : trou 1,3, pastille 1,9 x 2,4
f = load("Package_TO_SOT_THT", "TO-220-3_Vertical")
for p in plated(f):
    p.SetDrillSize(V(1.3, 1.3))
    p.SetSize(pcbnew.F_Cu, V(1.9, 2.4))
save(f, "TO-220-3_Vertical_LF33CV", "trou 1,3 (broche 0,88 x 0,70 max)")

# Carte Waveshare ESP32-S3-ETH-M : vue de dessus (cote RJ45), RJ45 vers le haut (y negatif)
f = load("Connector_PinSocket_2.54mm", "PinSocket_1x20_P2.54mm_Vertical")
for g in list(f.GraphicalItems()):
    f.Delete(g)
src = {p.GetNumber(): p for p in f.Pads()}
for n in range(1, 21):
    p = src[str(n)]
    p.SetPosition(V(0, (n - 1) * 2.54))
    q = pcbnew.PAD(p)
    q.SetNumber(str(41 - n))
    q.SetShape(pcbnew.F_Cu, pcbnew.PAD_SHAPE_CIRCLE)
    q.SetPosition(V(17.78, (n - 1) * 2.54))
    f.Add(q)


def rect(x1, y1, x2, y2, layer, w):
    s = pcbnew.PCB_SHAPE(f, pcbnew.SHAPE_T_RECT)
    s.SetStart(V(x1, y1))
    s.SetEnd(V(x2, y2))
    s.SetLayer(layer)
    s.SetWidth(mm(w))
    f.Add(s)


def text(t, x, y, layer, h=1.0):
    s = pcbnew.PCB_TEXT(f)
    s.SetText(t)
    s.SetPosition(V(x, y))
    s.SetLayer(layer)
    s.SetTextSize(V(h, h))
    s.SetTextThickness(mm(0.15))
    f.Add(s)


X1, X2, Y1, Y2 = -1.61, 19.39, -19.87, 52.93
rect(X1, Y1, X2, Y2, pcbnew.F_Fab, 0.1)
rect(X1 - 0.12, Y1 - 0.12, X2 + 0.12, Y2 + 0.12, pcbnew.F_SilkS, 0.12)
rect(X1 - 0.5, Y1 - 0.5, X2 + 0.5, Y2 + 0.5, pcbnew.F_CrtYd, 0.05)
text("RJ45", 8.89, -14, pcbnew.F_SilkS)
text("ANTENNE", 8.89, 51, pcbnew.F_Fab)
f.Reference().SetPosition(V(8.89, -8))
f.Value().SetPosition(V(8.89, 20))
f.SetLibDescription("Waveshare ESP32-S3-ETH-M (SKU 34882) sur 2 x SSW-120-01-G-S, 72,8 x 21 mm, vue cote RJ45, broches cote USB-C")
f.SetFPID(pcbnew.LIB_ID("FilPilote", "Waveshare_ESP32-S3-ETH-M"))
IO.FootprintSave(OUT, f)

# Fixation coffret : trou oblong non metallise 4,0 x 10,4 (grand axe = y).
# Couvre Y = 18,3 (table CamdenBoss 2015) et Y = 11,9 (releve a l'echelle du dessin) ; vis No.6.
f = load("MountingHole", "MountingHole_3.2mm_M3")
for g in list(f.GraphicalItems()):
    f.Delete(g)
for p in f.Pads():
    p.SetShape(pcbnew.F_Cu, pcbnew.PAD_SHAPE_OVAL)
    p.SetDrillShape(pcbnew.PAD_DRILL_SHAPE_OBLONG)
    p.SetSize(pcbnew.F_Cu, V(4.0, 10.4))
    p.SetDrillSize(V(4.0, 10.4))
rect(-4.5, -8.5, 4.5, 8.5, pcbnew.F_CrtYd, 0.05)
save(f, "Fixation_CNMB_4.0x10.4", "oblong provisoire, vis No.6")

for n in sorted(os.listdir(OUT)):
    g = pcbnew.FootprintLoad(OUT, n[:-10])
    print(n, len(list(g.Pads())), {(pcbnew.ToMM(p.GetSize(pcbnew.F_Cu).x), pcbnew.ToMM(p.GetSize(pcbnew.F_Cu).y), pcbnew.ToMM(p.GetDrillSize().x), pcbnew.ToMM(p.GetDrillSize().y)) for p in g.Pads()})
