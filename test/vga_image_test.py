# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

# import cocotb
# from cocotb.clock import Clock
# from cocotb.triggers import ClockCycles


# @cocotb.test()
# async def test_project(dut):
#     pass
    # dut._log.info("Start")

    # # Set the clock period to 10 us (100 KHz)
    # clock = Clock(dut.clk, 10, unit="us")
    # cocotb.start_soon(clock.start())

    # # Reset
    # dut._log.info("Reset")
    # dut.ena.value = 1
    # dut.ui_in.value = 0
    # dut.uio_in.value = 0
    # dut.rst_n.value = 0
    # await ClockCycles(dut.clk, 10)
    # dut.rst_n.value = 1

    # dut._log.info("Test project behavior")

    # # Set the input values you want to test
    # dut.ui_in.value = 20
    # dut.uio_in.value = 30

    # # Wait for one clock cycle to see the output values
    # await ClockCycles(dut.clk, 1)

    # # The following assersion is just an example of how to check the output values.
    # # Change it to match the actual expected output of your module:
    # assert dut.uo_out.value == 50

    # # Keep testing the module by changing the input values, waiting for
    # # one or more clock cycles, and asserting the expected output values.


# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from PIL import Image

# @cocotb.test()
# async def render_vga_frame(dut):
#     dut._log.info("Start VGA render test")

#     # Start de klok op 25 MHz (40 ns periode)
#     clock = Clock(dut.clk, 40, unit="ns")
#     cocotb.start_soon(clock.start())

#     # Zet alle pinnen in een beginstand en houd de reset even actief (low)
#     dut.rst_n.value = 0
#     await ClockCycles(dut.clk, 5)
#     dut.rst_n.value = 1
    
#     # Maak een lege zwarte afbeelding van 640x480 pixels (de VGA resolutie)
#     WIDTH, HEIGHT = 640, 480
#     img = Image.new('RGB', (WIDTH, HEIGHT), "black")
#     pixels = img.load()

#     # Vaste waarden vanuit de hvsync_generator
#     H_MAX = 800  # 640 + 48 + 16 + 96
#     V_MAX = 525  # 480 + 33 + 10 + 2

#     # We houden zelf de x en y posities bij, synchroon aan de hardware
#     hpos = 0
#     vpos = 0

#     dut._log.info("Simuleren van 1 compleet VGA-frame. Dit kan even duren...")

#     # Een heel frame duurt 800 * 525 = 420.000 kloktikken
#     for _ in range(H_MAX * V_MAX):
#         await RisingEdge(dut.clk)

#         # Controleer of de output niet "onbekend" (X) of "zwevend" (Z) is
#         if 'x' in dut.uo_out.value.binstr or 'z' in dut.uo_out.value.binstr:
#             hpos += 1
#             if hpos == H_MAX:
#                 hpos = 0
#                 vpos += 1
#             continue

#         # Lees de 8-bit output uit als een geheel getal
#         uo_val = int(dut.uo_out.value)

#         # Filter de bits eruit op basis van jouw assign statement:
#         # uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]}
#         # Bits:     7      6     5     4      3      2     1     0
#         r1 = (uo_val >> 0) & 1
#         g1 = (uo_val >> 1) & 1
#         b1 = (uo_val >> 2) & 1
#         r0 = (uo_val >> 4) & 1
#         g0 = (uo_val >> 5) & 1
#         b0 = (uo_val >> 6) & 1

#         # Combineer de bits tot 2-bit waardes per kleurkanaal (0 t/m 3)
#         r_val = (r1 << 1) | r0
#         g_val = (g1 << 1) | g0
#         b_val = (b1 << 1) | b0

#         # Schaal de 0-3 waarde op naar een 0-255 waarde voor de afbeelding
#         # (0 -> 0, 1 -> 85, 2 -> 170, 3 -> 255)
#         r_color = r_val * 85
#         g_color = g_val * 85
#         b_color = b_val * 85

#         # Teken de pixel als we ons binnen het zichtbare deel van het scherm (640x480) bevinden
#         if hpos < WIDTH and vpos < HEIGHT:
#             pixels[hpos, vpos] = (r_color, g_color, b_color)

#         # Update de pixelcoördinaten voor de volgende kloktik
#         hpos += 1
#         if hpos == H_MAX:
#             hpos = 0
#             vpos += 1

#     # Sla het uiteindelijke frame op
#     filename = "vga_frame.png"
#     img.save(filename)
#     dut._log.info(f"Test afgerond! Afbeelding is opgeslagen als {filename}")