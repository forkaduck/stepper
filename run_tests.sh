#!/bin/bash

tests_dir="$PWD/tests"
src_dir="$PWD/src"

mkdir -v -p "$tests_dir"

cd "$tests_dir" || exit

dirlist=($(find . -name "test_*.v" | tr -s '\n' ' '))

for i in "${dirlist[@]}"; do
    IFS='_' read -ra curr <<< "$i"

    echo "[+] Compiling $i into vvp file"
    iverilog -o "$i"vp "$i" "$src_dir"/"${curr[1]}"

    echo -e "\n[+] Running Simulation for $i"
    vvp "$i"vp
done
