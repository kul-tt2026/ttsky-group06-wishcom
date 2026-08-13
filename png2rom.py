from PIL import Image
import sys

def convert():
    img = Image.open("lvl1.png").convert("RGBA")
    width, height = img.size

    with open("dragon_rom.v", "w") as f:
        f.write("case (row[5:0])\n")
        for y in range(height):
            f.write(f"  6'd{y}: case (col[5:0])\n")
            for x in range(width):
                r, g, b, a = img.getpixel((x, y))

                # 1. Transparant (Achtergrond)
                if a < 128:
                    code = "color0"
                    
                # 2. Zwart / Omtrek (Heel donker)
                elif r < 50 and g < 50 and b < 50:
                    code = "color1"

                # 3. WIT (Eierschaal & Oogglim)
                # MOET BOVEN GROEN STAAN! 
                # Als R, G én B alle drie helder zijn (> 150), is het de EIERSCHAAL,
                # zelfs als G net 1 of 2 puntjes hoger is dan R!
                elif r > 150 and g > 150 and b > 150:
                    code = "color4"

                # 4. Grijstinten (Horentjes)
                elif abs(r - g) < 20 and abs(g - b) < 20:
                    code = "color5" if r > 100 else "color6"

                # 5. Groentinten (Draak) - Komt pas NA de wit-check!
                elif g > r and g > b:
                    code = "color3" if (g > 170 and r > 90) else "color2"

                else:
                    code = "color4" # Fallback naar wit

                f.write(f"    6'd{x}: code = {code};\n")
            f.write("    default: code = color0;\n  endcase\n")
        f.write("  default: code = color0;\nendcase\n")

if __name__ == "__main__":
    convert()