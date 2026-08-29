import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_init(dut):
    dut._log.info("Start init test")

    # Start de klok op 25 MHz (40 ns periode)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Zet alle pinnen in een beginstand en houd de reset even actief (low)
    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # startwaarde
    start_val = int(dut.rand_val.value)
    assert start_val == 2, f"Got {start_val}, expected 2 (3'b010)"


@cocotb.test()
async def test_one_tick(dut):
    dut._log.info("Start 1 tick test")

    # Start de klok op 25 MHz (40 ns periode)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Zet alle pinnen in een beginstand en houd de reset even actief (low)
    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # geef 1 tick
    dut.frame_tick.value = 1
    await RisingEdge(dut.clk)
    dut.frame_tick.value = 0
    await RisingEdge(dut.clk)

    new_val = int(dut.rand_val.value)
    assert new_val == 4, f"Got {new_val}, expected 4"

@cocotb.test()
async def test_bounds(dut):
    dut._log.info("Start long run boundaries (0 - 7) test")

    # Start de klok op 25 MHz (40 ns periode)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    for i in range(100):
        # Geef een frame tick
        dut.frame_tick.value = 1
        await RisingEdge(dut.clk)
        dut.frame_tick.value = 0
        await RisingEdge(dut.clk)
        
        # Check grenzen
        huidig = int(dut.rand_val.value)
        assert 0 <= huidig <= 7, f"LFSR generarated out-of-bounds output: {huidig}"

@cocotb.test()
async def test_non_zero(dut):
    dut._log.info("Start long run boundaries (0 - 7) test")

    # Start de klok op 25 MHz (40 ns periode)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    for i in range(100):
        # Geef een frame tick
        dut.frame_tick.value = 1
        await RisingEdge(dut.clk)
        dut.frame_tick.value = 0
        await RisingEdge(dut.clk)
        
        # Check grenzen
        lfsr_a = int(dut.lfsr_a.value)
        lfsr_b = int(dut.lfsr_b.value)
        assert lfsr_a != 0, f"lfsr_a is zero: {huidig}"
        assert lfsr_a != 0, f"lfsr_b is zero: {huidig}"
        