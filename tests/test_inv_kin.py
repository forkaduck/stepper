import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_inv_kin(dut):
    dut.x_in = 10
    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    await ClockCycles(dut.clk_in, 5000, rising=True)
