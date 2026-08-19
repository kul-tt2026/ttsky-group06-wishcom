#!/bin/bash
set -e

# Zorg ervoor dat de map test/figures bestaat
mkdir -p figures

echo "=== 1/2: Egg render genereren... ==="
iverilog -g2012 -o sim_egg egg_tb.v ../src/dragon_draw.v ../src/sprites.v
vvp sim_egg
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/egg_render.png')"
echo "✓ Opslaan voltooid: figures/egg_render.png"

echo ""

echo "=== 1/2: Egg render genereren... ==="
iverilog -g2012 -o sim_egg dragon_lvl1_tb.v ../src/dragon_draw.v ../src/sprites.v
vvp sim_egg
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/lvl1_render.png')"
echo "✓ Opslaan voltooid: figures/lvl1_render.png"

echo ""
echo "=== 2/2: Module render genereren... ==="
iverilog -g2012 -o sim_render render_tb.v ../src/sprites.v ../src/satisfactionbar.v ../src/coinbar.v ../src/hearts.v
vvp sim_render
python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/module_render.png')"
echo "✓ Opslaan voltooid: figures/module_render.png"

# Opruimen van tijdelijke bestanden
rm -f sim_egg sim_render frame.ppm

echo ""
echo "Klaar! Alle afbeeldingen staan in de map figures/."