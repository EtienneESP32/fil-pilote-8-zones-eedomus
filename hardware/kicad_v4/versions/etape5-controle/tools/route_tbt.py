"""Etape 4b : importe les pistes TBT de l'autorouteur (route/tbt.ses) et ajoute le tronc VSYS vers l'ESP32.
A lancer AVANT route_mains.py (l'import SES efface les pistes existantes).
Usage : route_tbt.py entree.kicad_pcb sortie.kicad_pcb"""
import sys, os
import wx, pcbnew
mm = pcbnew.FromMM
b = pcbnew.LoadBoard(sys.argv[1])
assert pcbnew.ImportSpecctraSES(b, os.path.join(os.path.dirname(os.path.abspath(__file__)), "route", "tbt.ses"))
NET = b.GetNetsByName()


def add(net, w, *pts):
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        s = pcbnew.PCB_TRACK(b)
        s.SetStart(pcbnew.VECTOR2I(mm(x1 + 60), mm(y1 + 50)))
        s.SetEnd(pcbnew.VECTOR2I(mm(x2 + 60), mm(y2 + 50)))
        s.SetLayer(pcbnew.F_Cu); s.SetWidth(mm(w)); s.SetNet(NET[net]); s.SetLocked(True)
        b.Add(s)


# tronc VSYS direct C1 -> ESP32 (110 mm environ), et GND entre les broches 15 a 17 de U2
add("VSYS", 1.5, (1.71, 64.09), (10.5, 64.09), (14, 67.59), (14, 83.4))
add("VSYS", 0.8, (14, 83.4), (16.15, 85.55), (76.4, 85.55), (80.6, 81.35))
add("VSYS", 1.5, (80.6, 81.35), (80.6, 79.5))
add("GND", 0.8, (38.98, 84.04), (44.06, 84.04))
pcbnew.SaveBoard(sys.argv[2], b)
print("pistes TBT", len(list(b.GetTracks())))
