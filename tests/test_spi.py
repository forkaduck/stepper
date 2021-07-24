import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

# Tests missing:
# sipo

clk_divider = 2


async def start(dut):
    dut.data_in = 0
    dut.clk_count_max = clk_divider
    dut.serial_in = 0
    dut.send_enable_in = 0
    dut.cs_select_in = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    print("Triggering reset")
    dut.reset_n_in = 0
    await ClockCycles(dut.clk_in, 2 * clk_divider, rising=True)

    dut.reset_n_in = 1
    await ClockCycles(dut.clk_in, clk_divider, rising=True)
    print("Reset done")


# 156374987060
# 00100100 01101000 10101100 11110001 00110100

# 78187493530
# 00010010 00110100 01010110 01111000 10011010


async def sipo_data(dut, data):
    for i in range(40):
        dut.serial_in = (data & (0x1 << i)) >> i
        await ClockCycles(dut.clk_in, clk_divider, rising=True)


@cocotb.test()
async def standard_ms_io(dut):
    await start(dut)

    test_data = [0x123456789A, 0xBCDEF12345, 0x6789ABCDEF, 0xDEADBEEF69]

    await RisingEdge(dut.r_ready_out)
    for i in range(4):
        # Setup parallel data out
        dut.data_in = test_data[i]
        cocotb.fork(sipo_data(dut, test_data[i]))

        assert int(dut.cs_out_n) == 1

        dut.send_enable_in = 1
        await ClockCycles(dut.clk_in, clk_divider, rising=True)

        # test io bit by bit
        for k in range(40):
            await ClockCycles(dut.clk_in, clk_divider, rising=True)

            assert int(dut.r_ready_out) == 0
            assert int(dut.cs_out_n.value) == 0

            assert int(dut.clk_out) == 1
            assert int(dut.data_in.value[k]) == int(dut.serial_out)

        # wait for the spi to be ready
        await RisingEdge(dut.r_ready_out)
        dut.send_enable_in = 0

        #  await ClockCycles(dut.clk_in, clk_divider, rising=True)
        assert int(dut.data_out.value) == int(test_data[i])

        await ClockCycles(dut.clk_in, clk_divider, rising=True)
