#!/bin/python3
import argparse
import os
import subprocess
import sys
from tqdm import tqdm
import logging


def run_subcommand(command, env={}):
    rv = subprocess.run(command, stdout=subprocess.PIPE, env=env)

    tqdm.write(rv.stdout.decode("utf-8"))
    tqdm.write("Subprocess returned " + str(rv.returncode))

    if rv.returncode != 0:
        sys.exit(1)


def clean():
    try:
        os.remove("stepper.json")
        os.remove("ulx3s_out.config")
        os.remove("ulx3s.bit")

    except FileNotFoundError:
        tqdm.write("Some files where already deleted!")


def build():
    with tqdm(total=3, file=sys.stdout) as pbar:
        pr = 0

        pbar.set_description("Running synthesis")
        run_subcommand(
            [
                "yosys",
                "-p",
                "read_verilog src/*.v; synth_ecp5 -noccu2 -nomux -nodram -json stepper.json",
            ],
        )
        pbar.update(pr)
        pr += 1

        pbar.set_description("Routing")
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
        pbar.update(pr)
        pr += 1

        pbar.set_description("Packing")
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
        pbar.update(pr)
        pr += 1

        pbar.set_description("Done")


def test(test_name):
    src_dir = "src/"
    output_dir = "tests/sim_output/"

    with tqdm(total=4, file=sys.stdout) as pbar:
        pr = 0

        # Generates a temporary hacky verilog file for simulation variables
        pbar.set_description("Preparing iverilog_dump.v")
        with open(output_dir + "iverilog_dump.v", "w", encoding="utf-8") as dump:
            dump.write(
                "`timescale 1ns / 100ps\n\n"
                + "module iverilog_dump();\n"
                + "initial begin\n"
                + '\t$dumpfile("'
                + output_dir
                + test_name
                + '.vcd");\n'
                + "\t$dumpvars(0, "
                + test_name
                + ");\n"
                + "end\n"
                + "endmodule\n"
            )

        pbar.update(pr)
        pr += 1

        # Gets together a list of source files
        pbar.set_description("Enumerating source files")
        tqdm.write("Source list:")
        with open(output_dir + "srclist.txt", "w", encoding="utf-8") as sources:
            sources.write(output_dir + "iverilog_dump.v\n")

            for i in os.listdir(src_dir):
                sources.write(src_dir + i + "\n")
                tqdm.write(src_dir + i)

        pbar.update(pr)
        pr += 1

        # Uses iverilog to compile all of the source files into an intermediate format
        pbar.set_description("Compiling python test to vpp file")
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

        pbar.update(pr)
        pr += 1

        # Run the compiled test
        pbar.set_description("Running test")
        run_subcommand(
            [
                "vvp",
                "-M",
                "/home/fuckaduck/.local/lib/python3.9/site-packages/cocotb/libs",
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
        pbar.update(pr)
        pr += 1


def prog():
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


parser = argparse.ArgumentParser(description="Main makefile for the stepper project")
parser.add_argument(
    "--clean", help="Removes build output", dest="clean", action="store_true"
)
parser.add_argument(
    "--build", help="Build the hole project", dest="build", action="store_true"
)
parser.add_argument("--test", help="Build and run a test", dest="test", action="store")
parser.add_argument(
    "--prog", help="Build and program the FPGA", dest="prog", action="store_true"
)

args = parser.parse_args()

if args.clean:
    clean()

if args.build:
    build()

if args.test:
    test(args.test)

if args.prog:
    prog()
