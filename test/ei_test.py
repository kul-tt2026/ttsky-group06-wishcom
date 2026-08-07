# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

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
# # Hulpfunctie: Vertaal de 6-bit Verilog kleuren (RR_GG_BB) naar (255, 255, 255)
# def hex_to_rgb(verilog_6bit):
#     # Splits het 6-bit getal op in rood, groen en blauw (elk 2 bits)
#     r_bits = (verilog_6bit >> 4) & 0b11
#     g_bits = (verilog_6bit >> 2) & 0b11
#     b_bits = (verilog_6bit >> 0) & 0b11

#     # Schaal de 0-3 waarde naar 0-255 (0, 85, 170, 255)
#     r = r_bits * 85
#     g = g_bits * 85
#     b = b_bits * 85
#     return (r, g, b)

# @cocotb.test()
# async def render_module_frame(dut):
#     dut._log.info("Start render test voor de sprite module")

#     WIDTH, HEIGHT = 640, 480
#     img = Image.new('RGB', (WIDTH, HEIGHT), "black")
#     pixels = img.load()

#     dut.level.value = 1         
#     dut.mood_anim.value = 0     
#     dut.bob.value = 0           

#     # ==========================================================
#     # PALET: Kopieer hier exact de 6'b... codes uit renderer.v
#     # Gebruik '0b' in plaats van '6'b' voor Python binaire getallen
#     # ==========================================================
#     palette = {
#         0: hex_to_rgb(0b000000), # Transparant / Zwart
#         1: hex_to_rgb(0b111111), # Code 1: Wit (6'b111111)
#         2: hex_to_rgb(0b011001), # Code 2: Dragon body green (6'b011001)
#         3: hex_to_rgb(0b110000), # Code 3: Rood (6'b110000)
#     }

#     dut._log.info(f"Genereren van {WIDTH}x{HEIGHT} afbeelding. Dit kan even duren...")

#     # Loop over alle pixels van het scherm
#     for y in range(HEIGHT):
#         dut.y.value = y
#         for x in range(WIDTH):
#             dut.x.value = x

#             await Timer(1, unit="ns")

#             on_str = str(dut.px_on.value).lower()
#             code_str = str(dut.px_code.value).lower()

#             if 'x' in on_str or 'z' in on_str or 'x' in code_str or 'z' in code_str:
#                 continue
                
#             px_on = int(dut.px_on.value)
#             px_code = int(dut.px_code.value)

#             if px_on:
#                 # Gebruik roze (255, 105, 180) als waarschuwing voor een onbekende code
#                 color = palette.get(px_code, (255, 105, 180))
#                 pixels[x, y] = color
#             else:
#                 pixels[x, y] = (30, 30, 30) # Donkergrijze achtergrond

#     # Sla het frame op
#     filename = "module_render.png"
#     img.save(filename)
#     dut._log.info(f"Test afgerond! Afbeelding is opgeslagen als {filename}")