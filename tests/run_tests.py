#!/sbin/python

import sys
import getopt
import os
import re
import subprocess

src_dir = "../src/"
output_dir = "sim_output/"

failed = 0
capture_output = True


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

    print("[*] Enumerating source files")
    sources = open("srclist.txt", "w")

    sources.write(output_dir + "iverilog_dump.v\n")

    for i in os.listdir(src_dir):
        sources.write(src_dir + i + "\n")

    sources.close()

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
            "-I",
            src_dir,
            "-v",
            "-f",
            "srclist.txt",
        ],
    )

    print("[*] subprocess returned " + str(rv.returncode))

    if rv.returncode != 0:
        exit(1)

    global capture_output

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
        capture_output=capture_output,
    )
    print("[*] subprocess returned " + str(rv.returncode))

    if rv.returncode != 0:
        exit(1)

    if rv.stdout is bytes:
        output = str(rv.stdout, encoding="UTF-8")
        print(output)

        if " FAIL " in output:
            global failed

            failed += 1


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
        "               -o <name>   // Run one test\n"
        "               -d          // Get the output of the simulation unbuffered\n"
        "                           // (The script can't check for a failed simulation inside an automated job but the output looks nicer)"
    )


def handleargs():
    run_one = False
    run_all = False

    try:
        args, vals = getopt.getopt(
            sys.argv[1:], "dhao:", ["help", "rall", "rone", "direct"]
        )

        for currargs, currvals in args:
            if currargs in ("-h", "--help"):
                printhelp()
                exit(0)

            elif currargs in ("-a", "--rall"):
                run_all = True

            elif currargs in ("-o", "--rone"):
                run_one = True
                test_name = currvals

            elif currargs in ("-d", "--direct"):
                global capture_output

                capture_output = False

    except getopt.error as err:
        print(str(err))

    if run_one:
        delold()
        runtest(test_name)
        exit(failed)

    elif run_all:
        delold()
        runalltests()
        exit(failed)


try:
    os.mkdir(output_dir, mode=0o755)
except FileExistsError:
    print("[*] Output directory exists")
handleargs()
