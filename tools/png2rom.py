import sys
from PIL import Image

def png_to_verilog(image_path, module_name, bits=3):
    img = Image.open(image_path).convert('RGBA')
    width, height = img.size

    print(f"// Generated from {image_path} ({width}x{height})")
    print(f"// Module / block name: {module_name}")
    print(f"if (row < 6'd{height} && col < 6'd{width}) begin")
    print("  case (row[5:0])")

    for y in range(height):
        print(f"    6'd{y}: case (col[5:0])")
        for x in range(width):
            r, g, b, a = img.getpixel((x, y))
            
            # 0 = Transparant (alpha == 0)
            if a < 128:
                code = 0
            # 1 = Zwart / Rand / Donker
            elif r < 60 and g < 60 and b < 60:
                code = 1
            # 2 = Groen (Draak / Vlekken)
            elif g > r and g > b:
                code = 2
            # 3 = Wit / Lichtgrijs (Eierschaal / Horentjes)
            else:
                code = 3
            
            print(f"      6'd{x}: code = {bits}'d{code};")
        print("      default: code = 3'd0;")
        print("    endcase")

    print("    default: code = 3'd0;")
    print("  endcase")
    print("end")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Gebruik: python3 tools/png2rom.py <pad_naar_png> [--name <naam>] [--bits <bits>]")
        sys.exit(1)
        
    img_path = sys.argv[1]
    name = "dragon"
    bits = 3
    
    if "--name" in sys.argv:
        name = sys.argv[sys.argv.index("--name") + 1]
    if "--bits" in sys.argv:
        bits = int(sys.argv[sys.argv.index("--bits") + 1])
        
    png_to_verilog(img_path, name, bits)
