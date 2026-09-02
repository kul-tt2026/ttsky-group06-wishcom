"""
test_hvsync.py -- hvsync_generator.v

640x480 @ 60 Hz: 800 klokken per lijn, 525 lijnen per beeld.  Als dit niet
klopt is er geen beeld, dus dit is de eerste test die je draait als de
monitor zwart blijft.

Wat hier getest wordt:
  1. reset: hpos = vpos = 0
  2. hsync laag op precies hpos 656..751 (96 klokken), hoog daarbuiten,
     hpos loopt 0..799 en wrapt, vpos telt een op per wrap
  3. vsync laag op precies vpos 490..491 (2 lijnen), vpos wrapt op 524
  4. display_on == (hpos < 640) && (vpos < 480), altijd
  5. een beeld is 525 * 800 = 420000 klokken

    make test_hvsync
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer

H_TOTAL, V_TOTAL = 800, 525
HS_LO, HS_HI = 656, 751          # inclusief
VS_LO, VS_HI = 490, 491


async def setup(dut):
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())
    dut.reset.value = 1
    await ClockCycles(dut.clk, 3)
    dut.reset.value = 0          # losgelaten TUSSEN twee flanken: hpos staat nog op 0
    await Timer(1, unit="ns")


def pos(dut):
    return int(dut.hpos.value), int(dut.vpos.value)


@cocotb.test()
async def test_reset(dut):
    await setup(dut)
    assert pos(dut) == (0, 0), f"na reset {pos(dut)}"


@cocotb.test()
async def test_hsync_and_line_length(dut):
    await setup(dut)
    prev_h = None
    lows = 0
    for _ in range(2 * H_TOTAL + 5):
        h, v = pos(dut)
        hs = int(dut.hsync.value)
        # hsync is een register: hij volgt hpos met een klok vertraging
        if prev_h is not None:
            exp = 0 if HS_LO <= prev_h <= HS_HI else 1
            assert hs == exp, f"hpos={prev_h}: hsync {hs}, verwacht {exp}"
            assert h == (prev_h + 1) % H_TOTAL, f"hpos sprong van {prev_h} naar {h}"
        assert int(dut.display_on.value) == int(h < 640 and v < 480), f"display_on op {h},{v}"
        lows += hs == 0
        prev_h = h
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")
    assert lows == 2 * 96, f"hsync {lows} klokken laag over 2 lijnen, verwacht 192"
    assert pos(dut)[1] == 2, "vpos moet na twee lijnen op 2 staan"


@cocotb.test()
async def test_vsync_and_frame_length(dut):
    await setup(dut)
    # spring naar het begin van lijn 489 en stap dan drie lijnen door
    await ClockCycles(dut.clk, 489 * H_TOTAL)
    await Timer(1, unit="ns")
    assert pos(dut) == (0, 489), f"verwacht (0,489), kreeg {pos(dut)}"
    prev_v, lows = None, 0
    for _ in range(3 * H_TOTAL + 1):
        h, v = pos(dut)
        vs = int(dut.vsync.value)
        if prev_v is not None:
            exp = 0 if VS_LO <= prev_v <= VS_HI else 1
            assert vs == exp, f"vpos={prev_v} hpos={h}: vsync {vs}, verwacht {exp}"
        assert int(dut.display_on.value) == 0, "display_on hoog in de verticale blanking"
        lows += vs == 0
        prev_v = v
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")
    assert lows == 2 * H_TOTAL, f"vsync {lows} klokken laag, verwacht {2 * H_TOTAL}"
    # naar het einde van het beeld: vpos wrapt van 524 naar 0
    h, v = pos(dut)
    await ClockCycles(dut.clk, (V_TOTAL - v) * H_TOTAL - h - 1)
    await Timer(1, unit="ns")
    assert pos(dut) == (H_TOTAL - 1, V_TOTAL - 1), f"laatste pixel: {pos(dut)}"
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert pos(dut) == (0, 0), f"na 525 lijnen niet terug op (0,0): {pos(dut)}"


@cocotb.test()
async def test_frame_is_420000_clocks(dut):
    await setup(dut)
    await ClockCycles(dut.clk, H_TOTAL * V_TOTAL)
    await Timer(1, unit="ns")
    assert pos(dut) == (0, 0), f"na 420000 klokken: {pos(dut)}"
    await ClockCycles(dut.clk, 1234)
    await Timer(1, unit="ns")
    assert pos(dut) == (1234 % H_TOTAL, 1234 // H_TOTAL)