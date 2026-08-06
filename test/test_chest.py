import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_chest_logic(dut):
    dut._log.info("Start chest logic test")

    # Start de klok op 25 MHz (40 ns periode)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Zet alle pinnen in een beginstand en houd de reset even actief (low)
    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    dut.active.value = 1       # Zet de game direct aan
    dut.btn_pressed.value = 0
    
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1