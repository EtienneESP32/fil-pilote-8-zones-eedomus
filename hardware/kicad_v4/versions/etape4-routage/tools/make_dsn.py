"""Etape 4b : copie de travail pour l'autorouteur (tres basse tension seulement).
Le cuivre secteur gonfle de 6,01 mm devient une zone interdite sur les DEUX faces ; les nets secteur sont retires.
Usage : make_dsn.py carte_avec_secteur.kicad_pcb copie.kicad_pcb sortie.dsn"""
import sys, fnmatch
import wx, pcbnew
SECT = ["MAINS_L", "MAINS_N", "PHASE_PROT", "MT_*", "FP?", "unconnected-(OC*Pad5)"]
# GND : tronc en pistes entre ces pastilles ; les autres pastilles GND sont reliees par les plans
GNDT = {("PS1", "3"), ("C1", "2"), ("U1", "2"), ("U3", "8"), ("U4", "8"), ("U5", "8"), ("JWS1", "3"), ("U2", "10")}
mm = pcbnew.FromMM
b = pcbnew.LoadBoard(sys.argv[1])
sect = lambda n: any(fnmatch.fnmatchcase(n, p) for p in SECT)
ps = pcbnew.SHAPE_POLY_SET()
for f in b.GetFootprints():
    for p in f.Pads():
        if p.GetNetname() == "GND" and (f.GetReference(), p.GetNumber()) not in GNDT:
            p.SetNetCode(0)   # relie par les plans de masse
        if sect(p.GetNetname()):
            p.TransformShapeToPolygon(ps, pcbnew.F_Cu, mm(6.01), mm(0.005), pcbnew.ERROR_OUTSIDE)
            p.SetNetCode(0)
for t in list(b.GetTracks()):
    assert sect(t.GetNetname())
    t.TransformShapeToPolygon(ps, t.GetLayer(), mm(6.01), mm(0.005), pcbnew.ERROR_OUTSIDE)
    b.Delete(t)
ps.Simplify()
ps.Simplify()


def area(pts):
    z = pcbnew.ZONE(b)
    z.SetIsRuleArea(True)
    for fn in (z.SetDoNotAllowTracks, z.SetDoNotAllowVias, z.SetDoNotAllowZoneFills):
        fn(True)
    z.SetDoNotAllowPads(False)
    z.SetDoNotAllowFootprints(False)
    ls = pcbnew.LSET(); ls.AddLayer(pcbnew.F_Cu); ls.AddLayer(pcbnew.B_Cu)
    z.SetLayerSet(ls)
    for v in pts:
        z.AppendCorner(v, -1)
    b.Add(z)


for i in range(ps.OutlineCount()):
    o = ps.Outline(i)
    print("zone interdite", i, o.PointCount(), "points")
    area([pcbnew.VECTOR2I(o.CPoint(k).x, o.CPoint(k).y) for k in range(o.PointCount())])
V = lambda x, y: pcbnew.VECTOR2I(mm(60 + x), mm(50 + y))
area([V(3.5, 66.2), V(11.1, 66.2), V(11.1, 80.1), V(3.5, 80.1)])     # tete de vis H2
area([V(0, 0), V(21.2, 0), V(21.2, 17.3), V(0, 17.3)])               # antenne
for r in ((0, 0, 156, 0.8), (0, 85.7, 156, 86.5), (0, 0, 0.8, 86.5), (155.2, 0, 156, 86.5)):   # bords
    area([V(r[0], r[1]), V(r[2], r[1]), V(r[2], r[3]), V(r[0], r[3])])
pcbnew.SaveBoard(sys.argv[2], b)
print("DSN", pcbnew.ExportSpecctraDSN(b, sys.argv[3]))
