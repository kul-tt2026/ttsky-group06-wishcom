import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer

async def setup_dut(dut):
    """Start de klok en reset het circuit."""
    clock = Clock(dut.clk, 40, unit="ns")  # 25 MHz klok
    cocotb.start_soon(clock.start())

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


async def execute_action(dut, act_type, sat_val=2):
    """
    Voert 1 actie uit op frame_tick en leest de uitgangen uit
    zodra de registers na de klokflank stabiel zijn (1 ns marge).
    """
    dut.satisfaction.value = sat_val

    # 1. Actie aanbieden op frame_tick
    dut.act_feed.value = 1 if act_type == 'feed' else 0
    dut.act_drink.value = 1 if act_type == 'drink' else 0
    dut.act_sleep.value = 1 if act_type == 'sleep' else 0
    dut.act_minigame.value = 1 if act_type == 'minigame' else 0
    dut.frame_tick.value = 1

    # 2. Klokflank afwachten
    await RisingEdge(dut.clk)
    # Geef het register 1 ns om stabiel te worden
    await Timer(1, unit="ns")

    # 3. Nu stabiel uitlezen
    result = {
        "sat_up": int(dut.req_sat_up.value),
        "sat_down": int(dut.req_sat_down.value),
        "heart_gain": int(dut.req_heart_gain.value),
        "heart_lose": int(dut.req_heart_lose.value),
        "combo_len": int(dut.combo_len.value),
    }

    # 4. Inputs opruimen voor de volgende cyclus
    dut.act_feed.value = 0
    dut.act_drink.value = 0
    dut.act_sleep.value = 0
    dut.act_minigame.value = 0
    dut.frame_tick.value = 0

    await RisingEdge(dut.clk)
    return result


@cocotb.test()
async def test_gain_heart_and_sat_up(dut):
    """Verifieert dat 4 unieke acties op rij direct leiden tot humeur- en hartjeswinst."""
    await setup_dut(dut)

    # Actie 1: MINIGAME
    res = await execute_action(dut, 'minigame', sat_val=3)
    assert res["sat_up"] == 0 and res["heart_gain"] == 0

    # Actie 2: FEED
    res = await execute_action(dut, 'feed', sat_val=3)
    assert res["sat_up"] == 0 and res["heart_gain"] == 0

    # Actie 3: DRINK
    res = await execute_action(dut, 'drink', sat_val=3)
    assert res["sat_up"] == 0 and res["heart_gain"] == 0

    # Actie 4: SLEEP (4e unieke actie: pulsen slaan aan!)
    res = await execute_action(dut, 'sleep', sat_val=3)
    assert res["sat_up"] == 1, "Expected req_sat_up on 4th unique action"
    assert res["heart_gain"] == 1, "Expected req_heart_gain on 4th unique action with sat=3"


@cocotb.test()
async def test_lose_heart_and_sat_down(dut):
    """Verifieert dat bij 6 monotone acties direct op stap 6 een daling en hartverlies volgt."""
    await setup_dut(dut)

    # Voer 5x FEED uit
    for step in range(5):
        res = await execute_action(dut, 'feed', sat_val=2)
        assert res["sat_down"] == 0, f"Unexpected sat_down at step {step+1}"
        assert res["heart_lose"] == 0, f"Unexpected heart_lose at step {step+1}"

    # Actie 6: FEED (6e actie monotoon)
    res = await execute_action(dut, 'feed', sat_val=2)
    assert res["sat_down"] == 1, "Expected req_sat_down on 6th monotonous action"
    assert res["heart_lose"] == 1, "Expected req_heart_lose at sat=2"


@cocotb.test()
async def test_satisfaction_thresholds(dut):
    """Test de drempelwaarden van satisfaction voor het wel/niet toekennen van hartjes."""
    await setup_dut(dut)

    # 1. 4 unieke acties bij lage tevredenheid (sat = 1) -> Wel humeur omhoog, GEEN extra hartje
    actions = ['minigame', 'feed', 'drink', 'sleep']
    for act in actions[:3]:
        await execute_action(dut, act, sat_val=1)
    res = await execute_action(dut, actions[3], sat_val=1)

    assert res["sat_up"] == 1, "req_sat_up should fire"
    assert res["heart_gain"] == 0, "No heart gain expected when sat is 1"

    # Reset voor volgend scenario
    dut.restart.value = 1
    await ClockCycles(dut.clk, 2)
    dut.restart.value = 0
    await ClockCycles(dut.clk, 2)

    # 2. 6 dezelfde acties bij hoge tevredenheid (sat = 4) -> Wel humeur omlaag, GEEN hartverlies
    for _ in range(5):
        await execute_action(dut, 'drink', sat_val=4)
    res = await execute_action(dut, 'drink', sat_val=4)

    assert res["sat_down"] == 1, "req_sat_down should fire"
    assert res["heart_lose"] == 0, "No heart lose expected when sat is 4"


@cocotb.test()
async def test_restart_clears_history(dut):
    """Verifieert dat het restart-signaal de tellers en registers reset."""
    await setup_dut(dut)

    # Voer 3 acties uit
    await execute_action(dut, 'minigame')
    await execute_action(dut, 'feed')
    await execute_action(dut, 'drink')

    # Trigger restart
    dut.restart.value = 1
    await RisingEdge(dut.clk)
    dut.restart.value = 0
    await RisingEdge(dut.clk)

    # Controleer of combo_len direct terug op 0 staat
    assert int(dut.combo_len.value) == 0, "combo_len should reset to 0 after restart"