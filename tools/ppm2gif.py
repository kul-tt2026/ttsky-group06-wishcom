#!/usr/bin/env python3
"""Plak alle shot*.ppm aan elkaar tot een animatie.
   python3 ppm2gif.py          -> egg_anim.gif
"""
import glob
from PIL import Image
files = sorted(glob.glob("shot*.ppm"))
if not files:
    raise SystemExit("geen shot*.ppm gevonden -- eerst vvp sim draaien")
frames = [Image.open(f).convert("P", palette=Image.ADAPTIVE) for f in files]
frames[0].save("egg_anim.gif", save_all=True, append_images=frames[1:],
               duration=100, loop=0)
print(f"egg_anim.gif geschreven ({len(frames)} beelden)")