#!/usr/bin/env python3
# tools/egg_decompose.py -- draaien vanuit src/: python3 ../tools/egg_decompose.py
# Leest egg_128s.hex (16384 regels, 3-bit codes) en maakt:
#   egg_shape.hex  : 128 regels, halve breedte per rij (2 hexcijfers)
#   egg_spots.hex  : 32 regels van 32 bits (8 hexcijfers), 1 = stip
# Plus compare.ppm: origineel | reconstructie naast elkaar.
CODE_SPOT = 5          # donkergroene stippen -- pas aan als jullie code anders is
EDGE = 2               # dikte van de zwarte rand in bronpixels

rom = [int(l, 16) for l in open("egg_128s.hex") if l.strip()]
assert len(rom) == 16384
px = lambda x, y: rom[y * 128 + x]


# vorm: per rij BUITEN-halfbreedte (alles != 0) en BINNEN-halfbreedte
# (alles != 0 en != 1, dus waar de witte schaal begint)
halfw_out, halfw_in, asym = [], [], 0
for y in range(128):
    xs_o = [x for x in range(128) if px(x, y) != 0]
    xs_i = [x for x in range(128) if px(x, y) not in (0, 1)]
    if not xs_o:
        halfw_out.append(0); halfw_in.append(0); continue
    lo, hi = xs_o[0], xs_o[-1]
    halfw_out.append((hi - lo) // 2 + 1)
    asym = max(asym, abs((lo + hi) // 2 - 63))
    if not xs_i:
        halfw_in.append(0)                       # rij is volledig rand
    else:
        li, hi2 = xs_i[0], xs_i[-1]
        halfw_in.append((hi2 - li) // 2 + 1)
print(f"max afwijking van het midden: {asym} px")

with open("egg_shape.hex", "w") as f:                # 3 hexcijfers per regel
    for o, i in zip(halfw_out, halfw_in):
        f.write(f"{(o << 6) | i:03x}\n")

# stippen: 4x4 blokken, meerderheid stip-pixels = stip
spots = []
for by in range(32):
    row = 0
    for bx in range(32):
        n = sum(1 for dy in range(4) for dx in range(4)
                if px(bx*4+dx, by*4+dy) == CODE_SPOT)
        if n >= 6: row |= 1 << bx        # drempel: 6 van 16
    spots.append(row)
with open("egg_spots.hex", "w") as f:
    for r in spots: f.write(f"{r:08x}\n")

# reconstructie en vergelijking
PAL = {0:(80,160,224), 1:(0,0,0), 2:(170,170,170), 3:(0,255,0),
       4:(255,255,255), 5:(0,170,0), 6:(85,85,85), 7:(170,255,85)}
def recon(x, y):
    o, i = halfw_out[y], halfw_in[y]
    d = abs(x - 63) + (1 if x > 63 else 0)
    if o == 0 or d >= o: return 0
    if i == 0 or d >= i: return 1                    # rand, rondom gesloten
    if (spots[y // 4] >> (x // 4)) & 1: return CODE_SPOT
    return 4
with open("compare.ppm", "w") as f:
    f.write("P3 260 128 255\n")
    for y in range(128):
        for x in range(128): f.write("%d %d %d " % PAL[px(x, y)])
        for x in range(4):   f.write("255 0 255 ")     # magenta scheidslijn
        for x in range(128): f.write("%d %d %d " % PAL[recon(x, y)])
        f.write("\n")
print("bekijk compare.ppm: links origineel, rechts reconstructie")