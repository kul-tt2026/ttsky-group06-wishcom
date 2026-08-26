#!/usr/bin/env bash
# draaien vanuit src/ :  bash ../tools/egg_breakdown.sh
set -u
cp title_egg.v /tmp/te.bak
trap 'cp /tmp/te.bak title_egg.v' EXIT

meet () { yowasp-yosys -p "read_verilog -sv title_egg.v; synth -top title_egg; stat" 2>&1 \
          | grep -m1 "Number of cells" | awk '{print $NF}'; }

stub () { cp /tmp/te.bak title_egg.v
          for p in "$@"; do
            sed -i -E "s|^(\s*assign\s+$p\s*=).*|\1 1'b0;|" title_egg.v
          done; }

cp /tmp/te.bak title_egg.v      ; printf "baseline          %s\n" "$(meet)"
stub crack_on                   ; printf "zonder barst      %s\n" "$(meet)"
stub flash_on flash_rim         ; printf "zonder flits      %s\n" "$(meet)"
stub press_on                   ; printf "zonder tekst      %s\n" "$(meet)"
stub ground_on ground_shadow    ; printf "zonder grond      %s\n" "$(meet)"
stub egg_on egg_code crack_on   ; printf "zonder ei + barst %s\n" "$(meet)"
