#!/bin/bash

if [[ "$1" == "-h" ]]; then
    echo "$0"
    echo "   -h          // prints this help"
    echo "   <test_*.v>  // run just that specific test"
    exit
fi

echo "[+] Deleting old simulation results"
rm ./*.vvp ./*.vcd

if [ -z $1 ]; then
    echo "[+] Running all tests"
    dirlist=($(find . -name "test_*.v" | tr -s '\n' ' '))

    for i in "${dirlist[@]}"; do
        echo -e "\n[+] Compiling $i into vvp file"

        if iverilog -o "$i"vp "$i"; then
            echo -e "\n[+] --- Simulation output of $i ---"
            vvp "$i"vp
        else
            echo -e "\n[!] Simulation was hasn't been started" \
            "because no vvp file was found!"
        fi
    done
else
    if [ -f "$1" ]; then
        echo "[+] Running just $1"

        echo -e "\n[+] Compiling $i into vvp file"

        if iverilog -o "$1"vp "$1"; then
            echo -e "\n[+] --- Simulation output of $1 ---"
            vvp "$1"vp
        else
            echo -e "\n[!] Simulation was hasn't been started" \
            "because no vvp file was found!"
        fi
    else
        echo "[!] No file found with that name!"
    fi
fi
