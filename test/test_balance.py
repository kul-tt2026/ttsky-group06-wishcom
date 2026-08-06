import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_balance(dut):
    dut._log.info("Start")

    # Start de klok op 25 MHz (40 ns periode)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Zet alle pinnen in een beginstand en houd de reset even actief (low)
    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    dut.restart.value = 0
    dut.act_feed.value = 0
    dut.act_drink.value = 0
    dut.act_sleep.value = 0
    dut.act_minigame.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1