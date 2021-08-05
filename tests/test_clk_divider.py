import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def test_clk_divider(dut):
    dut.clk_in = 0
    dut.max_in = 100
    dut.clk_out = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    for i in range(100):
        await RisingEdge(dut.clk_in)
        assert int(dut.clk_out) == 0

    await RisingEdge(dut.clk_in)
    assert int(dut.clk_out) == 1

    await RisingEdge(dut.clk_in)
    assert int(dut.clk_out) == 0
