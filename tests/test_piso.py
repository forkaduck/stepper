import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def test_piso(dut):
    dut.data_in = 0xAC
    dut.clk_in = 0
    dut.load_in = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    await RisingEdge(dut.clk_in)
    dut.load_in = 1
    await RisingEdge(dut.clk_in)
    dut.load_in = 0

    # test simple 8 bit data conversion
    for i in range(8):
        await RisingEdge(dut.clk_in)
        assert (int(dut.data_in.value) & (0x1 << i)) >> i == int(dut.data_out)
