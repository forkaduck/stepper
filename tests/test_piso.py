import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def test_piso(dut):
    dut.data_in = int("10101100", 2)
    dut.clk_in = 0
    dut.reset_n_in = 1
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

    # test simple 8 bit data conversion
    for i in range(8):
        await RisingEdge(dut.clk_in)
        assert (int(dut.data_in) & (0x1 << 7 - i)) >> 7 - i == dut.r_data_out
