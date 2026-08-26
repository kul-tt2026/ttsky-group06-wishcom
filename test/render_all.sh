#!/bin/bash
set -e

mkdir -p figures

# Vaste bouwsteen: -DNO_TITLE eerst, dan -o <naam>, dan de bronbestanden.
# -y ../src laat iverilog de rest zelf opzoeken op modulenaam.
# sprites.v moet er apart bij, want daar zitten meerdere modules in een bestand.

build () {          # build <simnaam> <testbench>
  iverilog -g2012 -DNO_TITLE -o "$1" -y ../src "$2" ../src/sprites.v
}

topng () {          # topng <doelnaam>
  python3 -c "from PIL import Image; Image.open('frame.ppm').save('figures/$1.png')"
  echo "✓ figures/$1.png"
}

echo ""
build sim_home_lvl1 home_lvl1_tb.v
vvp sim_home_lvl1
topng home_lvl1_render

echo ""
build sim_home_lvl2 home_lvl2_tb.v
vvp sim_home_lvl2
topng home_lvl2_render

echo ""
build sim_home_lvl3 home_lvl3_tb.v
vvp sim_home_lvl3
topng home_lvl3_render

echo ""
build sim_gameover gameover_tb.v
vvp sim_gameover
topng gameover_render

echo ""
build sim_chest_menu chest_menu_tb.v
vvp sim_chest_menu
topng chest_menu_render

# De kist-layout schrijft drie eigen .ppm's in plaats van frame.ppm
echo ""
build sim_chest_pick chest_pick_tb.v
vvp sim_chest_pick
python3 -c "from PIL import Image; [Image.open(f'chest_{s}.ppm').save(f'figures/chest_{s}.png') for s in ['pick','open','result']]"
echo "✓ figures/chest_pick.png, chest_open.png, chest_result.png"

# De dragon-benches gebruiken renderer.v niet, dus -DNO_TITLE is daar zinloos.
echo ""
iverilog -g2012 -o sim_dragon_lvl2 -y ../src dragon_lvl2_tb.v ../src/sprites.v
vvp sim_dragon_lvl2
topng lvl2_render

echo ""
iverilog -g2012 -o sim_dragon_lvl3 -y ../src dragon_lvl3_tb.v ../src/sprites.v
vvp sim_dragon_lvl3
topng lvl3_render

echo ""
iverilog -g2012 -o sim_dragon_lvl4 -y ../src dragon_lvl4_tb.v ../src/sprites.v
vvp sim_dragon_lvl4
topng lvl4_render

echo ""
build sim_egg_frames egg_frames_tb.v
vvp sim_egg_frames
python3 -c "from PIL import Image; [Image.open(f'egg_frame_{i}.ppm').save(f'figures/egg_frame_{i}.png') for i in range(0, 6)]"
echo "✓ figures/egg_frame_0.png t/m egg_frame_5.png"

# Een keer opruimen, helemaal aan het eind
rm -f sim_* *.ppm

echo ""
echo "Klaar! Alle afbeeldingen staan in figures/."