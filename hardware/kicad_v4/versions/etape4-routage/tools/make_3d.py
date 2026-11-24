"""Volume simplifie de la carte ESP32-S3-ETH-M (hauteurs SUPPOSEES : support 8,51 + entretoise 2,54)."""
import os
G = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "3d")
Z = 11.05


def box(x1, y1, z1, x2, y2, z2, c):
    u = 2.54
    cx, cy, cz = (x1 + x2) / 2 / u, -(y1 + y2) / 2 / u, (z1 + z2) / 2 / u
    return "Transform { translation %.4f %.4f %.4f children [ Shape { appearance Appearance { material Material { diffuseColor %s } } geometry Box { size %.4f %.4f %.4f } } ] }\n" % (cx, cy, cz, c, abs(x2 - x1) / u, abs(y2 - y1) / u, abs(z2 - z1) / u)


s = "#VRML V2.0 utf8\n"
s += box(-1.61, -19.87, Z, 19.39, 52.93, Z + 1.6, "0.05 0.05 0.08")
s += box(0.9, -19.87, Z + 1.6, 16.9, -4.5, Z + 15.1, "0.75 0.75 0.78")
s += box(4.4, -19.87, Z - 3.2, 13.4, -12.5, Z, "0.8 0.8 0.8")
s += box(5.4, 50.9, Z + 1.6, 12.4, 52.5, Z + 2.8, "0.8 0.1 0.1")
p = "#VRML V2.0 utf8"+chr(10) + box(-3.6, -11.2, 0, 42.1, 14.2, 21.5, "0.12 0.12 0.12")
open(os.path.join(G, "IRM-05-5.wrl"), "w").write(p)
open(os.path.join(G, "ESP32-S3-ETH-M.wrl"), "w").write(s)
