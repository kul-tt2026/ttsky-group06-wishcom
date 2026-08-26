#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Cellen en dure operaties per module.
#
#   cd src && bash ../tools/cellcount.sh
#
# Twee passes per module:
#   synth     -> aantal gates na mapping (het getal dat telt)
#   coarse    -> $mul / $div / $mod voordat techmap ze platslaat
#
# De modulelijst komt uit yosys zelf, niet uit bestandsnamen: background en
# gameover_text wonen in sprites.v en zou je anders missen.
#
# LEZEN: $div en $mod zijn altijd fout, honderden cellen per stuk.
#        $mul met een CONSTANTE is prima -- dat worden shift-adds.
# ---------------------------------------------------------------------------
set -u
YOSYS=${YOSYS:-yowasp-yosys}
LOGS=$(mktemp -d)

mods=$($YOSYS -p "read_verilog -sv *.v; ls" 2>&1 \
       | awk '/modules:/{f=1;next} f && NF==1 && $1 !~ /^[0-9]/ {print $1}')

if [ -z "$mods" ]; then
  echo "Geen modules gevonden.  Leesfout:"
  $YOSYS -p "read_verilog -sv *.v" 2>&1 | tail -20
  exit 1
fi

printf "%8s  %-22s %s\n" CELLEN MODULE "DURE OPERATIES"
printf "%8s  %-22s %s\n" "--------" "----------------------" "-----------------"

for m in $mods; do
  $YOSYS -p "read_verilog -sv *.v; synth -top $m; stat" \
         > "$LOGS/$m.syn" 2>&1
  $YOSYS -p "read_verilog -sv *.v; hierarchy -top $m; proc; opt; stat" \
         > "$LOGS/$m.coarse" 2>&1
  cells=$(grep "Number of cells" "$LOGS/$m.syn" | tail -1 | awk '{print $NF}')
  ops=$(grep -E '^[[:space:]]+\$(mul|div|mod|pow)' "$LOGS/$m.coarse" \
        | awk '{printf "%s x%s  ", $1, $2}')
  echo "${cells:-ERR}|$m|${ops:-.}"
done | sort -t'|' -k1 -rn | awk -F'|' '{printf "%8s  %-22s %s\n", $1, $2, $3}'

echo
echo "=== hele chip ==="
$YOSYS -p "read_verilog -sv *.v; synth -top tt_um_dragonchi; stat" \
       > "$LOGS/_top.syn" 2>&1
grep "Number of cells" "$LOGS/_top.syn" | tail -1
grep -icE '\$_?dlatch' "$LOGS/_top.syn" | sed 's/^0$/geen latches/;s/^\([1-9].*\)/LATCHES GEVONDEN: \1/'

total=$(grep "Number of cells" "$LOGS/_top.syn" | tail -1 | awk '{print $NF}')
if [ -n "${total:-}" ]; then
  awk -v t="$total" 'BEGIN{printf "utilization: %.1f %% van 6 tiles (~36700 cellen)\n", t*100/36700}'
fi

echo
echo "logs: $LOGS"
echo "bij ERR:  grep -i error $LOGS/<module>.syn"
