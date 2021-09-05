#!/bin/python3
import argparse
import os
import subprocess
import sys

# Runs a subcommand with the appropriate pipes
# (a wrapper for use with tqdm)
def run_subcommand(args, env={}):
    # A simple hack to add new env variables
    # on top of the old ones
    for i, k in env.items():
        os.environ[i] = k

    rv = subprocess.run(args=args, check=True)

    print(rv.args)


# Removes generated files after build
def clean():
    try:
        os.remove("stepper.json")
        os.remove("ulx3s_out.config")
        os.remove("ulx3s.bit")

    except FileNotFoundError:
        print("Some files where already deleted or are missing!")


def compile_firmware():
    wd = os.getcwd()
    os.chdir("firmware")

    # Build the firmware
    run_subcommand(
        ["cargo", "build", "--release"],
    )

    # Strip the firmware of debug symbols
    run_subcommand(
        [
            "riscv32-elf-strip",
            "target/riscv32imac-unknown-none-elf/release/stepper",
        ],
    )

    # Copy sections to bin for use with rom initialisation
    run_subcommand(
        [
            "riscv32-elf-objcopy",
            "-O",
            "binary",
            "target/riscv32imac-unknown-none-elf/release/stepper",
            "target/riscv32imac-unknown-none-elf/release/stepper.bin",
        ],
    )

    # Format output to work with readmemh
    counter = 1
    with open(
        "target/riscv32imac-unknown-none-elf/release/stepper.mem", "w"
    ) as firm_out:
        with open(
            "target/riscv32imac-unknown-none-elf/release/stepper.bin", "rb"
        ) as firm_in:
            for i in firm_in.read():
                firm_out.write("{:02x}".format(i))

                if counter % 4 == 0:
                    firm_out.write("\n")

                counter += 1

            for i in range(5 - (counter % 4)):
                firm_out.write("00")

    os.chdir(wd)


# Builds the bitstream which can be loaded onto the FPGA
def build():
    compile_firmware()

    # Generate the intermediate netlist as a .json
    run_subcommand(
        [
            "yosys",
            "-p",
            "read_verilog src/*.v; synth_ecp5 -asyncprld -json stepper.json",
        ],
    )

    # Route the netlist in the specific FPGA
    run_subcommand(
        [
            "nextpnr-ecp5",
            "-v",
            "--25k",
            "--json",
            "stepper.json",
            "--lpf",
            "ulx3s_v20.lpf",
            "--textcfg",
            "ulx3s_out.config",
        ],
    )

    # Generates the bitstream using the packed netlist
    run_subcommand(
        [
            "ecppack",
            "-v",
            "ulx3s_out.config",
            "ulx3s.bit",
            "--idcode",
            "0x21111043",
        ],
    )


# Runs one test with the name test_name which is in the tests
# directory
def test(test_name):
    compile_firmware()

    wd = os.getcwd()
    os.chdir("tests")

    # Test commands are run inside the tests folder!!!
    src_dir = "../src/"
    output_dir = "sim_output/"

    # Generates a temporary hacky verilog file for simulation variables
    with open(output_dir + "iverilog_dump.v", "w", encoding="utf-8") as dump:
        dump.write(
            "`timescale 1ns / 100ps\n\n"
            + "module iverilog_dump();\n"
            + "initial begin\n"
            + '\t$dumpfile("'
            + output_dir
            + test_name
            + '.vcd");\n'
            + "\t$dumpvars();\n"
            + "end\n"
            + "endmodule\n"
        )

    # Gets together a list of source files
    print("Current source list:")
    with open(output_dir + "srclist.txt", "w", encoding="utf-8") as sources:
        sources.write(output_dir + "iverilog_dump.v\n")

        for i in os.listdir(src_dir):
            sources.write(src_dir + i + "\n")
            print(src_dir + i)

    # Uses iverilog to compile all of the source files
    # into an intermediate format
    run_subcommand(
        [
            "iverilog",
            "-o",
            output_dir + test_name + ".vvp",
            "-g",
            "2005",
            "-D",
            "COCOTB_SIM=1",
            "-s",
            test_name,
            "-s",
            "iverilog_dump",
            "-I",
            src_dir,
            "-v",
            "-f",
            output_dir + "srclist.txt",
        ],
    )

    # Run the compiled test
    run_subcommand(
        [
            "vvp",
            "-M",
            os.path.expanduser("~") + "/.local/lib/python3.9/site-packages/cocotb/libs",
            "-m",
            "libcocotbvpi_icarus",
            output_dir + test_name + ".vvp",
        ],
        env={
            "MODULE": "test_" + test_name,
            "TOPLEVEL": test_name,
            "TOPLEVEL_LANG": "verilog",
            "COCOTB_HDL_TIMEUNIT": "1ns",
            "COCOTB_HDL_TIMEPRECISION": "1ns",
        },
    )

    # Switch back to original working directory
    os.chdir(wd)


# Load the FPGA temporarily with the generated bitstream
def load():
    run_subcommand(
        [
            "openFPGALoader",
            "-b",
            "ulx3s",
            "-v",
            "-m",
            "ulx3s.bit",
        ],
    )


def flash():
    run_subcommand(
        [
            "openFPGALoader",
            "-b",
            "ulx3s",
            "-f",
            "-v",
            "-m",
            "ulx3s.bit",
        ],
    )


parser = argparse.ArgumentParser(description="Main makefile for the stepper project")
parser.add_argument(
    "--clean", help="Removes build output", dest="clean", action="store_true"
)
parser.add_argument(
    "--build", help="Build the hole project", dest="build", action="store_true"
)
parser.add_argument("--test", help="Run a test", dest="test", action="store")
parser.add_argument(
    "--load", help="Load the bitstream into SRAM", dest="load", action="store_true"
)
parser.add_argument(
    "--flash", help="Flash the bitstream into EEPROM", dest="flash", action="store_true"
)

prog_args = parser.parse_args()

if prog_args.clean:
    clean()

if prog_args.build:
    build()

if prog_args.test:
    test(prog_args.test)

if prog_args.load:
    load()

if prog_args.flash:
    flash()
