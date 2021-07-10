#!/bin/python3

import os
import re
import subprocess

cwd = os.path.dirname(os.path.abspath(__file__))
src_dir = cwd + "/../src/"
output_dir = cwd + "/sim_output/"


def delold():
    print("[*] Deleting old simulation files")

    for i in os.listdir(cwd):
        vvp = re.search("\.vvp$", i)
        vcd = re.search("\.vcd$", i)

        if vvp is not None or vcd is not None:
            os.remove(cwd + "/" + i)


# /sbin/iverilog -o sim_build/sim.vvp -D COCOTB_SIM=1 -s piso -f sim_build/cmds.f -g2012  -f sim_build/cmds.f -g2012   ../src/piso.v
#  MODULE=test_piso TESTCASE= TOPLEVEL=piso TOPLEVEL_LANG=verilog \
#          /sbin/vvp -M /home/fuckaduck/.local/lib/python3.9/site-packages/cocotb/libs -m libcocotbvpi_icarus   sim_build/sim.vvp
def runtest(test):
    try:
        os.mkdir(output_dir, mode=0o755)
    except FileExistsError:
        print("[*] Output directory exists")

    print("[*] Compiling python tests to vpp file")

    rv = subprocess.run([
        "iverilog",
        "-o",
        output_dir + test + ".vvp",
        "-g2005",
        "-D",
        "COCOTB_SIM=1",
        "-s",
        test,
        src_dir + test + ".v",
    ])

    print("[*] Subprocess returned " + str(rv.returncode))

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
            "TOPLEVEL_LANG": "verilog"
        },
    )

    print("[*] Subprocess returned " + str(rv.returncode))


def runalltests():
    for i in os.listdir(cwd):
        if re.search("\.py$", i) is not None and i != "run_tests.py":
            print("[*] Running " + i)
            runtest(i[len("test_"):].split(".")[0])


delold()
runalltests()
