import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

async def execute_action(dut, act_type):
    """
    Voert 1 actie uit op frame_tick en leest de pulsen uit nadat de RTL
    de status op de klokflank heeft verwerkt.
    """
    # 1. Inputs instellen voor deze frame_tick
    dut.act_feed.value = 1 if act_type == 'feed' else 0
    dut.act_drink.value = 1 if act_type == 'drink' else 0
    dut.act_sleep.value = 1 if act_type == 'sleep' else 0
    dut.act_minigame.value = 1 if act_type == 'minigame' else 0
    dut.frame_tick.value = 1

    # 2. Wacht op de klokflank waarop de RTL-module de logica verwerkt
    await RisingEdge(dut.clk)
    
    # 3. Reset de sturingssignalen
    dut.act_feed.value = 0
    dut.act_drink.value = 0
    dut.act_sleep.value = 0
    dut.act_minigame.value = 0
    dut.frame_tick.value = 0

    # 4. Wacht 1 extra klokcyclus zodat de RTL-registers hun nieuwe status laten zien
    await RisingEdge(dut.clk)
    
    # Nu pas de getriggerde pulsen veilig uitlezen
    lost = int(dut.req_heart_lose.value)
    gained = int(dut.req_heart_gain.value)
    
    return lost, gained

@cocotb.test()
async def test_lose1(dut):
    """Test of exact 1 hartje verloren gaat bij 6 monotone acties"""
    dut._log.info("Start test_lose1")

    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    dut.restart.value = 0
    dut.act_feed.value = 0
    dut.act_drink.value = 0
    dut.act_sleep.value = 0
    dut.act_minigame.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    total_lost_pulses = 0

    # Acties 1-4: FEED
    for _ in range(4):
        lost, _ = await execute_action(dut, 'feed')
        total_lost_pulses += lost

    # Acties 5-6: DRINK
    for _ in range(2):
        lost, _ = await execute_action(dut, 'drink')
        total_lost_pulses += lost

    satisfaction = int(dut.satisfaction.value)

    assert satisfaction == 2, f"Got satisfaction {satisfaction}, expected 2"
    assert total_lost_pulses == 1, f"Expected 1 lose pulse, got {total_lost_pulses}"


@cocotb.test()
async def test_lose2(dut):
    """Test of exact 2 hartjes verloren gaan bij 7 monotone acties"""
    dut._log.info("Start test_lose2")

    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    dut.restart.value = 0
    dut.act_feed.value = 0
    dut.act_drink.value = 0
    dut.act_sleep.value = 0
    dut.act_minigame.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    total_lost_pulses = 0

    # Acties 1-4: FEED
    for _ in range(4):
        lost, _ = await execute_action(dut, 'feed')
        total_lost_pulses += lost

    # Acties 5-6: DRINK (1e daling)
    for _ in range(2):
        lost, _ = await execute_action(dut, 'drink')
        total_lost_pulses += lost

    # Actie 7: DRINK (2e daling)
    lost, _ = await execute_action(dut, 'drink')
    total_lost_pulses += lost

    satisfaction = int(dut.satisfaction.value)

    assert satisfaction == 1, f"Got satisfaction {satisfaction}, expected 1"
    assert total_lost_pulses == 2, f"Expected 2 lose pulses, got {total_lost_pulses}"