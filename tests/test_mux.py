import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def test_mux(dut):
    dut.select_in.value = 0
    dut.sig_in.value = 0

    for i in range(4):
        dut.r_sig_out[i].value = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    await RisingEdge(dut.clk_in)
    for i in range(4):
        dut.select_in.value = i
        dut.sig_in.value = 0

        for k in range(2):
            await RisingEdge(dut.clk_in)

        assert dut.r_sig_out[i].value == 0

        dut.sig_in.value = 1

        for k in range(2):
            await RisingEdge(dut.clk_in)

        assert dut.r_sig_out[i].value == 1
