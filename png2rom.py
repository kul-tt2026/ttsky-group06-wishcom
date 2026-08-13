from PIL import Image
import sys

def convert_dragon(image_path="lvl1.png", output_v="dragon_rom.v"):
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size

    with open(output_v, "w") as f:
        f.write("case (row[5:0])\n")
        for y in range(height):
            f.write(f"  6'd{y}: case (col[5:0])\n")
            for x in range(width):
                r, g, b, a = img.getpixel((x, y))

                # 1. Transparant (Achtergrond)
                if a < 128:
                    code = "color0"

                # 2. Zwart (Contouren / Oogjes)
                elif r < 50 and g < 50 and b < 50:
                    code = "color1"

                # 3. Grijstinten (Horentjes)
                elif abs(r - g) < 20 and abs(g - b) < 20 and r < 200:
                    code = "color5" if r > 100 else "color6"

                # 4. WITTE EIERSCHAAL (Zit voornamelijk aan de onderkant/links: y >= 18 of x < 15)
                elif (r > 160 and g > 160 and b > 160) and (y >= 20 or x <= 14):
                    code = "color4"

                # 5. LICHTGROEN / BUIKJE & NEKJE (Witte/lichte accenten op de draak zelf)
                elif (r > 160 and g > 160 and b > 160) or (g > 160 and r > 120):
                    code = "color7"

                # 6. GROEN (Lijfje en vlekjes van de draak)
                elif g > r and g > b:
                    code = "color3" if g > 170 else "color2"

                else:
                    code = "color4"

                f.write(f"    6'd{x}: code = {code};\n")
            f.write("    default: code = color0;\n  endcase\n")
        f.write("  default: code = color0;\nendcase\n")

    print(f"✓ Nieuwe ROM succesvol gegenereerd in {output_v}!")

if __name__ == "__main__":
    file_name = sys.argv[1] if len(sys.argv) > 1 else "lvl1.png"
    convert_dragon(file_name)