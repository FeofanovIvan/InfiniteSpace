#!/usr/bin/env python3
"""Extract five native LMC sprites from unchanged RGBA source sheet."""
from pathlib import Path
from PIL import Image
import cv2
import numpy as np
import sys
if len(sys.argv) != 3:
    raise SystemExit('Usage: python3 crop_lmc_fleet.py SOURCE.png OUTPUT_FOLDER')
src,out=Path(sys.argv[1]),Path(sys.argv[2])
out.mkdir(parents=True,exist_ok=True)
source=np.array(Image.open(src).convert('RGBA'))
a=source[:,:,3]
n,labels,stats,_=cv2.connectedComponentsWithStats((a>32).astype('uint8'),8)
ids=[i for i in range(1,n) if stats[i,cv2.CC_STAT_AREA]>100000]
assert len(ids)==5, 'Expected five objects in original artwork'
ids=sorted(ids,key=lambda i:(0 if stats[i,1]<300 else 1 if stats[i,1]<550 else 2,stats[i,0]))
names=['lmc_merchant_01.png','lmc_shuttle_02.png','lmc_freighter_03.png','lmc_explorer_04.png','lmc_escort_05.png']
for idx,name in zip(ids,names):
    mask=(labels==idx).astype(np.uint8)
    grown=cv2.dilate(mask,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(13,13)))
    gx,gy,gw,gh=cv2.boundingRect(cv2.findNonZero(grown))
    l=max(0,gx-10);t=max(0,gy-10);r=min(source.shape[1],gx+gw+10);b=min(source.shape[0],gy+gh+10)
    sub=source[t:b,l:r].copy()
    near=np.clip(cv2.GaussianBlur(grown[t:b,l:r].astype(np.float32),(0,0),sigmaX=2.5)*1.3,0,1)
    sub[:,:,3]=np.minimum(sub[:,:,3].astype(np.float32),sub[:,:,3].astype(np.float32)*near).astype(np.uint8)
    sub[sub[:,:,3]==0,:3]=0
    Image.fromarray(sub,'RGBA').save(out/name,optimize=True)
print('Cropped 5 PNG sprites from supplied source:',out)
