# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start top-level simulatie voor tt_um_dragonchi")

    # Start een 10 MHz klok op dut.clk (periode van 100 ns)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Pas een reset toe
    dut._log.info("Systeem resetten...")
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Reset vrijgegeven")

    # Wacht 100 klokcycles om te zien of de interne signaalverwerking werkt
    await ClockCycles(dut.clk, 100)

    dut._log.info("Top-level test succesvol afgerond!")