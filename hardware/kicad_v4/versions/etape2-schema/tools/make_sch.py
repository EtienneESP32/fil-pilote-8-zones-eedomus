"""Genere le schema FilPilote v4 avec les symboles officiels KiCad 10.
Usage : python.exe make_sch.py (python de KiCad 10)."""
import json, os, sys, uuid
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sx import Q, parse, dump, kids, kid, flat, pins

PRJ = "FilPilote_v4"
ROOT = os.path.dirname(HERE)
NS = uuid.UUID("5b1f0a52-7c1e-4d63-9a5e-0f11f11a0004")
_n = [0]


def uid(tag=""):
    _n[0] += 1
    return Q(str(uuid.uuid5(NS, "%d" % _n[0])))


SHEET = Q(str(uuid.uuid5(NS, "root")))
G = 1.27
out, libs = [], {}


def eff(size=1.27, hide=False, just=None):
    e = ["effects", ["font", ["size", size, size]]]
    if just:
        e.append(["justify", just])
    return e


# ---- symbole maison de la carte ESP32 ----
ESP = {1: "GPIO20", 2: "GPIO19", 3: "GND", 4: "GPIO48", 5: "GPIO47", 6: "GPIO46", 7: "GPIO45", 8: "GND", 9: "GPIO42", 10: "GPIO41",
       11: "GPIO40", 12: "GPIO39", 13: "GND", 14: "GPIO38", 15: "GPIO37", 16: "GPIO36", 17: "GPIO35", 18: "GND", 19: "GPIO34", 20: "GPIO33",
       21: "GPIO43", 22: "GPIO44", 23: "GND", 24: "GPIO0", 25: "GPIO1", 26: "GPIO2", 27: "GPIO3", 28: "GND", 29: "GPIO15", 30: "CHIP_PU",
       31: "GPIO18", 32: "GPIO16", 33: "GND", 34: "GPIO17", 35: "GPIO21", 36: "3V3", 37: "3V3_EN", 38: "GND", 39: "VSYS", 40: "VBUS"}


def esp_symbol():
    s = ["symbol", Q("ESP32-S3-ETH-M"), ["exclude_from_sim", "no"], ["in_bom", "yes"], ["on_board", "yes"]]
    for k, v, y in (("Reference", "JWS", 27.94), ("Value", "ESP32-S3-ETH-M", -27.94), ("Footprint", "FilPilote:Waveshare_ESP32-S3-ETH-M", 0),
                    ("Datasheet", "https://www.waveshare.com/wiki/ESP32-S3-ETH", 0), ("Description", "Carte Waveshare ESP32-S3-ETH-M, 2x20 broches", 0)):
        p = ["property", Q(k), Q(v), ["at", 0, y, 0]]
        if k not in ("Reference", "Value"):
            p.append(["hide", "yes"])
        p.append(eff())
        s.append(p)
    s.append(["symbol", Q("ESP32-S3-ETH-M_0_1"), ["rectangle", ["start", -12.7, 26.67], ["end", 12.7, -26.67], ["stroke", ["width", 0.254], ["type", "default"]], ["fill", ["type", "background"]]]])
    u = ["symbol", Q("ESP32-S3-ETH-M_1_1")]
    for n in range(1, 41):
        nm = ESP[n]
        ty = "power_in" if nm == "GND" else ("passive" if nm in ("VSYS", "VBUS", "3V3", "3V3_EN", "CHIP_PU") else "bidirectional")
        if n <= 20:
            at = ["at", -15.24, round(24.13 - (n - 1) * 2.54, 2), 0]
        else:
            at = ["at", 15.24, round(24.13 - (40 - n) * 2.54, 2), 180]
        u.append(["pin", ty, "line", at, ["length", 2.54], ["name", Q(nm), eff()], ["number", Q(str(n)), eff()]])
    s.append(u)
    s.append(["embedded_fonts", "no"])
    return s


ESPSYM = esp_symbol()


def getsym(lid):
    if lid not in libs:
        l, n = lid.split(":")
        s = ESPSYM if l == "FilPilote" else flat(l, n)
        s = parse(dump(s))[0]
        s[1] = Q(lid)
        libs[lid] = s
    return libs[lid]


R90 = {0: lambda x, y: (x, y), 90: lambda x, y: (-y, x), 180: lambda x, y: (-x, -y), 270: lambda x, y: (y, -x)}
PARTS = []


def place(lid, ref, val, fp, x, y, rot=0, mpn="", rp=(0, -5.08), vp=(0, 5.08), hideval=False):
    """Place un symbole (x, y en unites de 1,27 mm). Retourne {broche: (x, y, dx)} en mm."""
    s = getsym(lid)
    X, Y = round(x * G, 4), round(y * G, 4)
    i = ["symbol", ["lib_id", Q(lid)], ["at", X, Y, rot], ["unit", 1], ["exclude_from_sim", "no"], ["in_bom", "yes"], ["on_board", "yes"], ["dnp", "no"], ["uuid", uid()]]
    power = lid.startswith("power:")
    for k, v, ox, oy, hide in (("Reference", ref, rp[0], rp[1], power), ("Value", val, vp[0], vp[1], hideval), ("Footprint", fp, 0, 0, True), ("MPN", mpn, 0, 0, True)):
        if k == "MPN" and not mpn:
            continue
        p = ["property", Q(k), Q(v), ["at", round(X + ox, 4), round(Y + oy, 4), (360 - rot) % 180 if rot in (90, 270) else 0]]
        if hide:
            p.append(["hide", "yes"])
        p.append(eff())
        i.append(p)
    res = {}
    for num, nm, ty, px, py, a, hid in pins(s):
        i.append(["pin", Q(num), ["uuid", uid()]])
        rx, ry = R90[rot](px, py)
        ax, ay = R90[rot](-1 if a == 0 else 1 if a == 180 else 0, 1 if a == 270 else -1 if a == 90 else 0)
        res[num] = (round(X + rx, 4), round(Y - ry, 4), ax, -ay, nm, hid)
    i.append(["instances", ["project", Q(PRJ), ["path", Q("/" + SHEET), ["reference", Q(ref)], ["unit", 1]]]])
    out.append(i)
    if not power:
        PARTS.append((ref, val, fp, mpn))
    return res


def wire(*pts):
    for a, b in zip(pts, pts[1:]):
        if a != b:
            out.append(["wire", ["pts", ["xy", a[0], a[1]], ["xy", b[0], b[1]]], ["stroke", ["width", 0], ["type", "default"]], ["uuid", uid()]])


def junction(p):
    out.append(["junction", ["at", p[0], p[1]], ["diameter", 0], ["color", 0, 0, 0, 0], ["uuid", uid()]])


def glabel(net, x, y, dx, dy):
    rot = {(-1, 0): 180, (1, 0): 0, (0, -1): 90, (0, 1): 270}[(dx, dy)]
    out.append(["global_label", Q(net), ["shape", "passive"], ["at", x, y, rot], ["effects", ["font", ["size", 1.27, 1.27]], ["justify", "right" if rot in (180, 270) else "left"]], ["uuid", uid()]])


def net(pin, name, n=2):
    """Etiquette globale au bout d'un petit fil sur une broche."""
    x, y, dx, dy = pin[:4]
    x2, y2 = round(x + dx * n * G, 4), round(y + dy * n * G, 4)
    wire((x, y), (x2, y2))
    glabel(name, x2, y2, int(dx), int(dy))


_pw = [0, 0]


def gnd(pin, n=2):
    x, y, dx, dy = pin[:4]
    x2, y2 = round(x + dx * n * G, 4), round(y + dy * n * G, 4)
    wire((x, y), (x2, y2))
    _pw[0] += 1
    place("power:GND", "#PWR%03d" % _pw[0], "GND", "", x2 / G, y2 / G, 0, vp=(0, 3.81))


def flag(netname, x, y):
    _pw[1] += 1
    p = place("power:PWR_FLAG", "#FLG%02d" % _pw[1], "PWR_FLAG", "", x, y, 0, vp=(0, -3.81))["1"]
    wire((p[0], p[1]), (p[0], round(p[1] + 2 * G, 4)))
    if netname == "GND":
        _pw[0] += 1
        place("power:GND", "#PWR%03d" % _pw[0], "GND", "", p[0] / G, p[1] / G + 2, 0, vp=(0, 3.81))
    else:
        glabel(netname, p[0], round(p[1] + 2 * G, 4), 0, 1)


def nc(pin):
    out.append(["no_connect", ["at", pin[0], pin[1]], ["uuid", uid()]])


def title(t, x, y, size=3.0):
    out.append(["text", Q(t), ["exclude_from_sim", "no"], ["at", round(x * G, 3), round(y * G, 3), 0], ["effects", ["font", ["size", size, size], ["bold", "yes"]], ["justify", "left"]], ["uuid", uid()]])


def box(x1, y1, x2, y2, dash="default"):
    out.append(["rectangle", ["start", round(x1 * G, 3), round(y1 * G, 3)], ["end", round(x2 * G, 3), round(y2 * G, 3)], ["stroke", ["width", 0.3], ["type", dash]], ["fill", ["type", "none"]], ["uuid", uid()]])


FP_PHX = "FilPilote:Phoenix_1715721_MKDS-1.5-2-5.08"
FP_D = "Diode_THT:D_DO-41_SOD81_P10.16mm_Horizontal"
FP_R = "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P10.16mm_Horizontal"
FP_CP = "Capacitor_THT:CP_Radial_D5.0mm_P2.00mm"
FP_C = "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P2.50mm"

# ================= 1. ALIMENTATION =================
box(12, 12, 232, 78)
title("1. ALIMENTATION", 14, 16)
p = place("Connector:Screw_Terminal_01x02", "J1", "SECTEUR L/N", FP_PHX, 34, 34, 180, "1715721", (0, -7.62), (0, 7.62))
net(p["1"], "MAINS_L", 4)
net(p["2"], "MAINS_N", 4)
p = place("Device:Fuse", "F0", "250mA T 5x20", "FilPilote:Schurter_0031.8201", 66, 34, 90, "0031.8201", (0, -3.81), (0, 3.81))
net(p["1"], "MAINS_L")
net(p["2"], "PHASE_PROT")
p = place("Converter_ACDC:IRM-05-5", "PS1", "IRM-05-5", "Converter_ACDC:Converter_ACDC_MeanWell_IRM-05-xx_THT", 108, 34, 0, "IRM-05-5", (0, -8.89), (0, 8.89))
net(p["2"], "PHASE_PROT")
net(p["1"], "MAINS_N")
net(p["4"], "LOCAL_5V")
gnd(p["3"], 4)
p = place("Diode:1N5819", "DPWR", "1N5819RL", FP_D, 148, 32, 180, "1N5819RL", (0, -3.81), (0, 3.81))
net(p["2"], "LOCAL_5V")
net(p["1"], "VSYS")
p = place("Regulator_Linear:LF33_TO220", "U1", "LF33CV", "FilPilote:TO-220-3_Vertical_LF33CV", 190, 32, 0, "LF33CV", (-5.08, -6.35), (5.08, -6.35))
net(p["1"], "VSYS", 4)
net(p["3"], "3V3_OPTO", 4)
gnd(p["2"])
for ref, val, fp, sym, x, nn, mpn in (("C1", "47uF 25V", FP_CP, "Device:C_Polarized", 162, "VSYS", "EEUFC1E470"), ("C4", "100nF", FP_C, "Device:C", 178, "VSYS", "RDER71H104K0P1H03B"),
                                      ("C2", "47uF 25V", FP_CP, "Device:C_Polarized", 206, "3V3_OPTO", "EEUFC1E470")):
    p = place(sym, ref, val, fp, x, 58, 0, mpn, (5.08, -1.27), (7.62, 1.27))
    net(p["1"], nn)
    gnd(p["2"])
for k, nn in enumerate(("PHASE_PROT", "MAINS_N", "VSYS")):
    flag(nn, 30 + 24 * k, 62)

# ================= 2. COMMANDE =================
box(236, 12, 456, 160)
title("2. COMMANDE (tres basse tension)", 238, 16)
p = place("FilPilote:ESP32-S3-ETH-M", "JWS", "ESP32-S3-ETH-M", "FilPilote:Waveshare_ESP32-S3-ETH-M", 268, 50, 0, "ESP32-S3-ETH-M (34882)", (0, -36.83), (0, 36.83))
GNDP = (3, 8, 13, 18, 23, 28, 33, 38)
for n in range(1, 41):
    q = p[str(n)]
    if n in GNDP:
        net(q, "GND")
    elif n == 39:
        net(q, "VSYS")
    elif n == 25:
        net(q, "SDA")
    elif n == 26:
        net(q, "SCL")
    else:
        nc(q)

CH = [(z, s) for z in range(1, 9) for s in (1, 2)]  # 1 = positive, 2 = negative
GP = ["21", "22", "23", "24", "25", "26", "27", "28", "1", "2", "3", "4", "5", "6", "7", "8"]
p = place("Interface_Expansion:MCP23017x-x-SP", "U2", "MCP23017-E/SP", "FilPilote:DIP-28_W7.62mm_Support_ASSMANN", 334, 56, 0, "MCP23017-E/SP", (-10.16, -27.94), (10.16, 27.94))
for pin, (z, s) in zip(GP, CH):
    net(p[pin], "DRV_%d%d" % (z, s))
net(p["12"], "SCL")
net(p["13"], "SDA")
net(p["18"], "3V3_OPTO")
net(p["9"], "3V3_OPTO")
gnd(p["10"])
for k in ("15", "16", "17"):
    net(p[k], "GND")
nc(p["19"])
nc(p["20"])
p = place("Device:C", "C3", "100nF", FP_C, 366, 98, 0, "RDER71H104K0P1H03B", (5.08, -1.27), (6.35, 1.27))
net(p["1"], "3V3_OPTO")
gnd(p["2"])
for ref, nn, x in (("RPU1", "SDA", 318), ("RPU2", "SCL", 342)):
    p = place("Device:R", ref, "4.7k", FP_R, x, 100, 0, "CFR-25JT-52-4K7", (5.08, -1.27), (5.08, 1.27))
    net(p["1"], "3V3_OPTO")
    net(p["2"], nn)

ULN = [("U3", CH[0:7], 46), ("U4", CH[7:14], 88), ("U5", CH[14:16], 130)]
for ref, chs, y in ULN:
    p = place("Transistor_Array:ULN2003A", ref, "ULN2003AN", "FilPilote:DIP-16_W7.62mm_Support_ASSMANN", 412, y, 0, "ULN2003AN", (-7.62, -15.24), (12.7, 17.78))
    for k in range(7):
        i_, o_ = p[str(k + 1)], p[str(16 - k)]
        if k < len(chs):
            z, s = chs[k]
            net(i_, "DRV_%d%d" % (z, s))
            net(o_, "LEDK_%d%d" % (z, s))
        else:
            net(i_, "GND")
            nc(o_)
    net(p["9"], "VSYS")
    gnd(p["8"])

# ================= 3. SORTIES =================
box(12, 82, 232, 160)
title("3. BORNIERS DE SORTIE ET FIXATIONS", 14, 86)
for k in range(4):
    p = place("Connector:Screw_Terminal_01x02", "J%d" % (k + 2), "FP%d / FP%d" % (2 * k + 1, 2 * k + 2), FP_PHX, 34 + 40 * k, 106, 180, "1715721", (0, -7.62), (0, 7.62))
    net(p["1"], "FP%d" % (2 * k + 1))
    net(p["2"], "FP%d" % (2 * k + 2))
for k in (1, 2):
    place("Mechanical:MountingHole", "H%d" % k, "Fixation coffret", "FilPilote:Fixation_CNMB_4.0x10.4", 34 + 40 * (k - 1), 140, 0, "", (0, -3.81), (0, 5.08))

# ================= 4. ZONES =================
box(12, 164, 456, 314)
title("4. HUIT ZONES : OCx1 = alternance positive, OCx2 = alternance negative", 14, 168)
for z in range(1, 9):
    bx = 16 + ((z - 1) // 4) * 222
    by = 184 + ((z - 1) % 4) * 33
    title("ZONE %d" % z, bx, by - 7, 2.0)
    for s in (1, 2):
        y = by + (s - 1) * 15
        t = "%d%d" % (z, s)
        r = place("Device:R", "RL" + t, "200 1%", FP_R, bx + 26, y - 2, 90, "MRS25000C2000FCT00", (0, -2.54), (0, 2.54))
        net(r["1"], "VSYS", 4)
        o = place("Relay_SolidState:MOC3063M", "OC" + t, "MOC3063M", "FilPilote:DIP-6_W7.62mm_Support_ASSMANN", bx + 68, y, 0, "MOC3063M", (0, -6.35), (0, 6.35))
        # LEDA : fil direct avec etiquette
        a, b = r["2"], o["1"]
        wire((a[0], a[1]), (b[0], b[1]))
        glabel("LEDA_" + t, round(a[0] + 2 * G, 4), a[1], 0, -1)
        net(o["2"], "LEDK_" + t, 4)
        net(o["6"], "PHASE_PROT", 4)
        d = place("Diode:1N4007", "D" + t, "1N4007", FP_D, bx + 120, y + 2, 180 if s == 1 else 0, "1N4007G", (0, -2.54), (0, 2.54))
        left, right = (d["2"], d["1"]) if s == 1 else (d["1"], d["2"])
        wire((o["4"][0], o["4"][1]), (left[0], left[1]))
        glabel("MT_" + t, round(left[0] - 6 * G, 4), left[1], 0, 1)
        net(right, "FP%d" % z, 4)

# ---- ecriture ----
doc = ["kicad_sch", ["version", 20260306], ["generator", Q("eeschema")], ["generator_version", Q("10.0")], ["uuid", SHEET], ["paper", Q("A2")],
       ["title_block", ["title", Q("Fil pilote 8 zones - v4")], ["date", Q("2026-11-24")], ["rev", Q("v4-etape2")], ["comment", 1, Q("Genere par tools/make_sch.py, symboles officiels KiCad 10")]],
       ["lib_symbols"] + [libs[k] for k in sorted(libs)]] + out + [["sheet_instances", ["path", Q("/"), ["page", Q("1")]]], ["embedded_fonts", "no"]]
open(os.path.join(ROOT, PRJ + ".kicad_sch"), "w", encoding="utf-8", newline="\n").write(dump(doc) + "\n")

open(os.path.join(ROOT, "FilPilote.kicad_sym"), "w", encoding="utf-8", newline="\n").write(
    dump(["kicad_symbol_lib", ["version", 20251024], ["generator", Q("kicad_symbol_editor")], ["generator_version", Q("10.0")], ESPSYM]) + "\n")
open(os.path.join(ROOT, "sym-lib-table"), "w", newline="\n").write('(sym_lib_table\n  (version 7)\n  (lib (name "FilPilote")(type "KiCad")(uri "${KIPRJMOD}/FilPilote.kicad_sym")(options "")(descr ""))\n)\n')
open(os.path.join(ROOT, "fp-lib-table"), "w", newline="\n").write('(fp_lib_table\n  (version 7)\n  (lib (name "FilPilote")(type "KiCad")(uri "${KIPRJMOD}/FilPilote.pretty")(options "")(descr ""))\n)\n')

base = {"clearance": 0.2, "diff_pair_gap": 0.25, "diff_pair_via_gap": 0.25, "diff_pair_width": 0.2, "line_style": 0, "microvia_diameter": 0.3, "microvia_drill": 0.1,
        "pcb_color": "rgba(0, 0, 0, 0.000)", "schematic_color": "rgba(0, 0, 0, 0.000)", "track_width": 0.3, "via_diameter": 0.8, "via_drill": 0.4, "wire_width": 6, "bus_width": 12}
classes = [dict(base, name="Default", priority=2147483647), dict(base, name="Secteur", priority=0, clearance=1.5, track_width=1.0), dict(base, name="TBT", priority=1, clearance=0.25, track_width=0.4)]
SECT = ["MAINS_L", "MAINS_N", "PHASE_PROT", "MT_*", "FP?", "unconnected-(OC*Pad5)"]
TBT = ["GND", "VSYS", "LOCAL_5V", "3V3_OPTO", "SDA", "SCL", "DRV_*", "LEDA_*", "LEDK_*", "unconnected-(OC*Pad3)", "unconnected-(JWS*", "unconnected-(U?-*"]
pro = {"board": {"design_settings": {"defaults": {}, "rules": {}}}, "meta": {"filename": PRJ + ".kicad_pro", "version": 3},
       "net_settings": {"classes": classes, "meta": {"version": 5}, "net_colors": None, "netclass_assignments": None,
                        "netclass_patterns": [{"netclass": "Secteur", "pattern": x} for x in SECT] + [{"netclass": "TBT", "pattern": x} for x in TBT]},
       "pcbnew": {"page_layout_descr_file": ""}, "schematic": {"legacy_lib_dir": "", "legacy_lib_list": []}, "sheets": [[str(SHEET), "Root"]], "text_variables": {}}
fpro = os.path.join(ROOT, PRJ + ".kicad_pro")
if not os.path.exists(fpro) or "--pro" in sys.argv:
    json.dump(pro, open(fpro, "w", encoding="utf-8"), indent=2)
print(len(PARTS), "composants")
