import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer

# ============================================================================
# HULPFUNCTIES
# ============================================================================

async def pulse_frame_tick(dut, frames=1):
    """Genereert N frame_ticks zonder acties (idle frames)."""
    for _ in range(frames):
        dut.frame_tick.value = 1
        await RisingEdge(dut.clk)
        dut.frame_tick.value = 0
        await RisingEdge(dut.clk)


async def execute_action(dut, act_type, sat_val=2):
    """Biedt 1 actie aan synchroon op de frame_tick."""
    dut.satisfaction.value = sat_val

    dut.act_feed.value = 1 if act_type == 'feed' else 0
    dut.act_drink.value = 1 if act_type == 'drink' else 0
    dut.act_sleep.value = 1 if act_type == 'sleep' else 0
    dut.act_minigame.value = 1 if act_type == 'minigame' else 0
    dut.frame_tick.value = 1

    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")

    result = {
        "sat_up": int(dut.req_sat_up.value),
        "sat_down": int(dut.req_sat_down.value),
        "heart_gain": int(dut.req_heart_gain.value),
        "heart_lose": int(dut.req_heart_lose.value),
        "combo_len": int(dut.combo_len.value),
    }

    dut.act_feed.value = 0
    dut.act_drink.value = 0
    dut.act_sleep.value = 0
    dut.act_minigame.value = 0
    dut.frame_tick.value = 0

    await RisingEdge(dut.clk)
    return result


async def setup_dut(dut):
    """Start de 25 MHz klok en initialiseert het circuit via reset."""
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())

    dut.rst_n.value = 0
    dut.restart.value = 0
    dut.frame_tick.value = 0
    dut.act_feed.value = 0
    dut.act_drink.value = 0
    dut.act_sleep.value = 0
    dut.act_minigame.value = 0
    dut.satisfaction.value = 2

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


# ============================================================================
# 1. COMBO OPBOUW & BALK (HAPPY PATH)
# ============================================================================

@cocotb.test()
async def test_combo_progress_bar_and_gain(dut):
    """Verifieert normale combo opbouw: 0 -> 1 -> 2 -> 3 en winst."""
    await setup_dut(dut)
    assert int(dut.combo_len.value) == 0

    # 1. Feed
    res = await execute_action(dut, 'feed', sat_val=3)
    assert res["combo_len"] == 0
    assert res["sat_up"] == 0 and res["heart_gain"] == 0

    # 2. Drink
    res = await execute_action(dut, 'drink', sat_val=3)
    assert res["combo_len"] == 1
    assert res["sat_up"] == 0 and res["heart_gain"] == 0

    # 3. Sleep
    res = await execute_action(dut, 'sleep', sat_val=3)
    assert res["combo_len"] == 2
    assert res["sat_up"] == 0 and res["heart_gain"] == 0

    # 4. Minigame -> Winst
    res = await execute_action(dut, 'minigame', sat_val=3)
    assert res["sat_up"] == 1
    assert res["heart_gain"] == 1
    assert res["combo_len"] == 3


@cocotb.test()
async def test_streak_reset_after_success(dut):
    """Verifieert dat actions_count reset naar 0 na succes."""
    await setup_dut(dut)

    for act in ['minigame', 'feed', 'drink']:
        await execute_action(dut, act, sat_val=3)
    res = await execute_action(dut, 'sleep', sat_val=3)
    assert res["sat_up"] == 1

    # 5e actie: Minigame -> Mag NIET opnieuw direct triggeren
    res = await execute_action(dut, 'minigame', sat_val=3)
    assert res["sat_up"] == 0
    assert res["heart_gain"] == 0


# ============================================================================
# 2. VERBROKEN COMBO'S & BALK GEDRAG
# ============================================================================

@cocotb.test()
async def test_broken_combo_behavior(dut):
    """
    Test wat er gebeurt als de speler een duplicaat indrukt:
    Feed -> Drink -> Feed -> Sleep (geen 4 uniek, balk past zich aan).
    """
    await setup_dut(dut)

    await execute_action(dut, 'feed')   # hist: [Feed] -> unique 1 -> combo_len 0
    await execute_action(dut, 'drink')  # hist: [Drink, Feed] -> unique 2 -> combo_len 1

    # Duplicaat: Feed opnieuw indrukken
    res = await execute_action(dut, 'feed')  # hist: [Feed, Drink, Feed] -> unique 2
    assert res["combo_len"] == 1, "Balk moet op 1 blijven (2 unieke acties in venster)"
    assert res["sat_up"] == 0

    # Sleep toevoegen: hist = [Sleep, Feed, Drink, Feed] -> niet 4 uniek!
    res = await execute_action(dut, 'sleep')
    assert res["sat_up"] == 0, "Mag GEEN combo triggeren want Feed zit er 2x in"
    assert res["combo_len"] == 2, "Balk moet 2/3 zijn (Sleep, Feed, Drink in laatste 3)"


@cocotb.test()
async def test_idle_frames_maintain_bar_state(dut):
    """Verifieert dat de combo balk niet leegloopt als de speler even niets doet."""
    await setup_dut(dut)

    await execute_action(dut, 'feed')
    await execute_action(dut, 'drink')
    assert int(dut.combo_len.value) == 1

    # 10 lege frames laten passeren
    await pulse_frame_tick(dut, 10)

    assert int(dut.combo_len.value) == 1, "Balk mag niet veranderen tijdens rustframes"
    assert int(dut.req_sat_up.value) == 0
    assert int(dut.req_sat_down.value) == 0


# ============================================================================
# 3. STRAFSCENARIO'S (6-STAPPEN LOGICA)
# ============================================================================

@cocotb.test()
async def test_penalty_alternating_missing_actions(dut):
    """
    Test straf bij afwisselende acties waar 2 acties ontbreken:
    Feed, Drink, Feed, Drink, Feed, Drink (6 stappen -> Straf!).
    """
    await setup_dut(dut)

    pattern = ['feed', 'drink', 'feed', 'drink', 'feed']
    for act in pattern:
        res = await execute_action(dut, act, sat_val=1)
        assert res["sat_down"] == 0, "Nog geen straf voor stap 6"

    # Stap 6: Drink (Minigame en Sleep ontbreken in de laatste 6)
    res = await execute_action(dut, 'drink', sat_val=1)
    assert res["sat_down"] == 1, "Straf moet vuren bij stap 6"
    assert res["heart_lose"] == 1, "Hartverlies bij sat=1"


@cocotb.test()
async def test_no_penalty_if_all_4_present_in_6_steps(dut):
    """
    Speler doet: Feed, Feed, Drink, Sleep, Minigame, Feed
    In de laatste 6 zitten alle 4 acties -> GEEN straf bij stap 6.
    """
    await setup_dut(dut)

    sequence = ['feed', 'feed', 'drink', 'sleep', 'minigame', 'feed']
    for idx, act in enumerate(sequence):
        res = await execute_action(dut, act, sat_val=2)
        if idx == 5:
            assert res["sat_down"] == 0, "Geen straf verwacht: alle 4 acties waren aanwezig!"


@cocotb.test()
async def test_penalty_recovery_reset(dut):
    """Verifieert dat de straf-reset de speler 6 nieuwe stappen geeft."""
    await setup_dut(dut)

    # 6x Feed -> Straf
    for _ in range(5):
        await execute_action(dut, 'feed', sat_val=2)
    res = await execute_action(dut, 'feed', sat_val=2)
    assert res["sat_down"] == 1

    # Stap 7: Drink -> Mag NIET meteen weer straf zijn
    res = await execute_action(dut, 'drink', sat_val=2)
    assert res["sat_down"] == 0, "Straf reset faalt: speler belandt in straflus"


# ============================================================================
# 4. SATISFACTION DREMPELWAARDEN
# ============================================================================

@cocotb.test()
async def test_heart_gain_all_satisfaction_levels(dut):
    """Test alle tevredenheidsniveaus bij combo (0 t/m 4)."""
    test_matrix = [
        (0, 0),  # sat=0 -> wel sat_up, geen heart_gain
        (1, 0),  # sat=1 -> wel sat_up, geen heart_gain
        (2, 1),  # sat=2 -> wel sat_up, WEL heart_gain
        (3, 1),  # sat=3 -> wel sat_up, WEL heart_gain
        (4, 1),  # sat=4 -> wel sat_up, WEL heart_gain
    ]

    for sat_val, exp_heart_gain in test_matrix:
        await setup_dut(dut)
        await execute_action(dut, 'minigame', sat_val=sat_val)
        await execute_action(dut, 'feed', sat_val=sat_val)
        await execute_action(dut, 'drink', sat_val=sat_val)
        res = await execute_action(dut, 'sleep', sat_val=sat_val)

        assert res["sat_up"] == 1
        assert res["heart_gain"] == exp_heart_gain


@cocotb.test()
async def test_heart_lose_all_satisfaction_levels(dut):
    """Test alle tevredenheidsniveaus bij straf (0 t/m 4)."""
    test_matrix = [
        (0, 1),  # sat=0 -> sat_down en heart_lose
        (1, 1),  # sat=1 -> sat_down en heart_lose
        (2, 1),  # sat=2 -> sat_down en heart_lose
        (3, 0),  # sat=3 -> wel sat_down, GEEN heart_lose
        (4, 0),  # sat=4 -> wel sat_down, GEEN heart_lose
    ]

    for sat_val, exp_heart_lose in test_matrix:
        await setup_dut(dut)
        for _ in range(5):
            await execute_action(dut, 'feed', sat_val=sat_val)
        res = await execute_action(dut, 'feed', sat_val=sat_val)

        assert res["sat_down"] == 1
        assert res["heart_lose"] == exp_heart_lose


# ============================================================================
# 5. HARDWARE & TIMING EDGE CASES
# ============================================================================

@cocotb.test()
async def test_button_priority_simultaneous_press(dut):
    """
    Test prioriteit bij gelijktijdig indrukken van Feed en Drink.
    Volgens de ternary cascade moet Feed (2'b01) winnen.
    """
    await setup_dut(dut)

    dut.act_feed.value = 1
    dut.act_drink.value = 1
    dut.frame_tick.value = 1

    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")

    dut.act_feed.value = 0
    dut.act_drink.value = 0
    dut.frame_tick.value = 0
    await RisingEdge(dut.clk)

    assert int(dut.hist_0.value) == 1, "Feed (1) had prioriteit moeten krijgen boven Drink"


@cocotb.test()
async def test_button_latching_between_ticks(dut):
    """Test dat een knopdruk tussen frames bewaard blijft via de latch."""
    await setup_dut(dut)

    dut.act_feed.value = 1
    await RisingEdge(dut.clk)
    dut.act_feed.value = 0
    await ClockCycles(dut.clk, 3)

    assert int(dut.act_latched.value) == 1, "Puls had gelatcht moeten worden"

    dut.frame_tick.value = 1
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    dut.frame_tick.value = 0

    assert int(dut.hist_0.value) == 1
    assert int(dut.actions_count.value) == 1


@cocotb.test()
async def test_pulse_duration_is_exactly_one_frame_tick(dut):
    """Verifieert dat de request-pulsen na 1 frame_tick vanzelf resetten."""
    await setup_dut(dut)

    await execute_action(dut, 'minigame', sat_val=3)
    await execute_action(dut, 'feed', sat_val=3)
    await execute_action(dut, 'drink', sat_val=3)
    res = await execute_action(dut, 'sleep', sat_val=3)

    assert res["sat_up"] == 1 and res["heart_gain"] == 1

    await pulse_frame_tick(dut, 1)
    await Timer(1, unit="ns")

    assert int(dut.req_sat_up.value) == 0, "req_sat_up moet na 1 frame weer 0 zijn"
    assert int(dut.req_heart_gain.value) == 0, "req_heart_gain moet na 1 frame weer 0 zijn"


@cocotb.test()
async def test_restart_clears_history(dut):
    """Verifieert dat het restart-signaal de module schoonveegt."""
    await setup_dut(dut)

    await execute_action(dut, 'minigame')
    await execute_action(dut, 'feed')
    await execute_action(dut, 'drink')

    dut.restart.value = 1
    await RisingEdge(dut.clk)
    dut.restart.value = 0
    await RisingEdge(dut.clk)

    assert int(dut.combo_len.value) == 0, "combo_len moet 0 zijn na restart"
    assert int(dut.actions_count.value) == 0