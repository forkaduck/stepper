# Stepper
A RISC-V based uC written in verilog and a hardware design that can be used with it.

[![Lint](https://github.com/0xDEADC0DEx/stepper/actions/workflows/lint.yml/badge.svg)](https://github.com/0xDEADC0DEx/stepper/actions/workflows/lint.yml)
[![Rust Build](https://github.com/0xDEADC0DEx/stepper/actions/workflows/rust.yml/badge.svg)](https://github.com/0xDEADC0DEx/stepper/actions/workflows/rust.yml)

For most of the projects documentation have a look at the github wiki.

## Used tools
This project was written/created with the following utilities:
* Yosys (For synthesis)
* nextpnr (For routing and placing)
* prjtrellis (Bitstream documentation for the LATTICE LFE5U-12F)
* icarus verilog (Used for simulation)
* gtkwave (For opening the produced waveforms of the simulation as a vcd file)
* freecad (Used for 3d modeling)

## Project structure
#### Subfolders
* src -> Holds all the verilog src files that are synthesizeable.
* tests -> Consists of all verilog testbenches (for each model one with the naming convention `test_<name>.v`).
* designs -> Contains all of the 3d models of the project.
