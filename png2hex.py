#!/usr/bin/env python3
import sys
from PIL import Image

# Mapping van RGB(A) tuples naar jouw 3-bit kleurcodes (0..7)
# Pas de RGB-waarden aan op basis van jouw sprite palette:
COLOR_MAP = {
    (0, 0, 0, 0): 0,        # Transparant (alpha = 0)
    (0, 0, 0): 1,          # Zwart (Outline)
    (0, 100, 0): 2,        # Donkergroen (Vlekken)
    (0, 255, 0): 3,        # Felgroen (Lijf)
    (255, 255, 255): 4,    # Wit (Eierschaal)
    (128, 128, 128): 5,    # Grijs
    (64, 64, 64): 6,       # Donkergrijs
    (144, 238, 144): 7,    # Lichtgroen (Buik)
}

def get_color_code(pixel):
    # Als de pixel RGBA is en transparant is:
    if len(pixel) == 4 and pixel[3] == 0:
        return 0
    
    rgb = pixel[:3]
    if rgb in COLOR_MAP:
        return COLOR_MAP[rgb]
    
    # Zoek de dichtstbijzijnde kleur als er lichte kleurafwijkingen zijn
    best_match = 0
    min_dist = float("inf")
    for map_rgb, code in COLOR_MAP.items():
        if len(map_rgb) == 3:
            dist = sum((a - b) ** 2 for a, b in zip(rgb, map_rgb))
            if dist < min_dist:
                min_dist = dist
                best_match = code
    return best_match

def convert_png_to_hex_64x64(image_path, output_hex_path):
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size

    # Maak een leeg 64x64 canvas (alles transparant = code 0)
    grid = [[0 for _ in range(64)] for _ in range(64)]

    # Plak de sprite linksboven (of met offset) in het 64x64 raster
    for y in range(min(h, 64)):
        for x in range(min(w, 64)):
            pixel = img.getpixel((x, y))
            grid[y][x] = get_color_code(pixel)

    # Schrijf weg naar hex
    with open(output_hex_path, "w") as f:
        for y in range(64):
            row_hex = [f"{code:x}" for code in grid[y]]
            f.write(" ".join(row_hex) + "\n")

    print(f"64x64 HEX gegenereerd: {output_hex_path} (4096 pixels)")
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Gebruik: python3 png2hex.py <invoer.png> <uitvoer.hex>")
        sys.exit(1)
    
    convert_png_to_hex_64x64(sys.argv[1], sys.argv[2])