"""Etape 3 : placement seul. Usage : python.exe make_pcb.py <netlist.net> <sortie.kicad_pcb>
Repere : origine = coin haut gauche du PCB, x vers la droite, y vers le bas, vue de dessus, bord secteur en haut."""
import os, sys
import pcbnew
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sx import parse, kids, kid
ROOT = os.path.dirname(HERE)
KI = os.path.expandvars(r"%LOCALAPPDATA%\Programs\KiCad\10.0\share\kicad\footprints")
OX, OY = 60.0, 50.0   # position du PCB sur la feuille
W, H = 156.0, 86.5
mm = pcbnew.FromMM


def V(x, y):
    return pcbnew.VECTOR2I(mm(x + OX), mm(y + OY))


# ---- cotes maitresses ----
XR, PITCH, YM = 29.35, 8.20, 36.0         # rangee de 14 optos : 1re broche 6, pas, ligne des broches secteur
X8, YA = 23.2, 18.0                       # zone 8 : 2 optos tournes
CHAIN = ["72", "71", "62", "61", "52", "51", "42", "41", "32", "31", "22", "21", "12", "11"]
P = {}   # ref : (x, y, rotation) de la pastille 1 (origine de l'empreinte)
P["JWS1"] = (0.1 + 1.61 + 17.78, 86.5 - 19.87, 180)
P["H1"] = (148.7, 13.35, 0)
P["H2"] = (7.3, 73.15, 0)
for j, x in (("J5", 41.34), ("J4", 67.44), ("J3", 92.84), ("J2", 119.84), ("J1", 140.16)):
    P[j] = (x, 4.9, 180)
P["F0"] = (137.5, 15.75, 180)
P["PS1"] = (149.0, 59.75, 180)
for k, t in enumerate(CHAIN):
    x = round(XR + PITCH * k, 2)
    P["OC" + t] = (x, YM + 7.62, 90)
    dx = round(x + (6.6 if k < 10 else 5.08), 2)
    P["D" + t] = (dx, 22.24, 270) if t[1] == "1" else (dx, 32.4, 90)
    P["RL" + t] = (x, 57.66, 90) if k < 10 else (round(x + 0.0, 2), 84.6, 90)
P["OC82"] = (X8, YA, 0)
P["OC81"] = (X8, YA + PITCH, 0)
P["D82"] = (34.6, 14.0, 0)                # negative : cathode (1) cote triac
P["D81"] = (44.76, 18.0, 180)             # positive : anode (2) cote triac
P["RL82"] = (23.3, 57.66, 90)
P["RL81"] = (26.3, 57.66, 90)
P["U5"] = (24.6, 69.0, 90)
P["U4"] = (48.0, 69.0, 90)
P["U3"] = (82.5, 69.0, 90)
P["U2"] = (72.0, 76.42, 270)
P["U1"] = (70.9, 63.4, 0)
P["C4"] = (70.0, 70.5, 0)
P["C2"] = (76.6, 69.0, 0)
P["C1"] = (80.6, 79.5, 0)
P["C3"] = (51.5, 72.9, 180)
P["DPWR1"] = (90.0, 76.2, 0)
P["RPU1"] = (24.2, 76.0, 0)
P["RPU2"] = (24.2, 80.0, 0)

net = parse(open(sys.argv[1], encoding="utf-8").read())[0]
board = pcbnew.NewBoard(sys.argv[2])
nets, pad2net = {}, {}
for n in kids(kid(net, "nets"), "net"):
    nm = kid(n, "name")[1]
    ni = pcbnew.NETINFO_ITEM(board, nm)
    board.Add(ni)
    nets[nm] = ni
    for q in kids(n, "node"):
        pad2net[(kid(q, "ref")[1], kid(q, "pin")[1])] = nm
refs = set()
for c in kids(kid(net, "components"), "comp"):
    ref, fpn = kid(c, "ref")[1], kid(c, "footprint")[1]
    lib, name = fpn.split(":")
    d = os.path.join(ROOT, "FilPilote.pretty") if lib == "FilPilote" else os.path.join(KI, lib + ".pretty")
    f = pcbnew.FootprintLoad(d, name)
    f.SetFPID(pcbnew.LIB_ID(lib, name))
    f.SetReference(ref)
    f.SetValue(kid(c, "value")[1])
    f.SetPath(pcbnew.KIID_PATH("/" + kid(c, "tstamps")[1]))
    for p in f.Pads():
        k = (ref, p.GetNumber())
        if k in pad2net:
            p.SetNet(nets[pad2net[k]])
    for q in kids(c, "property"):
        if kid(q, "name")[1] == "MPN":
            f.SetField("MPN", kid(q, "value")[1])
            f.GetField("MPN").SetVisible(False)
    if ref == "PS1":   # modele 3D absent de l'installation KiCad : volume simple 45,7 x 25,4 x 21,5
        f.Models().clear()
        m = pcbnew.FP_3DMODEL()
        m.m_Filename = "${KIPRJMOD}/3d/IRM-05-5.wrl"
        f.Models().push_back(m)
    f.SetExcludedFromBOM(False)
    board.Add(f)
    x, y, r = P[ref]
    f.SetOrientationDegrees(r)
    f.SetPosition(V(x, y))
    f.Reference().SetLayer(pcbnew.F_SilkS)
    f.Reference().SetTextSize(pcbnew.VECTOR2I(mm(1), mm(1)))
    f.Reference().SetTextThickness(mm(0.15))
    if ref[0] == "R" and ref[1] == "L" or ref[0] == "D":
        f.Reference().SetPosition(f.GetBoundingBox(False).GetCenter())
        f.Reference().SetTextAngleDegrees(90 if r in (90, 270) else 0)
    f.Reference().SetKeepUpright(True)
    refs.add(ref)
assert refs == set(P), refs ^ set(P)


def line(x1, y1, x2, y2, layer, w):
    s = pcbnew.PCB_SHAPE(board, pcbnew.SHAPE_T_SEGMENT)
    s.SetStart(V(x1, y1)); s.SetEnd(V(x2, y2)); s.SetLayer(layer); s.SetWidth(mm(w)); board.Add(s)


def text(t, x, y, layer, h=1.2):
    s = pcbnew.PCB_TEXT(board)
    s.SetText(t); s.SetPosition(V(x, y)); s.SetLayer(layer)
    s.SetTextSize(pcbnew.VECTOR2I(mm(h), mm(h))); s.SetTextThickness(mm(h * 0.15)); board.Add(s)


s = pcbnew.PCB_SHAPE(board, pcbnew.SHAPE_T_RECT)
s.SetStart(V(0, 0)); s.SetEnd(V(W, H)); s.SetLayer(pcbnew.Edge_Cuts); s.SetWidth(mm(0.1)); board.Add(s)
# barriere d'isolement (trait de reperage, sans cuivre)
BAR = [(27.0, 0), (27.0, 33.2), (28.9, 39.81), (145.0, 39.81), (145.0, 67.6), (156, 67.6)]
for a, b in zip(BAR, BAR[1:]):
    line(a[0], a[1], b[0], b[1], pcbnew.Cmts_User, 0.3)
# coffret : limites de la partie haute
for y in (14.75, 71.75):
    line(0, y, W, y, pcbnew.Dwgs_User, 0.15)
board.GetDesignSettings().SetBoardThickness(mm(1.6))
board.GetDesignSettings().m_CopperEdgeClearance = mm(0.5)
pcbnew.SaveBoard(sys.argv[2], board)
print(len(refs), "empreintes placees")
