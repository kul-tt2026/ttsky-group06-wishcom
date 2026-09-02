"""
test.py -- de hele chip (tt_um_dragonochi via tb.v)

Dit is de test die de Tiny Tapeout-CI draait (`make` in test/).  Hij
speelt het spel niet uit -- een intro alleen al is 139 beelden = 58 miljoen klokken -- maar
controleert wat een monitor en een speler als eerste merken:

  1. na reset staat de chip op TITLE, de pinnen zijn gedefinieerd, en de
     uio-pinnen zijn uitgang met de spelstatus erop (allemaal laag na reset)
  2. uo_out: bit 7 = hsync, bit 3 = vsync, en de kleurbits zijn 0 zolang
     de straal buiten het beeld staat (blanking MOET zwart zijn)
  3. binnen het beeld komt er echt kleur uit
  4. frame_tick komt precies een keer per beeld (420000 klokken, 16.8 ms)
     en een knop op ui_in doet iets: TITLE -> EGG binnen een paar beelden,
     en dat is ook op uio[2:0] te zien (de Pico leest daar de mode)

Reken op een paar minuten: tb.v dumpt elk signaal naar tb.fst en een beeld
is 420000 klokken.  Wil je het sneller, zet $dumpvars in tb.v uit.

    make
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.utils import get_sim_time

FRAME_CLKS = 800 * 525


async def setup(dut):
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)


@cocotb.test()
async def test_reset_state(dut):
    await setup(dut)
    top = dut.user_project
    assert int(top.u_home.mode.value) == 0, "na reset niet op TITLE"
    assert int(top.u_state.hearts.value) == 5
    assert int(top.u_state.level.value) == 1, "level moet op 1 beginnen"
    assert dut.uo_out.value.is_resolvable, "uo_out heeft X/Z na reset"
    assert dut.uio_out.value.is_resolvable, "uio_out heeft X/Z na reset"
    # uio = {overflow, evolve_now, fx_on, chest_state[1:0], mode[2:0]}: allemaal uitgang
    assert int(dut.uio_oe.value) == 0xFF, "uio-pinnen moeten uitgang zijn (spelstatus voor de Pico)"
    assert int(dut.uio_out.value) == 0, "na reset: TITLE, geen kist, geen effect, 0 munten, geen overflow"


@cocotb.test()
async def test_uo_out_mapping_and_blanking(dut):
    await setup(dut)
    top = dut.user_project
    colour_seen, blank_checked = 0, 0
    # een hele lijn plus een stuk: dekt hsync, front/back porch en actief beeld
    for _ in range(900):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")
        uo = int(dut.uo_out.value)
        assert (uo >> 7) & 1 == int(top.hsync.value), "uo_out[7] is niet hsync"
        assert (uo >> 3) & 1 == int(top.vsync.value), "uo_out[3] is niet vsync"
        colour = uo & 0b01110111
        if int(top.video_active.value) == 0:
            blank_checked += 1
            assert colour == 0, f"kleur {colour:08b} buiten het beeld (hpos={int(top.pix_x.value)})"
        elif colour:
            colour_seen += 1
    assert blank_checked > 100, "te weinig blanking gezien"
    assert colour_seen > 100, "geen kleur in het actieve beeld: staat de titel wel aan?"


@cocotb.test()
async def test_frame_tick_and_button(dut):
    """Vier beelden: de periode van frame_tick meten en ondertussen een knop
    indrukken.  (Een beeld is 420000 klokken; deze test is de langzaamste.)"""
    await setup(dut)
    top = dut.user_project
    ft = top.frame_tick
    await RisingEdge(ft)
    t0 = get_sim_time("ns")
    assert int(top.u_home.mode.value) == 0
    dut.ui_in.value = 1 << 4                 # FEED, maakt niet uit welke
    await RisingEdge(ft)
    clks = round((get_sim_time("ns") - t0) / 40)
    assert clks == FRAME_CLKS, f"frame_tick elke {clks} klokken, verwacht {FRAME_CLKS}"
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(ft.value) == 0, "frame_tick langer dan een klok hoog"
    for _ in range(2):
        await RisingEdge(ft)
    await ClockCycles(dut.clk, 2)
    dut.ui_in.value = 0
    assert int(top.u_home.mode.value) == 1, "knop op ui_in bracht de chip niet van TITLE naar EGG"
    assert int(dut.uio_out.value) & 0b111 == 1, "uio[2:0] volgt de mode niet"
    await RisingEdge(ft)
    assert int(top.u_home.egg_frame.value) != 0, "het ei barst niet"