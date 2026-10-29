#!/usr/bin/env python3
"""Optional OFFLINE generation for the single galaxy image (requires Pillow + NumPy).
This is NOT run at game startup; bundled texture has already been generated.
Running this script regenerates the exact deterministic seed-based background.
"""
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
from pathlib import Path

root=Path(__file__).resolve().parents[1]
out=root/'assets/cosmic'
out.mkdir(parents=True,exist_ok=True)
W,H=2048,1024
rng=np.random.default_rng(20261027)

def noise(gridx, gridy):
    a=rng.uniform(0,255,(gridy,gridx)).astype('uint8')
    a=Image.fromarray(a,'L').resize((W,H),Image.Resampling.BICUBIC)
    return np.asarray(a,dtype=np.float32)/255.0

n0=noise(7,5); n1=noise(17,11); n2=noise(43,23); n3=noise(94,53)
d0=noise(12,8); d1=noise(31,19); d2=noise(88,47)
c0=noise(10,7); c1=noise(26,15); c2=noise(66,33)
print('noises constructed')
y,x=np.mgrid[0:H,0:W].astype(np.float32)
x=(x-W*.5)/(W*.5); y=(y-H*.5)/(H*.5)

# Sweeping non-repeating galactic river: a warped and bifurcated cloud envelope.
mid = 0.24*x+0.065*np.sin(x*5.6+0.3)+0.041*np.sin(x*14.3)+0.20*(n0-.5)
warp = 0.14*(n1-.5) + 0.085*(n2-.5)
dist=(y-mid+warp)
softwidth=0.25+0.06*n0+0.12*np.exp(-((x-0.10)/0.55)**2)
plume = np.exp(-0.5*(dist/softwidth)**2)
filament = 0.35+1.8*np.power(np.clip((0.38*n1+0.35*n2+0.27*n3),0,1),1.4)
branches=np.exp(-0.5*((dist-(0.19+0.06*np.sin(x*9))) / 0.17)**2)*(.45+.7*n2)
branches+=np.exp(-0.5*((dist+(0.25+0.04*np.sin(x*8)))/0.14)**2)*(.3+.7*n1)
# Dark razorlike and broken molecular-cloud valleys, no round edges.
dust_center = 0.068*np.sin(x*10.6+0.2)+0.03*np.sin(x*25.0)+0.055*(d1-.5)
lanes= np.exp(-0.5*((dist-dust_center)/(.032 + .032*d2))**2)
lanes+= .75*np.exp(-0.5*((dist+0.105+.044*np.sin(x*10+0.3))/.045)**2)*(d0>.40)
blotches=np.maximum(0.0, 0.65*d0+0.4*d1+0.30*d2-0.66)*2.4
mask=np.clip(lanes*.84+blotches*.73,0,0.96)

fade_x=np.clip((1.05-np.abs(x))/0.30,0,1)**1.5
base=np.clip((plume*(.65+.75*n1) + branches*.18)*filament,0,2.5)
base*= (1-mask)*fade_x
# Blue-white gas, copper-gold core, violet glowing knots, cyan gas pockets.
warm=np.exp(-((x-.12)/.38)**2)*np.exp(-(dist/.50)**2)
cyan=np.exp(-((x+.40)/.58)**2)*np.exp(-((dist+.02)/.44)**2)
violet=np.exp(-((x-.69)/.26)**2)*np.exp(-((dist-.06)/.24)**2)
# Emission knots have sharp broken, web-like interiors.
knots=(np.clip(1.7*c1+0.8*c2-1.35,0,1)**1.7)*(plume+.3*branches)
brightness = (.18+.4*n2+.22*n3)*base
brightness+=knots*.42
brightcenter=np.exp(-((x+.08)/.45)**2)*np.exp(-(dist/.25)**2)
brightness+=brightcenter*.28*(1-mask)
# Small complex emissive ridge where stars are born.
ridge=np.clip((n2*.5+n3*.5-.49)*3,0,1)*np.exp(-0.5*(dist/.23)**2)*(1-mask)
brightness+=ridge*.15*fade_x
# Luminous and dark nebular bands.
red  = brightness*(.22+.52*warm+.30*violet+.11*cyan)
green= brightness*(.36+.42*warm+.31*cyan+.09*violet)
blue = brightness*(.64+.13*warm+.41*cyan+.20*violet)
rgbs=np.stack([red,green,blue],axis=2)
rgbs += (knots*.22)[...,None]*np.array([.93,.66,.83],np.float32)
# Red-blue emission filaments, subtle sharp nebula strands.
rgbs += (ridge*.22*violet)[...,None]*np.array([.65,.17,.67],np.float32)
# Alpha retains black voids inside the galactic structure, fade to transparent elsewhere.
alpha=np.clip((plume*.48+branches*.12+knots*.3)*(1-mask*.88)*fade_x,0,.86)
# Color adjusted for deep-space composition, no alpha-blended rectangular bounding box.
# PNG authored as unpremultiplied color; luminous stars painted on later.
rgba=np.empty((H,W,4), dtype=np.uint8)
rgba[:,:,:3]=(np.clip(rgbs/(alpha[...,None]+0.13)*1.28,0,1)*255).astype('uint8')
rgba[:,:,3]=(np.clip(alpha,0,1)*255).astype('uint8')
del rgbs,red,green,blue,plume,branches,n0,n1,n2,n3,c0,c1,c2,d0,d1,d2
image=Image.fromarray(rgba,'RGBA')
# Dense bands of dim stellar points, bright field-star population follows envelope.
field_alpha=np.asarray(image.getchannel('A')).astype(np.float32)/255
scatter=Image.new('RGBA',(W,H),(0,0,0,0)); dr=ImageDraw.Draw(scatter,'RGBA')
star_count=8300
for i in range(star_count):
    sx=int(rng.integers(4,W-4)); sy=int(rng.integers(4,H-4))
    a=field_alpha[sy,sx]
    if rng.random()>float(0.10+a*1.5): continue
    z=rng.random()
    if z<0.90: rr=.45; transparency=int(rng.integers(60,154))
    elif z<0.985: rr=.85; transparency=int(rng.integers(126,215))
    else: rr=1.5; transparency=int(rng.integers(185,248))
    palette=[(186,218,255),(235,243,255),(150,216,255),(255,226,180),(255,190,165)]
    cr,cg,cb=palette[int(rng.integers(0,len(palette)))]
    dr.ellipse((sx-rr,sy-rr,sx+rr,sy+rr), fill=(cr,cg,cb,transparency))
# brightest stars clustered around central filament, not random even distribution
stars=Image.new('RGBA',(W,H),(0,0,0,0)); draw=ImageDraw.Draw(stars, 'RGBA')
for i in range(100):
    sx=int(rng.integers(24,W-24)); sy=int(rng.integers(24,H-24))
    if rng.random()>min(0.85,float(field_alpha[sy,sx])*2.5): continue
    r=float(rng.uniform(.9,2.3))
    tint=[(174,223,255),(248,244,227),(255,204,170),(163,202,255)][int(rng.integers(4))]
    draw.ellipse((sx-r,sy-r,sx+r,sy+r),fill=(*tint,int(rng.uniform(135,232))))
    if r>1.7:
        ray=6*r
        draw.line((sx-ray,sy,sx+ray,sy), fill=(*tint,55), width=1)
        draw.line((sx,sy-ray,sx,sy+ray), fill=(*tint,65), width=1)
# Star glows created on tiny layer with downsample/blur
blur=stars.filter(ImageFilter.GaussianBlur(4.8))
image=Image.alpha_composite(image,scatter)
image=Image.alpha_composite(image,blur)
image=Image.alpha_composite(image,stars)
path=out/'milky_way_2048.png'
# Exaggerate distant color contrast gently for a kid-friendly display.
boost = np.asarray(image, dtype=np.float32).copy()
boost[:,:,:3] = np.minimum(255.0, boost[:,:,:3] * 1.12)
boost[:,:,3] = np.minimum(240.0, boost[:,:,3] * 1.42)
image = Image.fromarray(boost.astype('uint8'), 'RGBA')
image.save(path, optimize=True)
# Representative preview composited over near-black background (no copyright images)
bg=Image.new('RGBA',(W,H),(2,5,13,255))
bg.alpha_composite(image)
bg.convert('RGB').resize((1200,600),Image.Resampling.LANCZOS).save(str(root/'docs/milky_way_preview.jpg'),quality=91)
print(path, path.stat().st_size)
