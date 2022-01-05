import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ClockCycles


@cocotb.test()
async def test_angle_to_step(dut):
    dut.enable_i.value = 0
    #  dut.relative_angle_i.value = 0b00011001100110011010000000000000
    dut.relative_angle_i.value = 0b00001000000000000000000000000000

    # 25 MHz clock
    clock = Clock(dut.clk_i, 40, units="ns")
    cocotb.fork(clock.start())

    # Run first cycle
    await ClockCycles(dut.clk_i, 10, rising=True)
    dut.enable_i.value = 1

    await ClockCycles(dut.clk_i, 800000, rising=True)

    # Reset
    dut.enable_i.value = 0
    await FallingEdge(dut.done_o)

    dut.enable_i.value = 1
    dut.relative_angle_i.value = 0b00000100000000000000000000000000
    await RisingEdge(dut.done_o)
