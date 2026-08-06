import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_lfsr(dut):
    dut._log.info("Start dual lfsr test")

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
    assert start_val == 2, f"Fout: Startwaarde moest 2 (3'b010) zijn, maar was {start_val}"