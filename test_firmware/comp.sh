#!/bin/bash

riscv64-unknown-elf-gcc -mabi=ilp32 -march=rv32i -nostdlib main.c
riscv64-unknown-elf-strip a.out
riscv64-unknown-elf-objcopy -O binary a.out ../firmware/target/riscv32imac-unknown-none-elf/release/stepper.bin
