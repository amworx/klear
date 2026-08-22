#!/usr/bin/env python3
import json, math, os
OUT = r"C:\Users\HP\Documents\code_repo\android\klear\src\assets\lottie"
P = {"p":[0.0549,0.4549,0.5647,1.0], "a":[0.1333,0.8275,0.9333,1.0], "w":[1,1,1,1]}
C = [200.0,200.0,0.0]
W=H=400; FR=60
def S(v): return {"a":0,"k":v}
def A(pts):
    n=len(pts[0][1]); out=[]
    for i,(t,val) in enumerate(pts):
        k={"t":t,"s":list(val)}
        if i<len(pts)-1:
            k["i"]={"x":[0.42]*n,"y":[1.0]*n}; k["o"]={"x":[0.58]*n,"y":[0.0]*n}
        out.append(k)
    return {"a":1,"k":out}
def ell(cx,cy,w,h,c,o=100):
    return {"ty":"gr","it":[{"ty":"el","p":S([cx,cy]),"s":S([w,h])},
        {"ty":"fl","c":S(c),"o":S(o),"r":1},
        {"ty":"tr","p":S([0,0]),"a":S([0,0]),"s":S([100,100]),"r":S(0),"o":S(100)}]}
def ring(cx,cy,w,h,c,sw,o=100):
    return {"ty":"gr","it":[{"ty":"el","p":S([cx,cy]),"s":S([w,h])},
        {"ty":"st","c":S(c),"o":S(o),"w":S(sw),"lc":2,"lj":2},
        {"ty":"tr","p":S([0,0]),"a":S([0,0]),"s":S([100,100]),"r":S(0),"o":S(100)}]}
def path(v,i,o,closed,fill=None,stroke=None,sw=0,o2=100):
    it=[{"ty":"sh","ks":S({"i":o,"o":i,"v":v,"c":closed})}]
    if fill is not None: it.append({"ty":"fl","c":S(fill),"o":S(o2),"r":1})
    if stroke is not None: it.append({"ty":"st","c":S(stroke),"o":S(o2),"w":S(sw),"lc":2,"lj":2})
    it.append({"ty":"tr","p":S([0,0]),"a":S([0,0]),"s":S([100,100]),"r":S(0),"o":S(100)})
    return {"ty":"gr","it":it}
def star4(ro,ri):
    v=[];i=[];o=[]
    for k in range(8):
        ang=math.pi/2+k*math.pi/4; r=ro if k%2==0 else ri
        v.append([round(r*math.cos(ang),2),round(-r*math.sin(ang),2)]); i.append([0,0]); o.append([0,0])
    return path(v,i,o,True,fill=P["w"])
def tri():
    v=[[0,-30],[34,28],[-34,28]]; z=[[0,0],[0,0],[0,0]]
    return path(v,z,z,True,fill=P["p"])
def layer(ind,shapes,op,ks,nm="l"):
    return {"ddd":0,"ind":ind,"ty":4,"nm":nm,"sr":1,"ks":ks,"ao":0,"shapes":shapes,"ip":0,"op":op,"st":0,"bm":0}
def doc(name,op,layers):
    return {"v":"5.9.0","fr":FR,"ip":0,"op":op,"w":W,"h":H,"nm":name,"ddd":0,"assets":[],"layers":layers}

def splash():
    op=144
    badge=layer(1,[ell(0,0,250,250,P["p"] if False else P["p"])],op,
        {"o":S(100),"r":S(0),"p":S(C),"a":S([0,0,0]),"s":S([100,100,100])},"badge")
    drop=layer(2,[ell(0,0,56,80,P["w"])],op,
        {"o":S(100),"r":S(0),"p":S(C),"a":S([0,0,0]),
         "s":A([(0,[100,100,100]),(36,[116,116,100]),(72,[100,100,100]),(108,[110,110,100]),(144,[100,100,100])])},"drop")
    rings=[]
    for i,st in enumerate([30,75,120]):
        rings.append(layer(3+i,[ring(0,0,150,150,P["w"],9)],op,
            {"o":A([(0,[70-i*8]),(144,[0])]),"r":S(0),"p":S(C),"a":S([0,0,0]),
             "s":A([(0,[st,st,100]),(144,[195,195,100])])},"r%d"%i))
    return doc("klear-splash",op,[badge,drop]+rings)

def welcome():
    op=120
    glow=layer(1,[ell(0,0,280,280,P["a"])],op,
        {"o":A([(0,[12]),(60,[28]),(120,[12])]),"r":S(0),"p":S(C),"a":S([0,0,0]),"s":S([100,100,100])},"glow")
    drop=layer(2,[ell(0,0,64,90,P["w"])],op,
        {"o":S(100),"r":S(0),
         "p":A([(0,[200,188,0]),(30,[200,214,0]),(60,[200,188,0]),(90,[200,214,0]),(120,[200,188,0])]),
         "a":S([0,0,0]),"s":S([100,100,100])},"drop")
    sp=[]
    for i,(rad,sz,off) in enumerate([(120,18,0),(150,13,2.1),(95,11,4.2)]):
        sp.append(layer(3+i,[ell(0,-rad,sz,sz,P["a"])],op,
            {"o":A([(0,[90]),(60,[30]),(120,[90])]),
             "r":A([(0,[off*57]),(120,[360+off*57])]),"p":S(C),"a":S([0,0,0]),"s":S([100,100,100])},"s%d"%i))
    return doc("klear-welcome",op,[glow,drop]+sp)

def onb1():
    op=120
    water=layer(1,[ell(0,0,320,150,P["a"])],op,
        {"o":S(70),"r":S(0),"p":A([(0,[200,300,0]),(60,[200,308,0]),(120,[200,300,0])]),"a":S([0,0,0]),"s":S([100,100,100])},"water")
    drop=layer(2,[ell(0,0,42,58,P["w"])],op,
        {"o":A([(0,[100]),(44,[100]),(50,[0]),(56,[0]),(62,[100]),(106,[100]),(112,[0]),(118,[0])]),
         "r":S(0),"p":A([(0,[200,120,0]),(44,[200,250,0]),(56,[200,120,0]),(106,[200,250,0]),(118,[200,120,0])]),
         "a":S([0,0,0]),"s":S([100,100,100])},"drop")
    rings=[]
    for i in range(2):
        b=50+i*60
        rings.append(layer(3+i,[ring(0,0,90,90,P["w"],8)],op,
            {"o":A([(0,[0]),(b,[0]),(b+2,[55]),(b+28,[0]),(120,[0])]),"r":S(0),"p":S([200,250,0]),"a":S([0,0,0]),
             "s":A([(0,[20,20,100]),(b,[20,20,100]),(b+28,[150,150,100]),(120,[150,150,100])])},"r%d"%i))
    return doc("klear-onb1",op,[water,drop]+rings)

def onb2():
    op=120
    head=ell(0,-25,92,92,P["p"])
    tvi=[[0,20],[34,20],[0,82]]; z=[[0,0],[0,0],[0,0]]
    tail=path(tvi,z,z,True,fill=P["p"])
    pin=layer(1,[head,tail],op,
        {"o":S(100),"r":S(0),"p":A([(0,[200,150,0]),(30,[200,178,0]),(60,[200,150,0]),(90,[200,178,0]),(120,[200,150,0])]),
         "a":S([0,0,0]),"s":S([100,100,100])},"pin")
    rings=[]
    for i in range(3):
        st=20+i*40
        rings.append(layer(2+i,[ring(0,0,70,70,P["a"],7)],op,
            {"o":A([(0,[0]),(40+i*25,[0]),(42+i*25,[50]),(70+i*25,[0]),(120,[0])]),"r":S(0),"p":S([200,240,0]),"a":S([0,0,0]),
             "s":A([(0,[st,st,100]),(70+i*25,[160,160,100]),(120,[160,160,100])])},"r%d"%i))
    dot=layer(5,[ell(0,0,16,16,P["a"])],op,
        {"o":S(100),"r":S(0),"p":A([(0,[130,200,0]),(60,[270,200,0]),(120,[130,200,0])]),"a":S([0,0,0]),"s":S([100,100,100])},"dot")
    return doc("klear-onb2",op,[pin]+rings+[dot])

def onb3():
    op=120
    halo=layer(1,[ell(0,0,250,250,P["a"])],op,
        {"o":A([(0,[18]),(60,[38]),(120,[18])]),"r":S(0),"p":S(C),"a":S([0,0,0]),"s":S([100,100,100])},"halo")
    drop=layer(2,[ell(0,0,60,84,P["p"])],op,
        {"o":S(100),"r":S(0),"p":S(C),"a":S([0,0,0]),"s":S([100,100,100])},"drop")
    star=layer(3,[star4(120,42)],op,
        {"o":A([(0,[100]),(60,[40]),(120,[100])]),"r":A([(0,[0]),(120,[360])]),"p":S(C),"a":S([0,0,0]),
         "s":A([(0,[80,80,100]),(60,[115,115,100]),(120,[80,80,100])])},"star")
    sp=[]
    for i,(rad,sz) in enumerate([(140,12),(175,9)]):
        sp.append(layer(4+i,[ell(0,-rad,sz,sz,P["w"])],op,
            {"o":A([(0,[80]),(60,[20]),(120,[80])]),"r":A([(0,[i*90]),(120,[360+i*90])]),"p":S(C),"a":S([0,0,0]),"s":S([100,100,100])},"s%d"%i))
    return doc("klear-onb3",op,[halo,drop,star]+sp)

os.makedirs(OUT,exist_ok=True)
for name,data in [("splash",splash()),("welcome",welcome()),("onboarding_1",onb1()),("onboarding_2",onb2()),("onboarding_3",onb3())]:
    with open(os.path.join(OUT,name+".json"),"w") as f:
        json.dump(data,f,separators=(",",":"))
    print("wrote",name+".json")
