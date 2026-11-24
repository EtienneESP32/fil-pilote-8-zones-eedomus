"""Etape 4c : plans de masse GND (deux faces), cote tres basse tension seulement, et zone sans cuivre autour de H2.
Usage : zones.py entree.kicad_pcb sortie.kicad_pcb"""
import sys
import wx, pcbnew
mm = pcbnew.FromMM
V = lambda x, y: pcbnew.VECTOR2I(mm(60 + x), mm(50 + y))
b = pcbnew.LoadBoard(sys.argv[1])
gnd = b.GetNetsByName()["GND"]
ls = pcbnew.LSET(); ls.AddLayer(pcbnew.F_Cu); ls.AddLayer(pcbnew.B_Cu)
k = pcbnew.ZONE(b)
k.SetIsRuleArea(True); k.SetZoneName("VIS_H2")
k.SetDoNotAllowTracks(True); k.SetDoNotAllowVias(True); k.SetDoNotAllowZoneFills(True)
k.SetDoNotAllowPads(False); k.SetDoNotAllowFootprints(False); k.SetLayerSet(ls)
for p in ((3.5, 66.2), (11.1, 66.2), (11.1, 80.1), (3.5, 80.1)):
    k.AppendCorner(V(*p), -1)
b.Add(k)
for layer in (pcbnew.F_Cu, pcbnew.B_Cu):
    z = pcbnew.ZONE(b)
    z.SetNet(gnd); z.SetLayer(layer); z.SetZoneName("GND_" + ("F" if layer == pcbnew.F_Cu else "B"))
    for p in ((0.6, 21), (22, 21), (22, 45.2), (141, 45.2), (141, 70), (155.4, 70), (155.4, 85.9), (0.6, 85.9)):
        z.AppendCorner(V(*p), -1)
    z.SetLocalClearance(mm(0.3)); z.SetMinThickness(mm(0.3))
    z.SetPadConnection(pcbnew.ZONE_CONNECTION_THERMAL)
    z.SetThermalReliefGap(mm(0.4)); z.SetThermalReliefSpokeWidth(mm(0.6))
    z.SetIslandRemovalMode(pcbnew.ISLAND_REMOVAL_MODE_ALWAYS)
    b.Add(z)
pcbnew.ZONE_FILLER(b).Fill(b.Zones())
pcbnew.SaveBoard(sys.argv[2], b)
print("plans", [(z.GetZoneName(), round(z.GetFilledArea() / 1e12)) for z in b.Zones() if not z.GetIsRuleArea()])
