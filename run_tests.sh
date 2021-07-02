#!/bin/bash

mkdir -v -p test_output

dirlist=($(find . -name "test_*.v" | tr -s '\n' ' '))

for i in "${dirlist[@]}"; do
    IFS='_' read -ra curr <<< "$i"

    cd test_output || exit

    echo "[+] Compiling $i into vvp file"
    iverilog -o "$i"vp ../"$i" ../"${curr[1]}"

    echo -e "\n[+] Running Simulation for $i"
    vvp "$i"vp
done
