"""
test_anim.py -- anim.v

Alle tijdsafhankelijke beeldtoestand: idle-wip, dag/nacht, voer- en
drinkeffect, de evolve-reeks en de knipperende evolve-knop.

Wat hier getest wordt:
  1. reset
  2. level_shown volgt level, en is na een restart NOOIT 0 (level 0 bestaat
     niet; dragon_draw tekent dan de volwassen draak -- zie de docstring daar)
  3. de wip per satisfaction, exact tegen een Python-model, twee cycli lang;
     amplitude 0/4/8/12/16; sat=0 staat stil; van sat wisselen landt netjes
  4. voeren: fx_on meteen hoog, 74 ticks lang (1 wachten + 73), fx_age 0..72
  5. drinken: 31 ticks (1 + 30)
  6. de draak LANDT eerst: fx_kind blijft 0 zolang dragon_bob != 0
  7. de wip staat stil tijdens een effect en tijdens een evolve
  8. knop vasthouden = een effect; nog eens drukken tijdens het effect = niets;
     drinken terwijl voeren wacht = voeren wint
  9. restart wist effect, nacht, evolve en wip
 10. nacht: sleep aan, wake uit, allebei tegelijk = wake wint
 11. evolve-reeks exact tegen een model: 72 ticks, flits tot 176 px, de vorm
     wisselt op het hoogtepunt, de knipper 8 aan / 8 uit in de eerste 48
 12. evolve terwijl de draak in de lucht hangt + voeren tijdens de evolve:
     geen deadlock, het effect start zodra hij geland is
 13. evolve_blink: 170 aan, 10 uit, periode 180

    make test_anim
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer

FX_NONE, FX_FEED, FX_DRINK = 0, 1, 2
FEED_LEN, DRINK_LEN = 73, 30
EVO_BLINK, EVO_STEP = 48, 11
EVO_PEAK, EVO_SWITCH, EVO_LEN = EVO_BLINK + EVO_STEP + 1, EVO_BLINK + EVO_STEP, EVO_BLINK + 2 * EVO_STEP + 2
CYCLE = {0: 0, 1: 150, 2: 90, 3: 60, 4: 56}
BOB_TABLE = {
    1: [(3, 0), (6, 2), (14, 4), (17, 1)],
    2: [(3, 0), (6, 3), (9, 6), (18, 8), (21, 3)],
    3: [(3, 0), (6, 4), (9, 8), (19, 12), (22, 6), (24, 2)],
    4: [(3, 0), (6, 5), (9, 11), (21, 16), (24, 8), (26, 3)],
}
AMPLITUDE = {0: 0, 1: 4, 2: 8, 3: 12, 4: 16}


# ---------------------------------------------------------------- model ----
def bob_of(sat, t):
    for lim, v in BOB_TABLE.get(sat, []):
        if t < lim:
            return v
    return 0


def evo_r_of(evo_t):
    if evo_t == 0:
        return 0
    age = EVO_LEN - evo_t
    if age < EVO_BLINK:
        return 0
    grow = age - EVO_BLINK
    fade = EVO_LEN - 1 - age
    step = min(grow if age < EVO_PEAK else fade, EVO_STEP)
    return step * 16


class EvoModel:
    def __init__(self, level_shown):
        self.evo_t, self.ls, self.flash = 0, level_shown, 0

    def tick(self, evolved, level):
        age = EVO_LEN - self.evo_t
        on = self.evo_t != 0
        new_t = self.evo_t - 1 if on else (EVO_LEN if evolved else 0)
        self.flash = int(on and age < EVO_BLINK and (age >> 3) & 1)
        if evolved:
            pass
        elif not on:
            self.ls = level
        elif age >= EVO_SWITCH:
            self.ls = level
        self.evo_t = new_t

    @property
    def evo_on(self):
        return int(self.evo_t != 0)

    @property
    def evo_r(self):
        return evo_r_of(self.evo_t)


# -------------------------------------------------------------- helpers ----
PULSES = ("act_feed", "act_drink", "act_sleep", "wake", "evolved")


async def setup(dut, sat=0, level=1):
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())
    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    dut.restart.value = 0
    dut.satisfaction.value = sat
    dut.level.value = level
    for p in PULSES:
        getattr(dut, p).value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")


async def tick(dut, feed=0, drink=0, sleep=0, wake=0, evolved=0, hold=False):
    """Een frame_tick. Met hold=True blijven de pulsen erna hoog staan."""
    dut.act_feed.value = feed
    dut.act_drink.value = drink
    dut.act_sleep.value = sleep
    dut.wake.value = wake
    dut.evolved.value = evolved
    dut.frame_tick.value = 1
    await RisingEdge(dut.clk)
    if not hold:
        for p in PULSES:
            getattr(dut, p).value = 0
    dut.frame_tick.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")


async def ticks(dut, n):
    for _ in range(n):
        await tick(dut)


async def restart(dut):
    dut.restart.value = 1
    await RisingEdge(dut.clk)
    dut.restart.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")


def bob(dut):      return int(dut.dragon_bob.value)
def fx_on(dut):    return int(dut.fx_on.value)
def fx_kind(dut):  return int(dut.fx_kind.value)
def fx_age(dut):   return int(dut.fx_age.value)
def evo_on(dut):   return int(dut.evo_on.value)
def evo_r(dut):    return int(dut.evo_r.value)
def shown(dut):    return int(dut.level_shown.value)


async def run_effect(dut, **press):
    """Druk, en tel hoe lang fx_on hoog blijft. Geeft (ticks, ages, kinds)."""
    await tick(dut, **press)
    n, ages, kinds = 0, [], []
    while fx_on(dut):
        kinds.append(fx_kind(dut))
        if fx_kind(dut) != FX_NONE:
            ages.append(fx_age(dut))
        await tick(dut)
        n += 1
        assert n < 400, "effect eindigt nooit"
    return n, ages, kinds          # n = aantal ticks waarop fx_on hoog stond


# ---------------------------------------------------------------- tests ----
@cocotb.test()
async def test_reset(dut):
    await setup(dut, sat=4)
    assert int(dut.night.value) == 0
    assert bob(dut) == 0
    assert fx_on(dut) == 0 and fx_kind(dut) == FX_NONE
    assert evo_on(dut) == 0 and evo_r(dut) == 0
    assert int(dut.flash.value) == 0
    assert int(dut.evolve_blink.value) == 1


@cocotb.test()
async def test_level_shown_follows_level(dut):
    await setup(dut, level=3)
    await tick(dut)
    assert shown(dut) == 3
    dut.level.value = 5
    await tick(dut)
    assert shown(dut) == 5


@cocotb.test()
async def test_level_shown_never_zero_after_restart(dut):
    """
    Level 0 bestaat niet: dragon_draw valt dan door naar de VOLWASSEN draak.
    restart wordt gepulst op het frame waarop HOME verschijnt, dus als
    level_shown naar 0 reset ziet de speler twee frames lang de eindvorm
    voordat de baby verschijnt.

    Faalt deze test, verander dan in anim.v:
        if (!rst_n || restart)  level_shown <= 3'd0;
    in
        if (!rst_n || restart)  level_shown <= 3'd1;
    """
    await setup(dut, level=1)
    assert shown(dut) != 0, "level_shown is 0 direct na reset"
    await tick(dut)
    await restart(dut)
    assert shown(dut) != 0, "level_shown is 0 direct na restart (voor de eerste tick)"


@cocotb.test()
async def test_bob_matches_model_all_satisfactions(dut):
    for sat in (1, 2, 3, 4):
        await setup(dut, sat=sat)
        timer, seen = 0, []
        for _ in range(2 * CYCLE[sat] + 5):
            exp = bob_of(sat, timer)
            timer = 0 if timer >= CYCLE[sat] - 1 else timer + 1
            await tick(dut)
            assert bob(dut) == exp, f"sat={sat} timer={timer}: bob {bob(dut)} != {exp}"
            seen.append(bob(dut))
        assert max(seen) == AMPLITUDE[sat], f"sat={sat}: amplitude {max(seen)}"
        assert 0 in seen, "de draak moet elke cyclus landen"


@cocotb.test()
async def test_bob_still_when_angry_and_lands_on_change(dut):
    await setup(dut, sat=0)
    await ticks(dut, 200)
    assert bob(dut) == 0, "sat=0 mag nooit wippen"

    await setup(dut, sat=4)
    await ticks(dut, 12)                 # midden in de sprong
    assert bob(dut) == 16
    dut.satisfaction.value = 0
    await tick(dut)
    assert bob(dut) == 0, "op sat=0 moet hij meteen op de grond staan"


@cocotb.test()
async def test_feed_length_and_age(dut):
    await setup(dut, sat=0)
    n, ages, kinds = await run_effect(dut, feed=1)
    assert n == FEED_LEN + 1, f"fx_on {n} ticks, verwacht {FEED_LEN + 1} (1 wachten + 73)"
    assert kinds[0] == FX_NONE, "eerste tick is 'wachten': kind nog 0"
    assert kinds[1:] == [FX_FEED] * FEED_LEN
    assert ages == list(range(FEED_LEN)), "fx_age moet 0..72 lopen, elke waarde een keer"
    assert fx_on(dut) == 0
    await tick(dut)
    assert fx_kind(dut) == FX_NONE


@cocotb.test()
async def test_drink_length(dut):
    await setup(dut, sat=0)
    n, ages, kinds = await run_effect(dut, drink=1)
    assert n == DRINK_LEN + 1
    assert kinds[1:] == [FX_DRINK] * DRINK_LEN
    assert ages == list(range(DRINK_LEN))


@cocotb.test()
async def test_dragon_lands_before_effect(dut):
    await setup(dut, sat=4)
    await ticks(dut, 12)
    assert bob(dut) == 16, "we willen de draak in de lucht"
    await tick(dut, feed=1)
    assert fx_on(dut) == 1, "fx_on moet meteen hoog: home.v moet de knoppen doodleggen"
    waited = 0
    while fx_kind(dut) == FX_NONE:
        pre = bob(dut)
        await tick(dut)
        waited += 1
        if fx_kind(dut) != FX_NONE:
            assert pre == 0, f"effect startte terwijl de draak op {pre} px hing"
        else:
            assert pre != 0, "draak stond op de grond maar het effect startte niet"
        assert waited < 60
    assert 5 < waited < 40, f"wachten op de landing duurde {waited} ticks"
    # tijdens het effect: geen wip
    frozen = bob(dut)
    for _ in range(FEED_LEN - 1):
        await tick(dut)
        assert bob(dut) == frozen == 0, "de wip moet stilstaan tijdens het effect"
    await ticks(dut, 2)
    assert fx_on(dut) == 0
    # de timer stond stil op het landingsmoment en loopt van daar verder:
    # binnen een cyclus moet hij weer springen
    n = 0
    while bob(dut) == 0:
        await tick(dut); n += 1
        assert n <= CYCLE[4], "na het effect moet de wip weer lopen"


@cocotb.test()
async def test_hold_spam_and_first_request_wins(dut):
    # vasthouden: een effect
    await setup(dut, sat=0)
    await tick(dut, feed=1, hold=True)
    starts, prev = 0, fx_on(dut)       # het eerste effect loopt al
    for _ in range(200):
        await tick(dut, feed=1, hold=True)
        if fx_on(dut) and not prev:
            starts += 1
        prev = fx_on(dut)
    assert starts == 0 and prev == 0, "200 frames vasthouden mag maar een effect geven"
    await tick(dut)

    # nog eens drukken tijdens het effect: niets
    await setup(dut, sat=0)
    await tick(dut, feed=1)
    await ticks(dut, 10)
    await tick(dut, feed=1)
    n = 0
    while fx_on(dut):
        await tick(dut); n += 1
    assert n == FEED_LEN - 10, f"tweede druk verlengde het effect ({n})"

    # drinken terwijl voeren wacht: voeren wint
    await setup(dut, sat=4)
    await ticks(dut, 12)
    await tick(dut, feed=1)
    await tick(dut, drink=1)
    while fx_kind(dut) == FX_NONE:
        await tick(dut)
    assert fx_kind(dut) == FX_FEED, "het eerste verzoek hoort te winnen"


@cocotb.test()
async def test_restart_clears_everything(dut):
    await setup(dut, sat=4, level=2)
    await tick(dut, sleep=1)
    await ticks(dut, 12)
    await tick(dut, feed=1)
    await ticks(dut, 3)
    dut.level.value = 3
    await tick(dut, evolved=1)
    await ticks(dut, 5)
    assert int(dut.night.value) == 1 and fx_on(dut) == 1 and evo_on(dut) == 1

    dut.level.value = 1
    await restart(dut)
    assert int(dut.night.value) == 0
    assert fx_on(dut) == 0 and fx_kind(dut) == FX_NONE
    assert evo_on(dut) == 0 and evo_r(dut) == 0 and int(dut.flash.value) == 0
    assert bob(dut) == 0
    await tick(dut)
    assert shown(dut) == 1


@cocotb.test()
async def test_night(dut):
    await setup(dut)
    await tick(dut, sleep=1); assert int(dut.night.value) == 1
    await ticks(dut, 50);     assert int(dut.night.value) == 1
    await tick(dut, wake=1);  assert int(dut.night.value) == 0
    await tick(dut, sleep=1, wake=1)
    assert int(dut.night.value) == 0, "wake gaat voor op sleep"
    await tick(dut, sleep=1); assert int(dut.night.value) == 1


@cocotb.test()
async def test_evolve_sequence_matches_model(dut):
    await setup(dut, sat=4, level=1)
    await tick(dut)
    m = EvoModel(level_shown=1)
    # de tick van `evolved`: dragon_state heeft level nog NIET omgezet
    m.tick(1, 1)
    await tick(dut, evolved=1)
    dut.level.value = 2
    assert shown(dut) == 1 and evo_on(dut) == 1
    frozen = bob(dut)

    on_ticks, r_max, switch_at, flash_hist = 0, 0, None, []
    for i in range(EVO_LEN + 5):
        m.tick(0, 2)
        await tick(dut)
        assert evo_on(dut) == m.evo_on, f"tick {i}: evo_on"
        assert evo_r(dut) == m.evo_r, f"tick {i}: evo_r {evo_r(dut)} != {m.evo_r}"
        assert shown(dut) == m.ls, f"tick {i}: level_shown {shown(dut)} != {m.ls}"
        assert int(dut.flash.value) == m.flash, f"tick {i}: flash"
        if evo_on(dut):
            on_ticks += 1
            assert bob(dut) == frozen, "de wip moet stilstaan tijdens de evolve"
        r_max = max(r_max, evo_r(dut))
        flash_hist.append(int(dut.flash.value))
        if switch_at is None and shown(dut) == 2:
            switch_at = i
    assert on_ticks == EVO_LEN - 1, f"evo_on {on_ticks + 1} ticks in totaal, verwacht {EVO_LEN}"
    assert r_max == EVO_STEP * 16, f"flits piekt op {r_max}, verwacht {EVO_STEP * 16}"
    assert switch_at is not None and EVO_BLINK < switch_at < EVO_LEN, \
        f"vorm wisselde op tick {switch_at}"
    assert sum(flash_hist) == 24, f"knipper {sum(flash_hist)} ticks aan, verwacht 3 x 8"
    assert shown(dut) == 2 and evo_on(dut) == 0 and evo_r(dut) == 0


@cocotb.test()
async def test_evolve_midair_then_feed_no_deadlock(dut):
    await setup(dut, sat=4, level=1)
    await ticks(dut, 12)
    assert bob(dut) == 16
    await tick(dut, evolved=1)
    dut.level.value = 2
    await ticks(dut, 10)
    assert evo_on(dut) == 1 and bob(dut) == 16, "bevroren in de lucht tijdens de evolve"
    await tick(dut, feed=1)
    assert fx_on(dut) == 1 and fx_kind(dut) == FX_NONE, "voeren wacht op de landing"
    n = 0
    while fx_kind(dut) == FX_NONE:
        await tick(dut); n += 1
        assert n < EVO_LEN + CYCLE[4], "voeren start nooit: deadlock"
    assert evo_on(dut) == 0, "het effect mag pas na de evolve starten"
    assert bob(dut) == 0


@cocotb.test()
async def test_evolve_blink_period(dut):
    await setup(dut)
    hist = []
    for _ in range(360):
        await tick(dut)
        hist.append(int(dut.evolve_blink.value))
    assert hist[:180] == hist[180:], "periode moet 180 ticks zijn"
    assert hist[:180].count(0) == 10, f"{hist[:180].count(0)} ticks uit per periode, verwacht 10"
    assert hist[:180].count(1) == 170