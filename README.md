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
This project was written/created with the following utilities:
* Yosys (For synthesis)
* nextpnr (For routing and placing)
* prjtrellis (Bitstream documentation for the LATTICE LFE5U-12F)
* icarus verilog (Used for simulation)
* freecad (Used for 3d modeling)

#### Commands
Synthesize design and load into SRAM on the ULX3S:

`$ make clean && make prog`

Programm into flash:

`$ openFPGALoader -b ulx3s -v -f ulx3s.bit`

Simulate all designs:

`$ ./run_tests.sh`

## Project structure
#### Subfolders
* docs -> Contains most of the documentation either written per hand or generated.
* src -> Holds all the verilog src files that are synthesizeable.
* tests -> Consists of all verilog testbenches (for each model one with the naming convention `test_<name>.v`).
* designs -> Contains all of the 3d models of the project.

#### Branches && Branching
* master -> Is merged with develop if develop contains reasonably stable code.
* develop -> Contains the latest pull requests.
* dev -> Development branch used by 0xDEADC0DEx

A change in code or whatever is **commited** to your **personal branch** (dev for instance).
If you think that the feature you are working on is done then open a **pull-request** to **develop** on github.
The code is then checked by another member of the team. Feedback on improvements should be given via the github comments in the pull request.
If all team members are happy with the changes then those changes will be merged into the develop branch.

Only after some major improvements will the develop branch finally merged into the master branch.

## Coding conventions
* One module per file (file should have the same name as the module does).
* Split code in functional blocks with spaces.

#### Variable naming conventions
* Every input and output wire or reg of a module (except for the top module) should contain either `_in` or `_out` as a surfix.
* Every name of every reg should contain `r_` as a prefix if it is not a counter variable in a loop.
* Every reg or wire which is active low has to have `_n_` before a input output surfix (`_in/_out`) but before the real name.

###### Example:
`Register Output which is active low: r_<name>_n_out`

`Wire which is an input: <name>_in`
