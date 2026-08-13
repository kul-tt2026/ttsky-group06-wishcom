from PIL import Image
import sys
import os

def convert_dragon(image_path, output_v="dragon_rom.v"):
    if not os.path.exists(image_path):
        print(f"Fout: Bestand '{image_path}' niet gevonden!", file=sys.stderr)
        sys.exit(1)

    # Open de afbeelding en converteer naar RGBA (Rood, Groen, Blauw, Alpha)
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size

    with open(output_v, "w") as f:
        f.write(f"// Generated from {image_path} ({width}x{height})\n")
        f.write("// Pixel-ROM Case Statement\n\n")
        f.write("case (row[5:0])\n")

        for y in range(height):
            f.write(f"  6'd{y}: case (col[5:0])\n")
            for x in range(width):
                r, g, b, a = img.getpixel((x, y))

                # ---------------------------------------------------------
                # Kleur-detectie logica
                # ---------------------------------------------------------

                # 0. Transparant / Zeer donkere achtergrond
                if a < 128 or (r < 35 and g < 35 and b < 45):
                    code = "color0"

                # 1. Zwart / Omtrek / Oogjes
                elif r < 45 and g < 45 and b < 45:
                    code = "color1"

                # 4. WIT (Eierschaal & Oogglim)
                # Zodra R, G en B alle drie hoog zijn (>170), is het gegarandeerd wit!
                elif r > 170 and g > 170 and b > 170:
                    code = "color4"

                # 5 & 6. Grijstinten (Horentjes)
                elif abs(r - g) < 25 and abs(g - b) < 25:
                    if r > 120:
                        code = "color5"  # Medium grijs
                    else:
                        code = "color6"  # Donkergrijs

                # 2 & 3. Groentinten (Lijfje, Buikje, Eivlekken)
                elif g > r and g > b:
                    # Lichtgroen / Neon heeft een hoge groen- én roodwaarde
                    if g > 180 and r > 100:
                        code = "color3"  # Fel/Lichtgroen
                    else:
                        code = "color2"  # Medium groen

                # Fallback naar wit als het nergens anders onder valt
                else:
                    code = "color4"

                f.write(f"    6'd{x}: code = {code};\n")

            f.write("    default: code = color0;\n")
            f.write("  endcase\n")

        f.write("  default: code = color0;\n")
        f.write("endcase\n")

    print(f"✓ Succesvol gegenereerd en opgeslagen in {output_v}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Gebruik: python3 png2rom.py <afbeelding.png>")
        sys.exit(1)
    
    convert_dragon(sys.argv[1])