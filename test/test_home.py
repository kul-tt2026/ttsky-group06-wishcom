"""
test_home.py -- home.v

De mode-machine en de prioriteitsketen. btn_pressed wordt hier direct
aangestuurd (alleen hoog tijdens een frame_tick, zoals buttons.v het doet).

Wat hier getest wordt:
  1. reset
  2. TITLE beweegt niet vanzelf; elke knop (ook een ongebruikte) start het spel
  3. de ei-intro loopt op FRAMES: na 30 ticks nog in EGG, in totaal 139 ticks,
     egg_frame 1..5, flash_r 16..768, en restart precies een frame hoog
     (regressietest voor de case die buiten het frame_tick-blok stond)
  4. in HOME geeft elke knop precies zijn eigen puls, een frame lang
  5. prioriteit: PLAY > EVOLVE > FEED > DRINK > SLEEP, ook alle vijf tegelijk
  6. fx_on legt de knoppen dood
  7. game_over en you_win gaan voor op knoppen
  8. CHEST negeert knoppen; minigame_done -> HOME; game_over -> GAMEOVER
  9. GAMEOVER en YOU_WIN: elke knop -> TITLE, ook als het niveau nog hoog staat,
     en de intro erna stuitert niet terug
 10. tussen twee ticks gebeurt er NIETS, ook niet met een knop ingedrukt

    make test_home
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer

TITLE, EGG, HOME, CHEST, GAMEOVER, YOU_WIN = range(6)
EVOLVE, FEED, DRINK, SLEEP, PLAY = 1 << 1, 1 << 4, 1 << 5, 1 << 6, 1 << 7
UNUSED0, UNUSED2, UNUSED3 = 1 << 0, 1 << 2, 1 << 3
ACTS = ("act_feed", "act_drink", "act_sleep", "act_minigame", "req_evolve", "restart")
INTRO_TICKS = 90 + 48 + 1     # egg_timer + flits (0..768 in stappen van 16) + overgang


async def setup(dut):
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())
    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    dut.btn_pressed.value = 0
    dut.game_over.value = 0
    dut.you_win.value = 0
    dut.minigame_done.value = 0
    dut.coins.value = 0
    dut.fx_on.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")


async def tick(dut, btn=0, minigame_done=0):
    dut.btn_pressed.value = btn
    dut.minigame_done.value = minigame_done
    dut.frame_tick.value = 1
    await RisingEdge(dut.clk)
    dut.btn_pressed.value = 0
    dut.minigame_done.value = 0
    dut.frame_tick.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")


async def ticks(dut, n):
    for _ in range(n):
        await tick(dut)


def mode(dut):
    return int(dut.mode.value)


def acts(dut):
    return {a: int(getattr(dut, a).value) for a in ACTS}


def only(dut, name):
    """Precies deze ene puls hoog, alle andere laag."""
    a = acts(dut)
    exp = {k: int(k == name) for k in ACTS}
    assert a == exp, f"verwacht alleen {name}: {a}"


def none(dut):
    a = acts(dut)
    assert not any(a.values()), f"er hoort geen puls te zijn: {a}"


async def run_intro(dut, btn=FEED):
    """Van TITLE naar HOME. Geeft het aantal ticks terug dat de intro duurde."""
    assert mode(dut) == TITLE
    await tick(dut, btn)
    assert mode(dut) == EGG
    n = 0
    while mode(dut) == EGG and n < 500:
        await tick(dut); n += 1
    assert mode(dut) == HOME, f"intro eindigde in mode {mode(dut)}"
    return n


# ---------------------------------------------------------------- tests ----
@cocotb.test()
async def test_reset(dut):
    await setup(dut)
    assert mode(dut) == TITLE
    assert int(dut.egg_frame.value) == 0
    assert int(dut.flash_r.value) == 0
    none(dut)


@cocotb.test()
async def test_title_waits_and_any_button_starts(dut):
    await setup(dut)
    await ticks(dut, 50)
    assert mode(dut) == TITLE, "TITLE mag niet vanzelf verder"
    none(dut)
    for btn in (UNUSED0, UNUSED2, UNUSED3, EVOLVE, FEED, DRINK, SLEEP, PLAY):
        await setup(dut)
        await tick(dut, btn)
        assert mode(dut) == EGG, f"knop {btn:#04x} startte het spel niet"
        none(dut)          # starten is geen actie en nog geen restart


@cocotb.test()
async def test_egg_intro_runs_on_frames(dut):
    """Regressie: de case moet BINNEN het frame_tick-blok staan."""
    await setup(dut)
    await tick(dut, FEED)
    assert mode(dut) == EGG

    frames_seen, flash_seen = [], []
    for _ in range(30):
        await tick(dut)
        frames_seen.append(int(dut.egg_frame.value))
    assert mode(dut) == EGG, "na 30 frames al uit EGG: de intro loopt op klokken"
    assert frames_seen == sorted(frames_seen), "egg_frame moet oplopen, niet springen"
    assert frames_seen[0] == 1 and 1 <= frames_seen[-1] <= 5

    n = 30
    while mode(dut) == EGG:
        await tick(dut); n += 1
        flash_seen.append(int(dut.flash_r.value))
        assert n < 500, "intro eindigt nooit"
    assert n == INTRO_TICKS, f"intro duurde {n} ticks, verwacht {INTRO_TICKS}"
    assert mode(dut) == HOME
    assert max(flash_seen) == 768, "flits moet tot 768 groeien"
    assert int(dut.flash_r.value) == 0, "flash_r moet weer 0 zijn in HOME"
    assert int(dut.egg_frame.value) == 0, "egg_frame is 0 buiten EGG"

    only(dut, "restart")               # de tick die HOME binnenging
    await tick(dut)
    none(dut)                          # en precies een frame later weer laag


@cocotb.test()
async def test_home_each_button_one_pulse(dut):
    await setup(dut)
    await run_intro(dut)
    for btn, act in ((FEED, "act_feed"), (DRINK, "act_drink"),
                     (SLEEP, "act_sleep"), (EVOLVE, "req_evolve")):
        await tick(dut, btn)
        only(dut, act)
        assert mode(dut) == HOME
        await tick(dut)
        none(dut)
    await tick(dut, PLAY)
    only(dut, "act_minigame")
    assert mode(dut) == CHEST


@cocotb.test()
async def test_priority_chain(dut):
    await setup(dut)
    await run_intro(dut)
    await tick(dut, EVOLVE | FEED | DRINK | SLEEP); only(dut, "req_evolve")
    await tick(dut, FEED | DRINK | SLEEP);          only(dut, "act_feed")
    await tick(dut, DRINK | SLEEP);                 only(dut, "act_drink")
    await tick(dut, SLEEP | UNUSED0 | UNUSED3);     only(dut, "act_sleep")
    assert mode(dut) == HOME
    await tick(dut, 0xFF);                          only(dut, "act_minigame")
    assert mode(dut) == CHEST


@cocotb.test()
async def test_fx_on_blocks_input(dut):
    await setup(dut)
    await run_intro(dut)
    dut.fx_on.value = 1
    for btn in (FEED, DRINK, SLEEP, EVOLVE, PLAY):
        await tick(dut, btn)
        none(dut)
        assert mode(dut) == HOME, "PLAY mag tijdens een effect niet naar CHEST"
    dut.fx_on.value = 0
    await tick(dut, FEED)
    only(dut, "act_feed")


@cocotb.test()
async def test_game_over_and_win_beat_buttons(dut):
    await setup(dut)
    await run_intro(dut)
    dut.game_over.value = 1
    await tick(dut, PLAY)
    assert mode(dut) == GAMEOVER
    none(dut)
    dut.game_over.value = 0

    await setup(dut)
    await run_intro(dut)
    dut.you_win.value = 1
    await tick(dut, FEED)
    assert mode(dut) == YOU_WIN
    none(dut)


@cocotb.test()
async def test_chest_mode(dut):
    await setup(dut)
    await run_intro(dut)
    await tick(dut, PLAY)
    assert mode(dut) == CHEST
    for btn in (FEED, DRINK, SLEEP, EVOLVE, PLAY, 0xFF):
        await tick(dut, btn)
        none(dut)
        assert mode(dut) == CHEST, "in CHEST kijkt home.v niet naar knoppen"
    await tick(dut, minigame_done=1)
    assert mode(dut) == HOME

    await tick(dut, PLAY)
    assert mode(dut) == CHEST
    dut.game_over.value = 1
    await tick(dut)
    assert mode(dut) == GAMEOVER, "dood in de kistenkamer moet naar GAMEOVER"


@cocotb.test()
async def test_end_screens_back_to_title_and_no_bounce(dut):
    """game_over blijft hoog tot restart; de intro mag daar niet op stuiteren."""
    await setup(dut)
    await run_intro(dut)
    dut.game_over.value = 1
    await tick(dut)
    assert mode(dut) == GAMEOVER
    await ticks(dut, 20)
    assert mode(dut) == GAMEOVER, "GAMEOVER wacht op een knop"
    await tick(dut, DRINK)
    assert mode(dut) == TITLE, "elke knop moet terug naar TITLE, ook met game_over hoog"

    # game_over staat NOG hoog (dragon_state wist pas op restart)
    n = await run_intro(dut, PLAY)
    assert n == INTRO_TICKS
    only(dut, "restart")
    dut.game_over.value = 0            # dragon_state heeft restart gezien
    await ticks(dut, 5)
    assert mode(dut) == HOME, "na de restart moet HOME blijven staan"

    dut.you_win.value = 1
    await tick(dut)
    assert mode(dut) == YOU_WIN
    await tick(dut, UNUSED2)
    assert mode(dut) == TITLE
    dut.you_win.value = 0


@cocotb.test()
async def test_nothing_moves_between_ticks(dut):
    """Registers bewegen alleen op frame_tick, ook met een knop ingedrukt."""
    await setup(dut)
    await run_intro(dut)
    await tick(dut)
    before = (mode(dut), acts(dut), int(dut.flash_r.value))
    dut.btn_pressed.value = FEED | PLAY       # zonder frame_tick
    await ClockCycles(dut.clk, 100)
    await Timer(1, unit="ns")
    dut.btn_pressed.value = 0
    assert (mode(dut), acts(dut), int(dut.flash_r.value)) == before, \
        "iets veranderde zonder frame_tick"