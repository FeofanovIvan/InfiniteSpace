#!/usr/bin/env python3
"""Extract unchanged RGBA ships from original 1536×1024 sheet. Needs Pillow, OpenCV, numpy."""
from pathlib import Path
import json
import cv2
import numpy as np
from PIL import Image
import sys
src=Path(sys.argv[1]) if len(sys.argv)>1 else Path("Futuristic Pearl Pod Collection(1).png")
out=Path(sys.argv[2]) if len(sys.argv)>2 else Path("assets/story")
out.mkdir(parents=True,exist_ok=True)
im=np.asarray(Image.open(src).convert("RGBA"))
n,cc,stats,_=cv2.connectedComponentsWithStats((im[:,:,3]>20).astype(np.uint8),8)
ids=[i for i in range(1,n) if stats[i,cv2.CC_STAT_AREA]>100000]
assert len(ids)==5
ids.sort(key=lambda i:(stats[i,1]>700,stats[i,1]>400,stats[i,0]))
names=["m33_civilian_01.png","m33_merchant_02.png","m33_courier_03.png","m33_patrol_04.png","m33_cargo_05.png"]
meta=[]
for index,i in enumerate(ids):
    x,y,w,h=map(int,stats[i,:4])
    mask=cv2.dilate((cc==i).astype("uint8"),np.ones((9,9),np.uint8),iterations=1)
    l=max(0,x-12);t=max(0,y-12);r=min(im.shape[1],x+w+12);b=min(im.shape[0],y+h+12)
    crop=im[t:b,l:r].copy()
    crop[:,:,3]=np.where(mask[t:b,l:r]!=0,crop[:,:,3],0)
    crop[crop[:,:,3]==0,:3]=0
    Image.fromarray(crop,"RGBA").save(out/names[index],optimize=True)
    meta.append({"name":names[index],"source_bbox":[x,y,w,h],"cutout_size":[r-l,b-t]})
(out/"m33_crop_provenance.json").write_text(json.dumps({"source_file":src.name,"ships":meta},ensure_ascii=False,indent=2),encoding="utf-8")
print("Extracted five original RGBA ships to",out)
