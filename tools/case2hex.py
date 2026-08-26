#!/usr/bin/env python3
"""De twee case-blokken uit title_card.v -> hex-ROM's.
   Draaien vanuit src/:   python3 ../tools/case2hex.py

   title_letters.hex : 37 rijen x 200 bits (1 bit per pixel)   -> 50 hex-tekens
   title_wings.hex   : 19 rijen x  33 x 2 bits, gepad tot 72   -> 18 hex-tekens
"""
import re

src = open("title_card.v").read()
letters_src, wings_src = src.split("vleugel-ROM")

# ---- letters: {6'drij, 8'dkolom}: on = 1'b1; --------------------------------
lrows = [0] * 37
nl = 0
for m in re.finditer(r"\{6'd(\d+),\s*8'd(\d+)\}:\s*on\s*=\s*1'b1;", letters_src):
    r, c = int(m.group(1)), int(m.group(2))
    lrows[r] |= 1 << c
    nl += 1

with open("title_letters.hex", "w") as f:
    for v in lrows:
        f.write(f"{v:050x}\n")

# ---- vleugels: {5'drij, 6'dkolom}: wcode = 2'dN; ----------------------------
wrows = [0] * 19
nw = 0
for m in re.finditer(r"\{5'd(\d+),\s*6'd(\d+)\}:\s*wcode\s*=\s*2'd(\d+);", wings_src):
    r, c, v = int(m.group(1)), int(m.group(2)), int(m.group(3))
    wrows[r] |= v << (2 * c)
    nw += 1

with open("title_wings.hex", "w") as f:
    for v in wrows:
        f.write(f"{v:018x}\n")

print(f"letters: {nl} pixels -> title_letters.hex (37 x 200 bits)")
print(f"vleugels: {nw} pixels -> title_wings.hex  (19 x  72 bits)")
