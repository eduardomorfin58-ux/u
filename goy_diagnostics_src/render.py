import lupa.lua54 as L, re, sys
from PIL import Image, ImageDraw, ImageFont
K=float(sys.argv[1]) if len(sys.argv)>1 else 2.6617
lua=L.LuaRuntime(unpack_returned_tuples=True)
lua.execute(open('dmock.lua').read())
lua.execute("OTHER=NEW('Player','Player2',PlayersS) OTHER.UserId=1002 function PlayersS:GetPlayers() return {ME,OTHER} end function PlayersS:GetPlayerByUserId(i) if i==8812345 then return ME elseif i==1002 then return OTHER end end")
lua.execute(open('GOY_Diagnostics.lua').read())
def step(s):
    for _ in range(int(s*60)): lua.execute("STEP(1/60)")
lua.execute("FEEDR=NEW('RemoteEvent','GOY_DiagFeed',RS) MODER=NEW('RemoteEvent','GOY_DiagMode',RS) function MODER:FireServer(t) end")
step(0.5)
lua.execute("btn('GOY').Activated:Fire()")
import random
random.seed(3)
for sec in range(62):
    for k in range(random.randint(5,20)):
        p=random.choice([('Goy671079',8812345),('Player2',1002),('Player3',1003)])
        r=random.choice(['Damage','Damage','UpdateHUD','PlaySound','EquipTool','GetInventory'])
        lua.execute(f"FEEDR.OnClientEvent:Fire({{v=2,kind='OnServerEvent',remote='ReplicatedStorage.Remotes.{r}',player='{p[0]}',userId={p[1]},args='1: string = \"Sword\"\\n2: number = 25',types='string, number'}})")
    if sec%7==0: lua.execute("R1.OnClientEvent:Fire({a=1})")
    step(1)
lua.execute("FEEDR.OnClientEvent:Fire({v=2,kind='ServerStats',msg='Heartbeat 60.0 Hz · memoria 900 MB'})")
lua.execute("FEEDR.OnClientEvent:Fire({v=2,kind='Mode',mode='all',ok=true})")
lua.execute(r"""FEEDR.OnClientEvent:Fire({v=2,kind='OnServerEvent',remote='ReplicatedStorage.Remotes.Damage',player='Player1',userId=1001,args='1: string = "Sword"\n2: number = 25',types='string, number'})""")
lua.execute("_G.GOY_DIAG.UI.sel=nil _G.GOY_DIAG.UI.force=true"); step(1.5)
print("errors", lua.eval("_G.GOY_DIAG.internalErrors"), lua.eval("_G.GOY_DIAG.lastInternalError"))
F={}
def font(size, mono=False, bold=False):
    key=(round(size*K),mono,bold)
    if key not in F:
        name='/usr/share/fonts/truetype/dejavu/DejaVuSans%s%s.ttf'%('Mono' if mono else '', '-Bold' if bold else '')
        F[key]=ImageFont.truetype(name, max(6,int(size*K*0.86)))
    return F[key]
W,H=int(1082*K/1)+0, int(1205*K)
img=Image.new('RGB',(int(1082*K),int(1205*K)),(5,6,11))
d=ImageDraw.Draw(img)
def col(c):
    if c is None: return None
    try: return (int(c[1]),int(c[2]),int(c[3]))
    except Exception: return None
def get(o,k):
    try: return o[k]
    except Exception: return None
def children(o): return list(lua.eval("function(o) return o:GetChildren() end")(o).values())
def child_of_class(o,cls):
    for c in children(o):
        if get(c,'ClassName')==cls: return c
    return None
def udim(u, parentLen, axis):
    if u is None: return 0
    a=u[axis]; return (a['Scale'] or 0)*parentLen+(a['Offset'] or 0)
def textw(t,size,mono): 
    try: return d.textlength(t,font=font(size,mono))/K
    except Exception: return len(t)*size*0.55
def draw(o, px, py, pw, ph, depth=0, clip=None):
    cls=get(o,'ClassName')
    if get(o,'Visible')==False: return
    pos=get(o,'Position'); size=get(o,'Size'); anchor=get(o,'AnchorPoint')
    w=udim(size,pw,'X'); h=udim(size,ph,'Y')
    auto=get(o,'AutomaticSize')
    if auto and 'X' in str(auto) and cls in('TextLabel','Frame'):
        if cls=='TextLabel': w=max(w,textw(re.sub('<[^>]+>','',str(get(o,'Text') or '')), get(o,'TextSize') or 10, False))
        else:
            cw=0
            for c in children(o):
                if get(c,'ClassName')=='TextLabel': cw=max(cw,textw(str(get(c,'Text') or ''),get(c,'TextSize') or 10,False))
            w=max(w,cw+12)
    x=px+udim(pos,pw,'X'); y=py+udim(pos,ph,'Y')
    if anchor: x-=anchor['X']*w; y-=anchor['Y']*h
    if clip and (y>=clip[1] or y+h<=clip[0]): return
    rect=[x*K,y*K,(x+w)*K,(y+h)*K]
    bt=get(o,'BackgroundTransparency')
    bg=col(get(o,'BackgroundColor3'))
    corner=child_of_class(o,'UICorner'); r=0
    if corner: r=(get(corner,'CornerRadius') or [0,0])[2]*K if get(corner,'CornerRadius') else 0
    st=child_of_class(o,'UIStroke')
    rot=get(o,'Rotation') or 0
    if cls in ('Frame','TextButton','TextLabel','ScrollingFrame','TextBox') and w>0 and h>0:
        if rot and abs(rot)>0.01 and bg and (bt or 0)<1:
            import math
            cx,cy=(x+w/2)*K,(y+h/2)*K; a=math.radians(rot); dx=math.cos(a)*w*K/2; dy=math.sin(a)*w*K/2
            d.line([cx-dx,cy-dy,cx+dx,cy+dy],fill=bg,width=max(1,int(h*K)))
        else:
            fill=bg if (bg and (bt is None or bt<1)) else None
            outline=None; ow=1
            if st and (get(st,'Transparency') or 0)<1: outline=col(get(st,'Color')); ow=max(1,int((get(st,'Thickness') or 1)*K))
            if fill or outline:
                try: d.rounded_rectangle(rect, radius=min(r,(rect[3]-rect[1])/2,(rect[2]-rect[0])/2), fill=fill, outline=outline, width=ow)
                except Exception: pass
    if cls in ('TextLabel','TextButton','TextBox'):
        t=get(o,'Text') or ''
        if cls=='TextBox' and t=='' : t=get(o,'PlaceholderText') or ''
        t=re.sub('<[^>]+>','',str(t)).replace('&lt;','<').replace('&gt;','>').replace('&amp;','&')
        if t:
            sz=get(o,'TextSize') or 10
            fnt=str(get(o,'Font') or '')
            mono='Code' in fnt; bold='Bold' in fnt or 'Black' in fnt
            ff=font(sz,mono,bold)
            c=col(get(o,'TextColor3')) or (220,220,220)
            lines=t.split('\n') if (get(o,'TextWrapped') or '\n' in t) else [t]
            if get(o,'TextWrapped'):
                out=[]
                for ln in lines:
                    words=ln.split(' '); cur=''
                    for wd in words:
                        tst=(cur+' '+wd).strip()
                        if d.textlength(tst,font=ff)>w*K and cur: out.append(cur); cur=wd
                        else: cur=tst
                    out.append(cur)
                lines=out
            lh=sz*1.3*K
            total=lh*len(lines)
            ya=str(get(o,'TextYAlignment') or '')
            ty=rect[1] if 'Top' in ya else (rect[1]+rect[3])/2-total/2
            xa=str(get(o,'TextXAlignment') or 'Center')
            for i,ln in enumerate(lines):
                tw=d.textlength(ln,font=ff)
                if tw>w*K and not get(o,'TextWrapped'):
                    while ln and d.textlength(ln+'…',font=ff)>w*K: ln=ln[:-1]
                    ln=ln+'…'; tw=d.textlength(ln,font=ff)
                tx=rect[0] if 'Left' in xa else (rect[2]-tw if 'Right' in xa else (rect[0]+rect[2])/2-tw/2)
                pad=child_of_class(o,'UIPadding')
                d.text((tx, ty+i*lh+lh/2), ln, font=ff, fill=c, anchor='lm')
    kids=children(o)
    layout=child_of_class(o,'UIListLayout')
    if layout and 'Horizontal' in str(get(layout,'FillDirection')):
        padx=(get(layout,'Padding') or [0,0])[2]
        items=[c for c in kids if get(c,'ClassName') in ('Frame','TextLabel','TextButton') and get(c,'Visible')!=False]
        items.sort(key=lambda c: get(c,'LayoutOrder') or 0)
        widths=[]
        for c in items:
            s2=get(c,'Size'); cw=udim(s2,w,'X')
            if get(c,'ClassName')=='TextLabel': cw=max(cw,textw(str(get(c,'Text') or ''),get(c,'TextSize') or 10,False))
            widths.append(cw)
        total=sum(widths)+padx*(len(items)-1)
        cx=x + (w-total if 'Right' in str(get(layout,'HorizontalAlignment')) else 0)
        for c,cw in zip(items,widths):
            c2h=udim(get(c,'Size'),h,'Y')
            lua.execute("function _setpos(o,x,y) o.Position=UDim2.fromOffset(x,y) end")
            lua.globals()._setpos(c, cx-x, (h-c2h)/2)
            draw(c, x, y, w, h, depth+1, clip); cx+=cw+padx
        return
    sy=0
    if cls=='ScrollingFrame':
        cp=get(o,'CanvasPosition'); sy=cp['Y'] if cp else 0
    nclip=clip
    if cls=='ScrollingFrame' or get(o,'ClipsDescendants'):
        nclip=(max(y,clip[0]) if clip else y, min(y+h,clip[1]) if clip else y+h)
    for c in kids:
        if get(c,'ClassName') in ('Frame','TextButton','TextLabel','ScrollingFrame','TextBox'):
            draw(c, x, y-sy, w, h, depth+1, nclip)
panel=lua.eval("GUI().Viewport.Panel")
draw(panel, 21-udim(get(panel,'Position'),0,'X'), 21-udim(get(panel,'Position'),0,'Y'), 1040, 1163)
img.save('render.png')
ref=Image.open('/workspace/projects/9ab3bdf8-2113-494b-a36f-a90c5426a8ed/files/extracted/GOY-Diagnostics-v1.2-Pro-03ad1d522dff/images/p001-Im0-obj6.jpg').convert('RGB').resize(img.size)
both=Image.new('RGB',(img.size[0]*2,img.size[1])); both.paste(ref,(0,0)); both.paste(img,(img.size[0],0))
both.thumbnail((2200,2200)); both.save('compare.png')
blend=Image.blend(ref,img,0.5); blend.thumbnail((1400,1400)); blend.save('blend.png')
print('ok')
