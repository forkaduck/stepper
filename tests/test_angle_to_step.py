import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_angle_to_step(dut):
    dut.reset_n_i.value = 1
    dut.enable_i.value = 1
    dut.relative_angle_i.value = 10

    # 25 MHz clock
    clock = Clock(dut.clk_i, 40, units="ns")
    cocotb.fork(clock.start())

    await ClockCycles(dut.clk_i, 1000000, rising=True)
