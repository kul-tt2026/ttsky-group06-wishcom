#!/usr/bin/env python3
"""PRESS ANY BUTTON uit title_egg.v -> title_press.hex (5 regels van 64 bits).
   Draaien vanuit src/:  python3 ../tools/press2hex.py
"""
import re
rows = [0] * 5
n = 0
for m in re.finditer(r"\{3'd(\d+),\s*6'd(\d+)\}:\s*pon\s*=\s*1'b1;",
                     open("title_egg.v").read()):
    r, c = int(m.group(1)), int(m.group(2))
    rows[r] |= 1 << c
    n += 1
with open("title_press.hex", "w") as f:
    for v in rows:
        f.write(f"{v:016x}\n")
print(f"{n} pixels -> title_press.hex (5 x 64 bits)")
