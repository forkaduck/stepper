import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_clk_divider(dut):
    dut.clk_in.value = 0
    dut.max_in.value = 100
    dut.r_clk_out.value = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    for _ in range(100):
        await RisingEdge(dut.clk_in)
        assert dut.r_clk_out.value == 0

    await RisingEdge(dut.clk_in)
    assert dut.r_clk_out.value == 1

    await RisingEdge(dut.clk_in)
    assert dut.r_clk_out.value == 0
