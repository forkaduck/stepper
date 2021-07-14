import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def test_sipo(dut):
    dut.data_in = 0
    dut.reset_n_in = 0
    dut.r_data_out = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    print("Triggering reset")
    dut.reset_n_in = 0
    for i in range(4):
        await RisingEdge(dut.clk_in)

    dut.reset_n_in = 1
    await RisingEdge(dut.clk_in)
    print("Reset done")

    test_data = 0xABCD

    for i in range(8):
        dut.data_in = (test_data & (0x1 << i)) >> i
        await RisingEdge(dut.clk_in)

    dut.data_in = 0
    await RisingEdge(dut.clk_in)
    assert int(dut.r_data_out) == test_data & 0xFF

    for i in range(8, 16):
        dut.data_in = (test_data & (0x1 << i)) >> i
        await RisingEdge(dut.clk_in)

    dut.data_in = 0
    await RisingEdge(dut.clk_in)
    assert int(dut.r_data_out) == (test_data & 0xFF00) >> 8
