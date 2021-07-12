#!/sbin/python

import sys
import getopt
import os
import re
import subprocess

src_dir = "../src/"
output_dir = "sim_output/"


def delold():
    print("[*] Deleting old simulation files")

    for i in os.listdir(output_dir):
        vvp = re.search("\.vvp$", i)
        vcd = re.search("\.vcd$", i)

        if vvp is not None or vcd is not None:
            os.remove(output_dir + i)


def runtest(test):
    print("[*] Preparing iverilog_dump.v")
    dump = open(output_dir + "iverilog_dump.v", "w")

    dump.write(
        "`timescale 1ns / 100ps\n\n"
        + "module iverilog_dump();\n"
        + "initial begin\n"
        + '\t$dumpfile("'
        + output_dir
        + test
        + '.vcd");\n'
        + "\t$dumpvars(0, "
        + test
        + ");\n"
        + "end\n"
        + "endmodule\n"
    )

    dump.close()

    print("[*] Compiling python tests to vpp file")

    rv = subprocess.run(
        [
            "iverilog",
            "-o",
            output_dir + test + ".vvp",
            "-g",
            "2005",
            "-D",
            "COCOTB_SIM=1",
            "-s",
            test,
            "-s",
            "iverilog_dump",
            src_dir + test + ".v",
            output_dir + "iverilog_dump.v",
        ],
    )

    print(rv)

    if rv.returncode != 0:
        exit()

    rv = subprocess.run(
        [
            "vvp",
            "-M",
            "/home/fuckaduck/.local/lib/python3.9/site-packages/cocotb/libs",
            "-m",
            "libcocotbvpi_icarus",
            output_dir + test + ".vvp",
        ],
        env={
            "MODULE": "test_" + test,
            "TOPLEVEL": test,
            "TOPLEVEL_LANG": "verilog",
            "COCOTB_HDL_TIMEUNIT": "1ns",
            "COCOTB_HDL_TIMEPRECISION": "1ns",
        },
    )

    print(rv)

    if rv.returncode != 0:
        exit()


def runalltests():
    for i in os.listdir("."):
        if re.search("\.py$", i) is not None and i != "run_tests.py":
            print("[*] Running " + i)
            runtest(i[len("test_") :].split(".")[0])


def printhelp():
    print(
        "Simulation runner help:\n\n" + sys.argv[0] + " [-hao]\n"
        "               -h          // print this help\n"
        "               -a          // Run all tests\n"
        "               -o <name>   // Run one test"
    )


def handleargs():
    try:
        args, vals = getopt.getopt(sys.argv[1:], "hao:", ["help", "rall", "rone"])

        for currargs, currvals in args:
            if currargs in ("-h", "--help"):
                printhelp()

            elif currargs in ("-a", "--rall"):
                delold()
                runalltests()

            elif currargs in ("-o", "--rone"):
                delold()
                runtest(currvals)

    except getopt.error as err:
        print(str(err))


try:
    os.mkdir(output_dir, mode=0o755)
except FileExistsError:
    print("[*] Output directory exists")
handleargs()
