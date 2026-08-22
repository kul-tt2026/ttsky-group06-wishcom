from PIL import Image

# 1. Open je afbeelding en herschaal exact naar 48x48
img = Image.open("src/media/lvl3.png").convert("RGBA")
img = img.resize((48, 48), Image.Resampling.NEAREST)

# 2. Definieer het 8-kleuren palet (index 0 t/m 7)
PALETTE = {
    0: (0, 0, 0, 0),        # 0: Transparant
    1: (0, 0, 0, 255),      # 1: Zwart / Outline
    2: (0, 128, 0, 255),    # 2: Donkergroen
    3: (85, 255, 85, 255),  # 3: Felgroen
    4: (255, 255, 255, 255),# 4: Wit
    5: (170, 170, 170, 255),# 5: Grijs
    6: (85, 85, 85, 255),   # 6: Donkergrijs
    7: (170, 255, 170, 255) # 7: Lichtgroen
}

def get_color_code(pixel):
    if pixel[3] < 128:  # Transparante pixel
        return 0
    # Zoek dichtstbijzijnde kleur in het palet (Euclidische afstand)
    min_dist = float("inf")
    best_idx = 0
    for idx, col in PALETTE.items():
        if idx == 0:
            continue
        dist = sum((a - b) ** 2 for a, b in zip(pixel[:3], col[:3]))
        if dist < min_dist:
            min_dist = dist
            best_idx = idx
    return best_idx

# 3. Schrijf exact 2.304 regels (48x48) naar dragon_l4.hex
with open("dragon_l4.hex", "w") as f:
    for y in range(48):
        for x in range(48):
            px = img.getpixel((x, y))
            code = get_color_code(px)
            f.write(f"{code:x}\n")

print("dragon_l4.hex gegenereerd met 2304 regels!")