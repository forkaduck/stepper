import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_inv_kin(dut):
    dut.x_in.value = 0x0000000a00000000
    dut.y_in.value = 0x0000000a00000000
    dut.z_in.value = 0x0000000a00000000

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    await ClockCycles(dut.clk_in, 5000, rising=True)
