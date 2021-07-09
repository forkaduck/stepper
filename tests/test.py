#!/bin/python3

from cocotb_test.simulator import run


def test_clk_divider():
    run(
        verilog_sources=["../src/clk_divider.v"],  # sources
        toplevel="clk_divider",  # top level HDL
        module="test_clk_divider",  # name of cocotb test module
        toplevel_lang="verilog",
        waves=1,
    )
