"""Etape 5 : controle de chaque pastille de la carte contre docs/13 et les brochages des fiches.
Valeurs attendues ecrites ici a la main, sans relire make_lib.py ni la bibliotheque.
Usage : check_pads.py carte.kicad_pcb"""
import sys
import wx, pcbnew
sys.stdout.reconfigure(encoding="utf-8")
t = pcbnew.ToMM
b = pcbnew.LoadBoard(sys.argv[1])
Z = ["%d%d" % (i, j) for i in range(1, 9) for j in (1, 2)]


def dip(n):   # vue de dessus, broche 1 en haut a gauche : descend a gauche, remonte a droite
    h = n // 2
    return {str(k): ((0, (k - 1) * 2.54) if k <= h else (7.62, (n - k) * 2.54)) for k in range(1, n + 1)}


# ---- geometrie attendue : positions, pastille, percage ----
two = lambda p: {"1": (0, 0), "2": (p, 0)}
GEO = {
    "J": (two(5.08), (2.0, 3.0), 1.3), "F": (two(22.5), (3.0, 3.0), 1.35),
    "PS": ({"1": (0, 0), "2": (0, 10.75), "3": (38.5, 10.75), "4": (38.5, 2.75)}, (3.0, 3.0), 1.5),
    "D": (two(10.16), (2.2, 2.2), 1.1), "R": (two(10.16), (1.6, 1.6), 0.8),
    "U1": ({"1": (0, 0), "2": (2.54, 0), "3": (5.08, 0)}, (1.9, 2.4), 1.3),
    "CP": (two(2.0), (1.6, 1.6), 0.8), "CD": (two(2.5), (1.6, 1.6), 0.8),
    "OC": (dip(6), (1.6, 1.6), 1.0), "U2": (dip(28), (1.6, 1.6), 1.0), "U": (dip(16), (1.6, 1.6), 1.0),
    "JWS": ({str(k): ((0, (k - 1) * 2.54) if k <= 20 else (17.78, (40 - k) * 2.54)) for k in range(1, 41)}, (1.7, 1.7), 1.0),
}


def geo(r):
    if r in ("U1", "U2"):
        return GEO[r]
    if r in ("C1", "C2"):
        return GEO["CP"]
    if r in ("C3", "C4"):
        return GEO["CD"]
    for k in ("JWS", "PS", "OC", "J", "F", "D", "R", "U"):
        if r.startswith(k):
            return GEO[k]


# ---- nets attendus, par fonction de broche des fiches ----
N = {}
put = lambda r, **kw: N.update({(r, k.strip("_")): v for k, v in kw.items()})
put("J1", _1="MAINS_L", _2="MAINS_N")
for j, (a, c) in {"J2": (1, 2), "J3": (3, 4), "J4": (5, 6), "J5": (7, 8)}.items():
    put(j, _1="FP%d" % a, _2="FP%d" % c)
put("F0", _1="MAINS_L", _2="PHASE_PROT")
put("PS1", _1="MAINS_N", _2="PHASE_PROT", _3="GND", _4="LOCAL_5V")     # AC/N, AC/L, -V, +V
put("DPWR1", _1="VSYS", _2="LOCAL_5V")                                # cathode, anode
put("U1", _1="VSYS", _2="GND", _3="3V3_OPTO")                         # entree, masse, sortie
put("C1", _1="VSYS", _2="GND"); put("C4", _1="VSYS", _2="GND")
put("C2", _1="3V3_OPTO", _2="GND"); put("C3", _1="3V3_OPTO", _2="GND")
put("RPU1", _1="3V3_OPTO", _2="SDA"); put("RPU2", _1="3V3_OPTO", _2="SCL")
for z in Z:
    put("OC" + z, _1="LEDA_" + z, _2="LEDK_" + z, _3=None, _4="MT_" + z, _5=None, _6="PHASE_PROT")
    put("RL" + z, _1="VSYS", _2="LEDA_" + z)
    fp = "FP" + z[0]
    put("D" + z, _1=fp if z[1] == "1" else "MT_" + z, _2="MT_" + z if z[1] == "1" else fp)   # 1 = cathode
# MCP23017 DS20001952 : 21-28 GPA0-7, 1-8 GPB0-7, 9 VDD, 10 VSS, 12 SCL, 13 SDA, 15-17 A0-A2, 18 RESET
for k in range(8):
    N[("U2", str(28 - k))] = "DRV_" + Z[k]
    N[("U2", str(1 + k))] = "DRV_" + Z[8 + k]
for p, v in {9: "3V3_OPTO", 10: "GND", 11: None, 12: "SCL", 13: "SDA", 14: None, 15: "GND", 16: "GND", 17: "GND", 18: "3V3_OPTO", 19: None, 20: None}.items():
    N[("U2", str(p))] = v
# ULN2003A : 1-7 entrees, 8 masse, 9 COM, sortie = 17 - entree
for u, ch in (("U3", Z[0:7]), ("U4", Z[7:14]), ("U5", Z[14:16])):
    N[(u, "8")], N[(u, "9")] = "GND", "VSYS"
    for i in range(1, 8):
        k = 7 - i
        N[(u, str(i))] = "DRV_" + ch[k] if k < len(ch) else "GND"
        N[(u, str(17 - i))] = "LEDK_" + ch[k] if k < len(ch) else None
# U5 : les deux canaux utilises sont les entrees 1 et 2
for i in range(1, 8):
    k = 2 - i
    N[("U5", str(i))] = "DRV_" + Z[14 + k] if k >= 0 else "GND"
    N[("U5", str(17 - i))] = "LEDK_" + Z[14 + k] if k >= 0 else None
for k in range(1, 41):
    N[("JWS1", str(k))] = "GND" if k in (3, 8, 13, 18, 23, 28, 33, 38) else {25: "SDA", 26: "SCL", 39: "VSYS"}.get(k)

bad, n, npth, seen = [], 0, [], set()
for f in b.GetFootprints():
    r = f.GetReference()
    if f.IsFlipped():
        bad.append((r, "au dos"))
    for p in f.Pads():
        s, dr = p.GetSize(pcbnew.F_Cu), p.GetDrillSize()
        q = p.GetFPRelativePosition()
        if p.GetAttribute() == pcbnew.PAD_ATTRIB_NPTH:
            npth.append((r, round(t(dr.x), 2), round(t(dr.y), 2)))
            continue
        n += 1
        k = p.GetNumber()
        pos, size, drill = geo(r)
        seen.add((r, k))
        chk = lambda c, m: None if c else bad.append((r, k, m))
        chk(k in pos and abs(t(q.x) - pos[k][0]) < .001 and abs(t(q.y) - pos[k][1]) < .001, ("position", t(q.x), t(q.y)))
        chk(abs(t(s.x) - size[0]) < .001 and abs(t(s.y) - size[1]) < .001, ("pastille", t(s.x), t(s.y)))
        chk(abs(t(dr.x) - drill) < .001 and abs(t(dr.y) - drill) < .001, ("percage", t(dr.x)))
        chk(p.IsOnLayer(pcbnew.F_Cu) and p.IsOnLayer(pcbnew.B_Cu) and p.IsOnLayer(pcbnew.F_Mask) and p.IsOnLayer(pcbnew.B_Mask), "couches")
        want, got = N.get((r, k), "?"), p.GetNetname()
        chk(got == want if want else got.startswith("unconnected-("), ("net", got, want))
manq = [(r, k) for r, k in N if (r, k) not in seen]
print("pastilles controlees :", n, "/ attendues", len(N), "| trous non metallises :", npth)
print("manquantes :", manq)
print("ECARTS :", len(bad))
for x in bad:
    print("   ", x)
