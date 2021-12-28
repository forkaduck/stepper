import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_stepper(dut):
    dut.btn.value = 0
    dut.led.value = 0

    # 25 MHz clock
    clock = Clock(dut.clk_25mhz, 40, units="ns")
    cocotb.fork(clock.start())

    print("Triggering reset")
    dut.btn[1].value = 0
    await ClockCycles(dut.clk_25mhz, 10, rising=True)

    dut.btn[1].value = 1
    await ClockCycles(dut.clk_25mhz, 100, rising=True)

    dut.btn[1].value = 0
    print("Reset done")

    await ClockCycles(dut.clk_25mhz, 1500000, rising=True)
