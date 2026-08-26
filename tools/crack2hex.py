#!/usr/bin/env python3
# tools/crack2hex.py -- draaien vanuit src/:  python3 ../tools/crack2hex.py
#
# Voert exact dezelfde stralen-wiskunde uit die in title_egg.v stond en legt
# per BRONPIXEL vast vanaf welk egg_frame hij barst (0 = nooit).  Omdat de
# barst monotoon groeit volstaat een enkele bitmap voor alle frames.
OX, OY   = 128, 112
DX0, DY0 = 141, 60           # OX + 13,  OY - 52
EX0, EY0 = 203, 172          # OX + 75,  OY + 60
FRAMES   = {1: (45, 2), 2: (90, 2), 3: (140, 2), 4: (200, 4)}   # (grow, cw)

def wob(t):
    hlf = t & 7
    trw = (7 - hlf) if (t >> 3) & 1 else hlf
    return trw * 2 - 7

def hit(lx, ly, frame):
    grow, cw = FRAMES[frame]
    tA = OY - ly                                    # straal A: omhoog
    if 0 <= tA < min(grow, 104) and abs(lx - (OX + (tA >> 2) + wob(tA))) <= cw:
        return True
    tB = OX - lx                                    # straal B: naar links
    if 0 <= tB < min(grow, 112) and abs(ly - (OY + (tB >> 2) + wob(tB))) <= cw:
        return True
    tC = ly - OY                                    # straal C: rechtsonder
    if 0 <= tC < min(grow, 130) and abs(lx - (OX + tC + (tC >> 2) + wob(tC))) <= cw:
        return True
    if frame >= 2:                                  # tak D
        tD = lx - DX0
        if 0 <= tD < min(max(grow - 52, 0), 70) and \
           abs(ly - (DY0 - (tD >> 2) + wob(tD))) <= 2:
            return True
    if frame >= 3:                                  # tak E
        tE = ly - EY0
        if 0 <= tE < min(max(grow - 60, 0), 60) and \
           abs(lx - (EX0 - tE + wob(tE))) <= 2:
            return True
    return False

# De barst werd in SCHERMpixels gerekend (256x256), de ROM staat in BRONpixels
# (128x128).  Per bronpixel kijken we of een van de vier schermpixels eronder
# raakt -- OR in plaats van bemonsteren, anders vallen dunne lijnen uiteen.
lvl = [0] * 16384
for sy in range(128):
    for sx in range(128):
        for f in (1, 2, 3, 4):
            if any(hit(2*sx + dx, 2*sy + dy, f) for dy in (0, 1) for dx in (0, 1)):
                lvl[sy * 128 + sx] = f
                break

with open("egg_crack.hex", "w") as f:
    for v in lvl:
        f.write(f"{v:x}\n")

xs = [i % 128 for i, v in enumerate(lvl) if v]
ys = [i // 128 for i, v in enumerate(lvl) if v]
print(f"{sum(1 for v in lvl if v)} gebarsten pixels van 16384")
print(f"bounding box: x {min(xs)}..{max(xs)}, y {min(ys)}..{max(ys)}")

for sy in range(0, 128, 2):                       # ruwe preview
    print("".join(".-=*#"[lvl[sy*128 + sx]] for sx in range(0, 128, 1)))