# 인앱 이벤트 그림(글자 없음): 레포 스크린샷을 휴대폰 틀에 넣어 KORA 바탕에 놓는다.
import sys, math
from PIL import Image, ImageDraw, ImageFilter
BG=(253,250,247); CORAL=(216,90,48); BLUE=(120,190,225)
def phone(shot, h):
    s=Image.open(shot).convert('RGB')
    sw=int(h*s.width/s.height); s=s.resize((sw,h),Image.LANCZOS)
    pad=int(h*0.022); W,H=sw+2*pad,h+2*pad
    ph=Image.new('RGBA',(W,H),(0,0,0,0)); d=ImageDraw.Draw(ph)
    d.rounded_rectangle([0,0,W-1,H-1],radius=int(W*0.16),fill=(28,24,23,255))
    m=Image.new('L',(sw,h),0); ImageDraw.Draw(m).rounded_rectangle([0,0,sw-1,h-1],radius=int(sw*0.13),fill=255)
    ph.paste(s,(pad,pad),m); return ph
def canvas(W,H,lines):
    im=Image.new('RGB',(W,H),BG)
    glow=Image.new('RGB',(W,H),BG); g=ImageDraw.Draw(glow)
    r=int(min(W,H)*0.55); cx,cy=int(W*0.62),int(H*0.45)
    g.ellipse([cx-r,cy-r,cx+r,cy+r],fill=(248,226,214)); glow=glow.filter(ImageFilter.GaussianBlur(r*0.5))
    im=Image.blend(im,glow,0.8); d=ImageDraw.Draw(im)
    sw=int(min(W,H)*0.03)
    for color,pts in lines:
        P=[(int(x*W),int(y*H)) for x,y in pts]
        d.line(P,fill=color,width=sw,joint='curve')
        for p in P[1:-1]:
            rr=int(sw*1.0); d.ellipse([p[0]-rr,p[1]-rr,p[0]+rr,p[1]+rr],fill=BG,outline=color,width=int(sw*0.45))
    return im
def shadow(im,ph,x,y):
    sh=Image.new('RGBA',im.size,(0,0,0,0)); a=ph.split()[3].point(lambda v:int(v*0.25))
    blk=Image.new('RGBA',ph.size,(60,30,20,255)); blk.putalpha(a); sh.paste(blk,(x,y+int(im.size[1]*0.008)),blk)
    sh=sh.filter(ImageFilter.GaussianBlur(max(im.size)*0.006)); im=im.convert('RGBA'); im.alpha_composite(sh); im.alpha_composite(ph,(x,y)); return im.convert('RGB')
def save(im,out):
    im.save(out,quality=90,optimize=True) if out.endswith('.jpg') else im.save(out,optimize=True)
def card(shot,out,W=1920,H=1080):
    im=canvas(W,H,[((171,214,234),[(0,0.18),(0.30,0.18),(0.40,0.36),(0.40,0.55)]),((246,200,178),[(1,0.80),(0.82,0.80),(0.74,0.66)])])
    ph=phone(shot,int(H*0.95)); x=int(W*0.5-ph.width/2); y=int(H*0.08)
    save(shadow(im,ph,x,y),out)
def detail(shot,out,W=1080,H=1920):
    im=canvas(W,H,[((171,214,234),[(0,0.10),(0.55,0.10),(0.70,0.18)]),((246,200,178),[(1,0.88),(0.70,0.88),(0.60,0.80)])])
    ph=phone(shot,int(H*0.72)); x=int(W/2-ph.width/2); y=int(H*0.14)
    save(shadow(im,ph,x,y),out)
if __name__=='__main__':
    # 쓰기: python3 make_event_images.py <docs/screenshots/raw 경로> <출력 폴더> [화면 이름=ride]
    # 로케일마다 <출력>/<로케일>/card.jpg(1920x1080) · detail.jpg(1080x1920) 를 만든다. 4K 가 필요하면 W·H 를 두 배로.
    import os
    raw,outdir=sys.argv[1],sys.argv[2]; screen=sys.argv[3] if len(sys.argv)>3 else 'ride'
    for loc in sorted(os.listdir(raw)):
        shot=os.path.join(raw,loc,screen+'.png')
        if not os.path.exists(shot): continue
        os.makedirs(os.path.join(outdir,loc),exist_ok=True)
        card(shot,os.path.join(outdir,loc,'card.jpg')); detail(shot,os.path.join(outdir,loc,'detail.jpg'))
        print(loc)
