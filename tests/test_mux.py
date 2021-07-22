import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def test_mux(dut):
    dut.select_in = 0
    dut.sig_in = 0

    for i in range(4):
        dut.r_sig_out.value[i] = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    await RisingEdge(dut.clk_in)
    for i in range(4):
        dut.select_in = i
        dut.sig_in = 0

        for k in range(2):
            await RisingEdge(dut.clk_in)

        assert (int(dut.r_sig_out.value) & (0x1 << i)) >> i == 0

        dut.sig_in = 1

        for k in range(2):
            await RisingEdge(dut.clk_in)

        # There is a bug where cocotb doesn't refresh
        # the value of a single bit. BinaryValue will probably
        # be replaced in the future. This bug persists only with registers
        # not wires
        # assert dut.r_sig_out.value[i] == 1
        assert (int(dut.r_sig_out.value) & (0x1 << i)) >> i == 1
