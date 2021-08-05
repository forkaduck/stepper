import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_motor_driver(dut):
    dut.serial_in = 0
    dut.step_enable_in = 0
    dut.speed_in.value = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    print("Triggering reset")
    dut.reset_n_in = 0
    await ClockCycles(dut.clk_in, 4, rising=True)

    dut.reset_n_in = 1
    await RisingEdge(dut.clk_in)
    print("Reset done")

    await ClockCycles(dut.clk_in, 3000, rising=True)
