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

    print("Triggering reset")
    dut.reset_n_i.value = 1
    await ClockCycles(dut.clk_i, 10, rising=True)

    dut.reset_n_i.value = 0
    await ClockCycles(dut.clk_i, 100, rising=True)

    dut.reset_n_i.value = 1
    print("Reset done")

    await ClockCycles(dut.clk_i, 200000, rising=True)
