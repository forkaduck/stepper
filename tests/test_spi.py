import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_spi(dut):
    #  dut.data_in = 0xAAAAAAAAAA
    dut.data_in = 0x123456789A
    dut.clk_count_max = 2
    dut.serial_in = 0
    dut.send_enable_in = 0
    dut.cs_select_in = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    print("Triggering reset")
    dut.reset_n_in = 0
    await ClockCycles(dut.clk_in, 4, rising=True)

    dut.reset_n_in = 1
    await ClockCycles(dut.clk_in, 2, rising=True)
    print("Reset done")

    # Frame start
    assert dut.cs_out_n == 1

    dut.send_enable_in = 1
    await ClockCycles(dut.clk_in, 4, rising=True)

    assert dut.cs_out_n == 0

    print("Data start")
    # piso test
    for i in range(40):
        print(
            str(i)
            + ":"
            + str(dut.data_in.value[i])
            + " serial:"
            + str(int(dut.serial_out))
        )

        assert dut.clk_out == 1
        assert dut.data_in.value[i] == int(dut.serial_out)

        await ClockCycles(dut.clk_in, 2, rising=True)
