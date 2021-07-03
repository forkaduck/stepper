#!/bin/bash

tests_dir="$PWD/tests"
src_dir="$PWD/src"

mkdir -v -p "$tests_dir"

cd "$tests_dir" || exit

echo "[+] Deleting old simulation results"
rm ./*.vvp ./*.vcd

dirlist=($(find . -name "test_*.v" | tr -s '\n' ' '))

for i in "${dirlist[@]}"; do
    echo -e "\n[+] Compiling $i into vvp file"
    iverilog -o "$i"vp "$i"

    if [ $? -eq 0 ]; then
        echo -e "\n[+] --- Simulation output of $i ---"
        vvp "$i"vp
    else
        echo -e "\n[!] Simulation was hasn't been started" \
        "because no vvp file was found!"
    fi
done
