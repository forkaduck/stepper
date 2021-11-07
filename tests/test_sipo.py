import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def test_sipo(dut):
    dut.data_in.value = 0
    dut.r_data_out.value = 0
    dut.en_in.value = 1

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    test_data = 0xABCD

    for i in range(7, -1, -1):
        dut.data_in.value = (test_data & (0x1 << i)) >> i
        await RisingEdge(dut.clk_in)

    await RisingEdge(dut.clk_in)
    assert dut.r_data_out.value == test_data & 0xFF

    for i in range(15, 8, -1):
        dut.data_in.value = (test_data & (0x1 << i)) >> i
        await RisingEdge(dut.clk_in)

    await RisingEdge(dut.clk_in)
    await RisingEdge(dut.clk_in)
    assert dut.r_data_out.value == (test_data & 0xFF00) >> 8
