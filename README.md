# Stepper
A test design for use with a hexapedal or octapedal robot.

## Current prototype pinout
Pinout of the Radiona ulx3s:
#### Stepper Driver 1
* gp[0] = Step
* gp[1] = Dir
* gn[0] = SDO
* gn[1] = CS
* gn[2] = SCK
* gn[3] = SDI


## Programming
This project was written with the following utilities:
* Yosys (for synthesis)
* nextpnr (for routing and placing)
* prjtrellis (bitstream documentation for the LATTICE LFE5U-12F)
* icarus verilog (used for simulation)

#### Commands
Synthesize design and load into SRAM on the ULX3S:

`$ make clean && make prog`

Programm into flash:

`$ openFPGALoader -b ulx3s -v -f ulx3s.bit`

Simulation of all designs:

`$ ./run_tests.sh`

## Project structure
#### Subfolders
* docs -> contains most of the documentation either written per hand or generated
* src -> holds all the verilog src files that are synthesizeable
* tests -> consists of all verilog testbenches (for each model one with the naming convention `test_<name>.v`)

## Coding conventions
* One module per file (file should have the same name as the module does).
* Split code in functional blocks with spaces.

#### Variable naming conventions
* Every input and output wire or reg of a module (except for the top module) should contain either `_in` or `_out` as a surfix.
* Every name of every reg should contain `r_` as a prefix.
* Every reg or wire which is active low has to have `_n_` before a input output surfix (`_in/_out`) but before the real name.

###### Example:
`Register Output which is active low: r_<name>_n_out`

`Wire which is an input: <name>_in`
