"""Image des deux couches cuivre : plot.py carte.kicad_pcb sortie.png  (dessus en haut, dessous en bas, meme vue de dessus)"""
import sys,fnmatch,wx,pcbnew
from PIL import Image,ImageDraw,ImageFont
b=pcbnew.LoadBoard(sys.argv[1]);t=pcbnew.ToMM;Z=12
SECT=["MAINS_L","MAINS_N","PHASE_PROT","MT_*","FP?","unconnected-(OC*Pad5)"]
COL={"MAINS_L":(150,0,0),"MAINS_N":(0,90,200),"PHASE_PROT":(225,60,20)}
def c(n):
    if n in COL:return COL[n]
    if n.startswith("MT_"):return (240,150,0)
    if n.startswith("FP"):return (170,0,150)
    if n=="GND":return (60,120,60)
    if n in("VSYS","LOCAL_5V"):return (200,0,60)
    if n=="3V3_OPTO":return (200,130,60)
    return (40,60,60) if not n.startswith("unc") else (150,150,150)
W,H=int(156*Z),int(86.5*Z)
im=Image.new("RGB",(W+40,2*H+100),"white")
for k,l in enumerate((pcbnew.F_Cu,pcbnew.B_Cu)):
    oy=30+k*(H+40);d=ImageDraw.Draw(im)
    P=lambda x,y:(20+(t(x)-60)*Z,oy+(t(y)-50)*Z)
    d.text((20,oy-24),"DESSUS (F.Cu)" if k==0 else "DESSOUS (B.Cu), vu de dessus",fill=(0,0,0),font=ImageFont.truetype("arial.ttf",20))
    d.rectangle([20,oy,20+W,oy+H],outline=(0,0,0),width=2)
    for z in b.Zones():
        if not z.GetIsRuleArea() and z.GetLayer()==l:
            q=z.GetFilledPolysList(l)
            for i in range(q.OutlineCount()):
                o=q.Outline(i);d.polygon([P(o.CPoint(j).x,o.CPoint(j).y) for j in range(o.PointCount())],fill=(205,232,205))
                for h in range(q.HoleCount(i)):
                    o=q.Hole(i,h);d.polygon([P(o.CPoint(j).x,o.CPoint(j).y) for j in range(o.PointCount())],fill="white")
    for f in b.GetFootprints():
        for g in f.GraphicalItems():
            if g.GetLayer()==pcbnew.F_CrtYd:
                r=g.GetBoundingBox();d.rectangle([P(r.GetLeft(),r.GetTop()),P(r.GetRight(),r.GetBottom())],outline=(215,215,235))
    for tr in b.GetTracks():
        if tr.Type()==pcbnew.PCB_VIA_T:
            p=P(tr.GetPosition().x,tr.GetPosition().y);d.ellipse([p[0]-5,p[1]-5,p[0]+5,p[1]+5],fill=c(tr.GetNetname()),outline=(0,0,0));continue
        if tr.GetLayer()!=l:continue
        a,e=P(tr.GetStart().x,tr.GetStart().y),P(tr.GetEnd().x,tr.GetEnd().y);w=int(t(tr.GetWidth())*Z)
        d.line([a,e],fill=c(tr.GetNetname()),width=w)
        for q in(a,e):d.ellipse([q[0]-w/2,q[1]-w/2,q[0]+w/2,q[1]+w/2],fill=c(tr.GetNetname()))
    for f in b.GetFootprints():
        for p in f.Pads():
            q=P(p.GetPosition().x,p.GetPosition().y);s=p.GetBoundingBox();sx=t(s.GetWidth())*Z/2;sy=t(s.GetHeight())*Z/2
            d.ellipse([q[0]-sx,q[1]-sy,q[0]+sx,q[1]+sy],fill=c(p.GetNetname()) if p.GetNetname() else (190,190,190),outline=(0,0,0))
        r=f.GetBoundingBox(False);q=P(r.GetCenter().x,r.GetCenter().y)
        d.text(q,f.GetReference(),fill=(0,0,255),anchor="mm",font=ImageFont.truetype("arial.ttf",13))
im.save(sys.argv[2])
