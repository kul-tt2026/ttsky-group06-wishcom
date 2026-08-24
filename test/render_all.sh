#!/bin/bash
set -e

# Zorg ervoor dat de map test/figures bestaat
mkdir -p figures
echo ""
iverilog -g2012 -o sim_egg home_lvl1_tb.v ../src/dragon_draw.v ../src/sprites.v ../src/home.v ../src/renderer.v ../src/chest_draw.v ../src/satisfactionbar.v ../src/coinbar.v ../src/hearts.v ../src/draw_buttons.v
vvp sim_egg
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/home_lvl1_render.png')"
echo "✓ Opslaan voltooid: figures/home_render.png"

# Zorg ervoor dat de map test/figures bestaat
mkdir -p figures
echo ""
iverilog -g2012 -o sim_egg home_lvl2_tb.v ../src/dragon_draw.v ../src/sprites.v ../src/home.v ../src/renderer.v ../src/chest_draw.v ../src/satisfactionbar.v ../src/coinbar.v ../src/hearts.v ../src/draw_buttons.v
vvp sim_egg
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/home_lvl2_render.png')"
echo "✓ Opslaan voltooid: figures/home_render.png"


# Zorg ervoor dat de map test/figures bestaat
mkdir -p figures
echo ""
iverilog -g2012 -o sim_egg home_lvl3_tb.v ../src/dragon_draw.v ../src/sprites.v ../src/home.v ../src/renderer.v ../src/chest_draw.v ../src/satisfactionbar.v ../src/coinbar.v ../src/hearts.v ../src/draw_buttons.v
vvp sim_egg
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/home_lvl3_render.png')"
echo "✓ Opslaan voltooid: figures/home_render.png"

# Opruimen van tijdelijke bestanden
rm -f sim_egg sim_render frame.ppm

iverilog -g2012 -o sim_egg dragon_lvl1_tb.v ../src/dragon_draw.v ../src/sprites.v
vvp sim_egg
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/egg_render.png')"
echo "✓ Opslaan voltooid: figures/egg_render.png"

echo ""

iverilog -g2012 -o sim_egg dragon_lvl2_tb.v ../src/dragon_draw.v ../src/sprites.v
vvp sim_egg
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/lvl2_render.png')"
echo "✓ Opslaan voltooid: figures/lvl2_render.png"

echo ""
iverilog -g2012 -o sim_render render_tb.v ../src/sprites.v ../src/satisfactionbar.v ../src/coinbar.v ../src/hearts.v
vvp sim_render
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/module_render.png')"
echo "✓ Opslaan voltooid: figures/module_render.png"

# Opruimen van tijdelijke bestanden
rm -f sim_egg sim_render frame.ppm

echo ""
iverilog -g2012 -o sim_egg dragon_lvl3_tb.v ../src/dragon_draw.v ../src/sprites.v
vvp sim_egg
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/lvl3_render.png')"
echo "✓ Opslaan voltooid: figures/lvl3_render.png"

# Opruimen van tijdelijke bestanden
rm -f sim_egg sim_render frame.ppm

echo ""
iverilog -g2012 -o sim_egg dragon_lvl4_tb.v ../src/dragon_draw.v ../src/sprites.v
vvp sim_egg
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/lvl4_render.png')"
echo "✓ Opslaan voltooid: figures/lvl4_render.png"

# Opruimen van tijdelijke bestanden
rm -f sim_egg sim_render frame.ppm
echo "Klaar! Alle afbeeldingen staan in de map figures/."