import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

clk_divider = 2


async def start(dut):
    dut.data_in.value = 0
    dut.clk_count_max.value = clk_divider
    dut.serial_in.value = 0
    dut.send_enable_in.value = 0
    dut.cs_select_in.value = 0

    # 25 MHz clock
    clock = Clock(dut.clk_in, 40, units="ns")
    cocotb.fork(clock.start())

    print("Triggering reset")
    dut.reset_n_in.value = 0
    await ClockCycles(dut.clk_in, 2 * clk_divider, rising=True)

    dut.reset_n_in.value = 1
    await ClockCycles(dut.clk_in, 2 * clk_divider, rising=True)
    print("Reset done")


@cocotb.coroutine
async def sipo_data(dut, data):
    for i in range(40):
        dut.serial_in.value = (data & (0x1 << i)) >> i
        await RisingEdge(dut.clk_out)

    await RisingEdge(dut.r_ready_out)
    assert dut.data_out.value == data


@cocotb.coroutine
async def piso_data(dut, data, current_cs):
    dut.data_in.value = data

    # test io bit by bit
    for i in range(39, 0):
        await RisingEdge(dut.clk_out)

        assert dut.r_ready_out.value == 0
        assert dut.cs_out_n[i].value == 0

        # Check that every other cs bit is high
        for k in range(0, current_cs):
            assert dut.cs_out_n[k].value == 1

        for k in range(current_cs + 1, 4):
            assert dut.cs_out_n[k].value == 1

        # Check if the piso module works
        assert dut.data_in[i].value == dut.serial_out.value


@cocotb.test()
async def standard_ms_io(dut):
    await start(dut)

    test_data = [0x123456789A, 0xBCDEF12345, 0x6789ABCDEF, 0xDEADBEEF69]

    for i in range(4):
        cocotb.fork(sipo_data(dut, test_data[i]))
        cocotb.fork(piso_data(dut, test_data[i], i))
        dut.cs_select_in.value = i

        await ClockCycles(dut.clk_in, 1 * clk_divider, rising=True)

        assert dut.r_ready_out.value == 1
        assert dut.cs_out_n[i].value == 1
        dut.send_enable_in.value = 1

        # Wait for the spi module to finish
        await RisingEdge(dut.r_ready_out)

        dut.send_enable_in.value = 0
        await ClockCycles(dut.clk_in, 3 * clk_divider, rising=True)

    dut.send_enable_in.value = 1
    await ClockCycles(dut.clk_in, 100 * clk_divider, rising=True)
    assert dut.r_ready_out.value == 1
