# run with "make -f Makefile.top_lvl", on first testrun or after changes to the code run "make -f Makefile.top_lvl clean"
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

# Knop definities (Komen overeen met jouw bit-posities op ui_in)
BTN_EVOLVE = 1
BTN_DOWN   = 3
BTN_FEED   = 4
BTN_DRINK  = 5
BTN_SLEEP  = 6
BTN_PLAY   = 7 # Wordt ook gebruikt als SELECT/BACK in menu's

# Modes in home.v (voor verificatie)
M_TITLE = 0
M_EGG   = 1
M_HOME  = 2
M_CHEST = 3

async def wait_for_frame(dut, frames=1):
    """
    In plaats van ZELF de frame_tick te maken, wachten we tot 
    de hvsync_generator in de chip hem genereert!
    """
    for _ in range(frames):
        await RisingEdge(dut.frame_tick)

async def press_physical_button(dut, btn_bit, frames_to_hold=2):
    """
    Simuleert een mens die een fysieke knop indrukt op ui_in.
    We houden hem een paar frames vast zodat buttons.v hem kan debouncen!
    """
    # Zet de specifieke bit hoog op de fysieke ingang
    dut.ui_in.value = (1 << btn_bit)
    
    # Wacht een paar frames zodat de debounce logica hem pakt
    await wait_for_frame(dut, frames_to_hold)
    
    # Laat de knop los
    dut.ui_in.value = 0
    await wait_for_frame(dut, 1)

@cocotb.test()
async def test_full_game_flow(dut):
    # 1. Start de VGA-klok (25 MHz = 40ns)
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())

    # 2. Hard Reset & Default pinnen
    dut.ena.value = 1       # Tiny Tapeout enable pin (heel belangrijk!)
    dut.ui_in.value = 0     # Geen knoppen ingedrukt
    dut.uio_in.value = 0    # Ongebruikt
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Chip opgestart, wachten op de eerste VGA frames...")

    # 3. Wacht tot de game is opgestart in M_TITLE
    await wait_for_frame(dut, 2)
    assert int(dut.u_home.mode.value) == M_TITLE, "Game startte niet in TITLE screen!"

    # 4. Druk op een knop om het EGG scherm te starten
    dut._log.info("Druk op start...")
    await press_physical_button(dut, BTN_PLAY)
    
    assert int(dut.u_home.mode.value) == M_EGG, "Niet naar EGG mode gegaan!"

    # 5. Het ei duurt 90 frames om uit te komen (volgens je home.v code)
    # We spoelen de tijd door!
    dut._log.info("Wachten tot het ei uitkomt (90 frames)... Dit kan even duren in de simulatie!")
    await wait_for_frame(dut, 95) 

    assert int(dut.u_home.mode.value) == M_HOME, "Ei is niet uitgekomen, of niet naar M_HOME gegaan!"

    # 6. We zijn in het home scherm. Laten we de minigame starten!
    dut._log.info("Druk op PLAY om naar de chest minigame te gaan...")
    await press_physical_button(dut, BTN_PLAY)

    # Verifieer dat de state-machine succesvol is doorgeschakeld
    assert int(dut.u_home.mode.value) == M_CHEST, "Niet naar minigame geschakeld!"
    
    # Check of de chest_game submodule daadwerkelijk 'active' is geworden!
    assert int(dut.u_chest_game.active.value) == 1, "Minigame kreeg het 'active' signaal niet!"

    dut._log.info("Integratietest geslaagd! Top-level signalen routen perfect.")