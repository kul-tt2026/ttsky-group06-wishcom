import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

# Constanten (komen overeen met je Verilog localparams)
C_PICK, C_OPEN, C_RESULT, C_MENU = 0, 1, 2, 3
O_COIN, O_2X, O_CURSED, O_BOMB, O_BOMB2 = 0, 1, 2, 3, 4

# Knoppen bits (btn_pressed)
BTN_UP   = 1
BTN_DOWN  = 3
BTN_SELECT = 6
BTN_BACK  = 7

async def pulse_frame_tick(dut, frames=1):
    """Hulpfunctie om N frame_ticks te genereren"""
    for _ in range(frames):
        dut.frame_tick.value = 1
        await RisingEdge(dut.clk)
        dut.frame_tick.value = 0
        await RisingEdge(dut.clk)

@cocotb.test()
async def test_chest_game_win_and_cashout(dut):
    # 1. Start de klok
    cocotb.start_soon(Clock(dut.clk, 40, units="ns").start())

    # 2. Reset de chip
    dut.active.value = 0
    dut.btn_pressed.value = 0
    dut.frame_tick.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # 3. Activeer de minigame
    dut.active.value = 1
    
    # KANSER: Geef de chip 1 frame_tick om de kisten te schudden (dealt = 1 maken)
    await pulse_frame_tick(dut, 1)
    
    assert int(dut.chest_state.value) == C_PICK, "State is niet C_PICK na activatie"

    # 4. SPIEKEN: Waar zit de munt?
    doel_kist = 0
    for i in range(3):
        if int(dut.contents[i].value) == O_COIN:
            doel_kist = i
            break

    # 5. Navigeer de cursor naar de juiste kist
    huidige_sel = int(dut.chest_sel.value)
    while huidige_sel < doel_kist:
        # Druk op RECHTS (btn 5 -> bitmask 1 << 5 = 32, of 1 << BTN_DOWN)
        dut.btn_pressed.value = (1 << BTN_DOWN)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0
        await pulse_frame_tick(dut, 1) # Wacht 1 frame voor debounce/loslaten
        huidige_sel = int(dut.chest_sel.value)

    # 6. Druk op SELECT om de kist te openen
    dut.btn_pressed.value = (1 << BTN_SELECT)
    await pulse_frame_tick(dut, 1) # Verwerkt de knopdruk
    dut.btn_pressed.value = 0      # Laat knop weer los!

    # KANSER: Geef de klok 1 tick de tijd om de nieuwe state (C_OPEN) te registreren!
    await ClockCycles(dut.clk, 1)

    # Nu MOET hij in C_OPEN (1) zitten!
    assert int(dut.chest_state.value) == C_OPEN, f"Moest C_OPEN (1) zijn, maar was state {int(dut.chest_state.value)}"

    # 7. Spoel de animatie timers door
    # We wachten dynamisch tot de state verandert (met een timeout voor de veiligheid)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_OPEN:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_OPEN"

    assert int(dut.chest_state.value) == C_RESULT, "Niet naar C_RESULT gegaan na animatie 1"
    
    # Wacht nu op de tweede animatie (C_RESULT -> C_PICK)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_RESULT:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_RESULT"

    # We zouden nu terug in C_MENU moeten zijn (want COIN triggert geen game over)
    assert int(dut.chest_state.value) == C_MENU, "Niet terug in C_MENU beland"
    
    # 8. Check de winst! Pot = 40 (reward van ronde 0) en round = 1
    huidige_pot = int(dut.pot.value)
    huidige_ronde = int(dut.round.value)
    assert huidige_pot == 40, f"Pot zou 40 moeten zijn, maar is {huidige_pot}"
    assert huidige_ronde == 1, f"Ronde zou 1 moeten zijn, maar is {huidige_ronde}"

    # 10. Check uitgaande signalen voor cashout
    assert int(dut.req_coins_add.value) == 0, "req_coins_add is niet 1 na cashout!"
    assert int(dut.pot_payout.value) == 0, f"pot_payout was {int(dut.pot_payout.value)}, moest 0 zijn"
    assert int(dut.minigame_done.value) == 0, "minigame_done niet verstuurd!"
    assert int(dut.req_heart_lose_chest.value) == 0, "req_heart_lose_chest is niet 0 na cashout"

    # 9. Cash out (Stop op tijd)
    dut.btn_pressed.value = (1 << BTN_BACK)
    await pulse_frame_tick(dut, 1)
    dut.btn_pressed.value = 0
    
    # Wacht 1 clock tick om de combinatorische logica (en reset) door te laten tikken
    await ClockCycles(dut.clk, 1) 

    # 10. Check uitgaande signalen
    assert int(dut.req_coins_add.value) == 1, "req_coins_add is niet 1 na cashout!"
    assert int(dut.pot_payout.value) == 40, f"pot_payout was {int(dut.pot_payout.value)}, moest 40 zijn"
    assert int(dut.minigame_done.value) == 1, "minigame_done niet verstuurd!"
    assert int(dut.req_heart_lose_chest.value) == 0, "req_heart_lose_chest is niet 0 na cashout"

    # home.v ziet minigame_done en sluit de game:
    dut.active.value = 0
    await pulse_frame_tick(dut, 1)
    
    # Verifieer dat de chip echt terug reset naar het begin!
    assert int(dut.chest_state.value) == C_PICK, "Chip resette niet netjes nadat active 0 werd!"

@cocotb.test()
async def test_chest_game_bomb(dut):
    # 1. Start de klok
    cocotb.start_soon(Clock(dut.clk, 40, units="ns").start())

    # 2. Reset de chip
    dut.active.value = 0
    dut.btn_pressed.value = 0
    dut.frame_tick.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # 3. Activeer de minigame
    dut.active.value = 1
    
    # KANSER: Geef de chip 1 frame_tick om de kisten te schudden (dealt = 1 maken)
    await pulse_frame_tick(dut, 1)
    
    assert int(dut.chest_state.value) == C_PICK, "State is niet C_PICK na activatie"

    # 4. SPIEKEN: Waar zit de munt?
    doel_kist = 0
    for i in range(3):
        if int(dut.contents[i].value) == O_BOMB:
            doel_kist = i
            break

    print(f"BOM gevonden in {int(doel_kist)}")

    # 5. Navigeer de cursor naar de juiste kist
    huidige_sel = int(dut.chest_sel.value)
    while huidige_sel < doel_kist:
        print(f"huidige selectie: {int(huidige_sel)}")
        # Druk op RECHTS (btn 5 -> bitmask 1 << 5 = 32, of 1 << BTN_DOWN)
        dut.btn_pressed.value = (1 << BTN_DOWN)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0
        await pulse_frame_tick(dut, 1) # Wacht 1 frame voor debounce/loslaten
        huidige_sel = int(dut.chest_sel.value)

    # 6. Druk op SELECT om de kist te openen
    dut.btn_pressed.value = (1 << BTN_SELECT)
    await pulse_frame_tick(dut, 1) # Verwerkt de knopdruk
    dut.btn_pressed.value = 0      # Laat knop weer los!

    print("BOM kist gekozen!")

    # KANSER: Geef de klok 1 tick de tijd om de nieuwe state (C_OPEN) te registreren!
    await ClockCycles(dut.clk, 1)

    # Nu MOET hij in C_OPEN (1) zitten!
    assert int(dut.chest_state.value) == C_OPEN, f"Moest C_OPEN (1) zijn, maar was state {int(dut.chest_state.value)}"

    # 7. Spoel de animatie timers door
    # We wachten dynamisch tot de state verandert (met een timeout voor de veiligheid)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_OPEN:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_OPEN"

    assert int(dut.chest_state.value) == C_RESULT, "Niet naar C_RESULT gegaan na animatie 1"
    
    # Wacht nu op de tweede animatie (C_RESULT -> C_PICK)
    timeout_counter = 0
    while int(dut.minigame_done.value) == 0:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip had na 100 frames nog steeds minigame_done = 0"


    # 8. Check de winst! Pot = 0 (reward van ronde 0) en round = 1
    huidige_pot = int(dut.pot.value)
    huidige_ronde = int(dut.round.value)
    assert huidige_pot == 0, f"Pot zou 0 moeten zijn, maar is {huidige_pot}"
    assert huidige_ronde == 0, f"Ronde zou 0 moeten zijn, maar is {huidige_ronde}"

    # Wacht 1 clock tick om de combinatorische logica (en reset) door te laten tikken
    await ClockCycles(dut.clk, 1) 

    # 10. Check uitgaande signalen
    assert int(dut.req_coins_add.value) == 0, "req_coins_add is niet 0 na bom!"
    assert int(dut.pot_payout.value) == 0, f"pot_payout was {int(dut.pot_payout.value)}, moest 0 zijn"
    assert int(dut.minigame_done.value) == 1, "minigame_done niet verstuurd!"
    assert int(dut.req_heart_lose_chest.value) == 0, "req_heart_lose_chest is niet 0 na bom"

    # home.v ziet minigame_done en sluit de game:
    dut.active.value = 0
    await pulse_frame_tick(dut, 1)
    
    # Verifieer dat de chip echt terug reset naar het begin!
    assert int(dut.chest_state.value) == C_PICK, "Chip resette niet netjes nadat active 0 werd!"

    

@cocotb.test()
async def test_chest_game_BOMB2(dut):
    # 1. Start de klok
    cocotb.start_soon(Clock(dut.clk, 40, units="ns").start())

    # 2. Reset de chip
    dut.active.value = 0
    dut.btn_pressed.value = 0
    dut.frame_tick.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # 3. Activeer de minigame
    dut.active.value = 1
    
    # KANSER: Geef de chip 1 frame_tick om de kisten te schudden (dealt = 1 maken)
    await pulse_frame_tick(dut, 1)
    
    assert int(dut.chest_state.value) == C_PICK, "State is niet C_PICK na activatie"

    # 4. Speel 2 rondes (0 & 1)
    for huidige_ronde in range(2):
        print(f"\n--- Start Ronde {huidige_ronde + 1} ---")
        
        # SPIEKEN: We zoeken de beste kist (O_2X is prioriteit, anders O_COIN)
        doel_kist = 0
        gevonden_item = O_COIN
        for i in range(3):
            inhoud = int(dut.contents[i].value)
            if inhoud == O_2X:
                doel_kist = i
                gevonden_item = O_2X
                break # 2X is het beste, we kunnen stoppen met zoeken
            elif inhoud == O_COIN:
                doel_kist = i
                gevonden_item = O_COIN
        
        item_naam = "2X" if gevonden_item == O_2X else "COIN"
        print(f"Spieken: We hebben een {item_naam} gevonden in kist {doel_kist}.")

        # CURSOR VERPLAATSEN
        huidige_sel = int(dut.chest_sel.value)
        while huidige_sel != doel_kist:
            if huidige_sel < doel_kist:
                dut.btn_pressed.value = (1 << BTN_DOWN)
            else:
                dut.btn_pressed.value = (1 << BTN_UP)
            
            await pulse_frame_tick(dut, 1)
            dut.btn_pressed.value = 0
            await pulse_frame_tick(dut, 1)
            huidige_sel = int(dut.chest_sel.value)

        # KIST OPENEN (SELECT)
        dut.btn_pressed.value = (1 << BTN_SELECT)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0
        await ClockCycles(dut.clk, 1) # Registratie tick
        
        assert int(dut.chest_state.value) == C_OPEN, "Niet naar C_OPEN gegaan!"

        # ANIMATIE 1 DOORVERWERKEN (C_OPEN -> C_RESULT)
        timeout = 0
        while int(dut.chest_state.value) == C_OPEN:
            await pulse_frame_tick(dut, 1)
            timeout += 1
            if timeout > 100: assert False, "Vastgelopen in C_OPEN"
            
        assert int(dut.chest_state.value) == C_RESULT, "Niet naar C_RESULT gegaan!"

        # ANIMATIE 2 DOORVERWERKEN (C_RESULT -> Verder)
        timeout = 0
        while int(dut.chest_state.value) == C_RESULT:
            await pulse_frame_tick(dut, 1)
            timeout += 1
            if timeout > 100: assert False, "Vastgelopen in C_RESULT"

        # We zouden nu terug in C_MENU moeten zijn (want COIN triggert geen game over)
        assert int(dut.chest_state.value) == C_MENU, "Niet terug in C_MENU beland"        

        # naar volgende ronde vanuit C_MENU (SELECT)
        dut.btn_pressed.value = (1 << BTN_SELECT)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0

        #Geef de chip exact 1 frame om de nieuwe kisten te vullen!
        await pulse_frame_tick(dut, 1)

        # We moeten door naar de volgende ronde, dus terug in C_PICK
        assert int(dut.chest_state.value) == C_PICK, "Spel had door moeten gaan, maar is gestopt!"


    # 5. SPIEKEN nu dat er een BOMB2 tussen zit
    doel_kist = 0
    for i in range(3):
        if int(dut.contents[i].value) == O_BOMB2:
            doel_kist = i
            break

    print(f"BOMB2 gevonden in {int(doel_kist)}")

    # 5. Navigeer de cursor naar de juiste kist
    huidige_sel = int(dut.chest_sel.value)
    while huidige_sel < doel_kist:
        print(f"huidige selectie: {int(huidige_sel)}")
        # Druk op RECHTS (btn 5 -> bitmask 1 << 5 = 32, of 1 << BTN_DOWN)
        dut.btn_pressed.value = (1 << BTN_DOWN)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0
        await pulse_frame_tick(dut, 1) # Wacht 1 frame voor debounce/loslaten
        huidige_sel = int(dut.chest_sel.value)

    # 6. Druk op SELECT om de kist te openen
    dut.btn_pressed.value = (1 << BTN_SELECT)
    await pulse_frame_tick(dut, 1) # Verwerkt de knopdruk
    dut.btn_pressed.value = 0      # Laat knop weer los!

    print("BOMB2 kist gekozen!")

    # KANSER: Geef de klok 1 tick de tijd om de nieuwe state (C_OPEN) te registreren!
    await ClockCycles(dut.clk, 1)

    # Nu MOET hij in C_OPEN (1) zitten!
    assert int(dut.chest_state.value) == C_OPEN, f"Moest C_OPEN (1) zijn, maar was state {int(dut.chest_state.value)}"

    # 7. Spoel de animatie timers door
    # We wachten dynamisch tot de state verandert (met een timeout voor de veiligheid)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_OPEN:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_OPEN"

    assert int(dut.chest_state.value) == C_RESULT, "Niet naar C_RESULT gegaan na animatie 1"
    
    # Wacht nu op de tweede animatie (C_RESULT -> C_PICK)
    timeout_counter = 0
    while int(dut.minigame_done.value) == 0:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip had na 100 frames nog steeds minigame_done = 0"


    # 8. Check de winst! Pot = 0 (reward van ronde 0) en round = 2
    huidige_pot = int(dut.pot.value)
    huidige_ronde = int(dut.round.value)
    assert huidige_pot == 0, f"Pot zou 0 moeten zijn, maar is {huidige_pot}"
    assert huidige_ronde == 2, f"Ronde zou 2 moeten zijn, maar is {huidige_ronde}"

    # Wacht 1 clock tick om de combinatorische logica (en reset) door te laten tikken
    await ClockCycles(dut.clk, 1) 

    # 10. Check uitgaande signalen
    assert int(dut.req_coins_add.value) == 0, "req_coins_add is niet 0 na bomb2!"
    assert int(dut.pot_payout.value) == 0, f"pot_payout was {int(dut.pot_payout.value)}, moest 0 zijn"
    assert int(dut.minigame_done.value) == 1, "minigame_done niet verstuurd!"
    assert int(dut.req_heart_lose_chest.value) == 1, "req_heart_lose_chest is niet 1 na bomb2"

    # home.v ziet minigame_done en sluit de game:
    dut.active.value = 0
    await pulse_frame_tick(dut, 1)
    
    # Verifieer dat de chip echt terug reset naar het begin!
    assert int(dut.chest_state.value) == C_PICK, "Chip resette niet netjes nadat active 0 werd!"


@cocotb.test()
async def test_chest_game_CURSED(dut):
    # 1. Start de klok
    cocotb.start_soon(Clock(dut.clk, 40, units="ns").start())

    # 2. Reset de chip
    dut.active.value = 0
    dut.btn_pressed.value = 0
    dut.frame_tick.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # 3. Activeer de minigame
    dut.active.value = 1
    
    # KANSER: Geef de chip 1 frame_tick om de kisten te schudden (dealt = 1 maken)
    await pulse_frame_tick(dut, 1)
    
    assert int(dut.chest_state.value) == C_PICK, "State is niet C_PICK na activatie"

    # 4. speel 1 ronde op voorhand
    doel_kist = 0
    for i in range(3):
        if int(dut.contents[i].value) == O_COIN:
            doel_kist = i
            break

    huidige_sel = int(dut.chest_sel.value)
    while huidige_sel < doel_kist:
        # Druk op RECHTS (btn 5 -> bitmask 1 << 5 = 32, of 1 << BTN_DOWN)
        dut.btn_pressed.value = (1 << BTN_DOWN)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0
        await pulse_frame_tick(dut, 1) # Wacht 1 frame voor debounce/loslaten
        huidige_sel = int(dut.chest_sel.value)

    dut.btn_pressed.value = (1 << BTN_SELECT)
    await pulse_frame_tick(dut, 1) # Verwerkt de knopdruk
    dut.btn_pressed.value = 0      # Laat knop weer los!

    # KANSER: Geef de klok 1 tick de tijd om de nieuwe state (C_OPEN) te registreren!
    await ClockCycles(dut.clk, 1)

    # Nu MOET hij in C_OPEN (1) zitten!
    assert int(dut.chest_state.value) == C_OPEN, f"Moest C_OPEN (1) zijn, maar was state {int(dut.chest_state.value)}"

    # Spoel de animatie timers door
    # We wachten dynamisch tot de state verandert (met een timeout voor de veiligheid)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_OPEN:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_OPEN"

    assert int(dut.chest_state.value) == C_RESULT, "Niet naar C_RESULT gegaan na animatie 1"
    
    # Wacht nu op de tweede animatie (C_RESULT -> C_PICK)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_RESULT:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_RESULT"

    # We zouden nu terug in C_MENU moeten zijn (want COIN triggert geen game over)
    assert int(dut.chest_state.value) == C_MENU, "Niet terug in C_MENU beland"
    
    # Check de winst! Pot = 40 (reward van ronde 0) en round = 1
    huidige_pot = int(dut.pot.value)
    huidige_ronde = int(dut.round.value)
    assert huidige_pot == 40, f"Pot zou 40 moeten zijn, maar is {huidige_pot}"
    assert huidige_ronde == 1, f"Ronde zou 1 moeten zijn, maar is {huidige_ronde}"
  
    # naar volgende ronde vanuit C_MENU (SELECT)
    dut.btn_pressed.value = (1 << BTN_SELECT)
    await pulse_frame_tick(dut, 1)
    dut.btn_pressed.value = 0

    #Geef de chip exact 1 frame om de nieuwe kisten te vullen!
    await pulse_frame_tick(dut, 1)

    # We moeten door naar de volgende ronde, dus terug in C_PICK
    assert int(dut.chest_state.value) == C_PICK, "Spel had door moeten gaan, maar is gestopt!"


    # 5. SPIEKEN nu dat er een cursed tussen zit
    doel_kist = 0
    for i in range(3):
        if int(dut.contents[i].value) == O_CURSED:
            doel_kist = i
            break

    print(f"cursed gevonden in {int(doel_kist)}")

    # 6. Navigeer de cursor naar de juiste kist
    huidige_sel = int(dut.chest_sel.value)
    while huidige_sel < doel_kist:
        print(f"huidige selectie: {int(huidige_sel)}")
        # Druk op RECHTS (btn 5 -> bitmask 1 << 5 = 32, of 1 << BTN_DOWN)
        dut.btn_pressed.value = (1 << BTN_DOWN)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0
        await pulse_frame_tick(dut, 1) # Wacht 1 frame voor debounce/loslaten
        huidige_sel = int(dut.chest_sel.value)

    # 7. Druk op SELECT om de kist te openen
    dut.btn_pressed.value = (1 << BTN_SELECT)
    await pulse_frame_tick(dut, 1) # Verwerkt de knopdruk
    dut.btn_pressed.value = 0      # Laat knop weer los!

    print("cursed kist gekozen!")

    # KANSER: Geef de klok 1 tick de tijd om de nieuwe state (C_OPEN) te registreren!
    await ClockCycles(dut.clk, 1)

    # Nu MOET hij in C_OPEN (1) zitten!
    assert int(dut.chest_state.value) == C_OPEN, f"Moest C_OPEN (1) zijn, maar was state {int(dut.chest_state.value)}"

    # 8. Spoel de animatie timers door
    # We wachten dynamisch tot de state verandert (met een timeout voor de veiligheid)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_OPEN:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_OPEN"

    assert int(dut.chest_state.value) == C_RESULT, "Niet naar C_RESULT gegaan na animatie 1"
    
    # Wacht nu op de tweede animatie (C_RESULT -> C_PICK)
    timeout_counter = 0
    while int(dut.minigame_done.value) == 0:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip had na 100 frames nog steeds minigame_done = 0"


    # 9. Check de winst! Pot = 40 (reward van ronde 0) en round = 1
    huidige_pot = int(dut.pot.value)
    huidige_ronde = int(dut.round.value)
    assert huidige_pot == 40, f"Pot zou 40 moeten zijn, maar is {huidige_pot}"
    assert huidige_ronde == 1, f"Ronde zou 1 moeten zijn, maar is {huidige_ronde}"

    # Wacht 1 clock tick om de combinatorische logica (en reset) door te laten tikken
    await ClockCycles(dut.clk, 1) 

    # 10. Check uitgaande signalen
    assert int(dut.req_coins_add.value) == 1, "req_coins_add is niet 1 na cursed!"
    assert int(dut.pot_payout.value) == 40, f"pot_payout was {int(dut.pot_payout.value)}, moest 40 zijn"
    assert int(dut.minigame_done.value) == 1, "minigame_done niet verstuurd!"
    assert int(dut.req_heart_lose_chest.value) == 1, "req_heart_lose_chest is niet 1 na cursed"

    # home.v ziet minigame_done en sluit de game:
    dut.active.value = 0
    await pulse_frame_tick(dut, 1)
    
    # Verifieer dat de chip echt terug reset naar het begin!
    assert int(dut.chest_state.value) == C_PICK, "Chip resette niet netjes nadat active 0 werd!"


@cocotb.test()
async def test_chest_game_2x(dut):
    # 1. Start de klok
    cocotb.start_soon(Clock(dut.clk, 40, units="ns").start())

    # 2. Reset de chip
    dut.active.value = 0
    dut.btn_pressed.value = 0
    dut.frame_tick.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # 3. Activeer de minigame
    dut.active.value = 1
    
    # KANSER: Geef de chip 1 frame_tick om de kisten te schudden (dealt = 1 maken)
    await pulse_frame_tick(dut, 1)
    
    assert int(dut.chest_state.value) == C_PICK, "State is niet C_PICK na activatie"

    # 4. speel 1 ronde op voorhand
    doel_kist = 0
    for i in range(3):
        if int(dut.contents[i].value) == O_COIN:
            doel_kist = i
            break

    huidige_sel = int(dut.chest_sel.value)
    while huidige_sel < doel_kist:
        # Druk op RECHTS (btn 5 -> bitmask 1 << 5 = 32, of 1 << BTN_DOWN)
        dut.btn_pressed.value = (1 << BTN_DOWN)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0
        await pulse_frame_tick(dut, 1) # Wacht 1 frame voor debounce/loslaten
        huidige_sel = int(dut.chest_sel.value)

    dut.btn_pressed.value = (1 << BTN_SELECT)
    await pulse_frame_tick(dut, 1) # Verwerkt de knopdruk
    dut.btn_pressed.value = 0      # Laat knop weer los!

    # KANSER: Geef de klok 1 tick de tijd om de nieuwe state (C_OPEN) te registreren!
    await ClockCycles(dut.clk, 1)

    # Nu MOET hij in C_OPEN (1) zitten!
    assert int(dut.chest_state.value) == C_OPEN, f"Moest C_OPEN (1) zijn, maar was state {int(dut.chest_state.value)}"

    # Spoel de animatie timers door
    # We wachten dynamisch tot de state verandert (met een timeout voor de veiligheid)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_OPEN:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_OPEN"

    assert int(dut.chest_state.value) == C_RESULT, "Niet naar C_RESULT gegaan na animatie 1"
    
    # Wacht nu op de tweede animatie (C_RESULT -> C_PICK)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_RESULT:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_RESULT"

    # We zouden nu terug in C_MENU moeten zijn (want COIN triggert geen game over)
    assert int(dut.chest_state.value) == C_MENU, "Niet terug in C_MENU beland"
    
    # Check de winst! Pot = 40 (reward van ronde 0) en round = 1
    huidige_pot = int(dut.pot.value)
    huidige_ronde = int(dut.round.value)
    assert huidige_pot == 40, f"Pot zou 40 moeten zijn, maar is {huidige_pot}"
    assert huidige_ronde == 1, f"Ronde zou 1 moeten zijn, maar is {huidige_ronde}"
  
    # naar volgende ronde vanuit C_MENU (SELECT)
    dut.btn_pressed.value = (1 << BTN_SELECT)
    await pulse_frame_tick(dut, 1)
    dut.btn_pressed.value = 0

    #Geef de chip exact 1 frame om de nieuwe kisten te vullen!
    await pulse_frame_tick(dut, 1)

    # We moeten door naar de volgende ronde, dus terug in C_PICK
    assert int(dut.chest_state.value) == C_PICK, "Spel had door moeten gaan, maar is gestopt!"


    # 5. SPIEKEN nu dat er een 2x tussen zit
    doel_kist = 0
    for i in range(3):
        if int(dut.contents[i].value) == O_2X:
            doel_kist = i
            break

    print(f"2x gevonden in {int(doel_kist)}")

    # 6. Navigeer de cursor naar de juiste kist
    huidige_sel = int(dut.chest_sel.value)
    while huidige_sel < doel_kist:
        print(f"huidige selectie: {int(huidige_sel)}")
        # Druk op RECHTS (btn 5 -> bitmask 1 << 5 = 32, of 1 << BTN_DOWN)
        dut.btn_pressed.value = (1 << BTN_DOWN)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0
        await pulse_frame_tick(dut, 1) # Wacht 1 frame voor debounce/loslaten
        huidige_sel = int(dut.chest_sel.value)

    # 7. Druk op SELECT om de kist te openen
    dut.btn_pressed.value = (1 << BTN_SELECT)
    await pulse_frame_tick(dut, 1) # Verwerkt de knopdruk
    dut.btn_pressed.value = 0      # Laat knop weer los!

    print("2x kist gekozen!")

    # KANSER: Geef de klok 1 tick de tijd om de nieuwe state (C_OPEN) te registreren!
    await ClockCycles(dut.clk, 1)

    # Nu MOET hij in C_OPEN (1) zitten!
    assert int(dut.chest_state.value) == C_OPEN, f"Moest C_OPEN (1) zijn, maar was state {int(dut.chest_state.value)}"

    # 8. Spoel de animatie timers door
    # We wachten dynamisch tot de state verandert (met een timeout voor de veiligheid)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_OPEN:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip zat na 100 frames nog steeds vast in C_OPEN"

    assert int(dut.chest_state.value) == C_RESULT, "Niet naar C_RESULT gegaan na animatie 1"
    
    # Wacht nu op de tweede animatie (C_RESULT -> C_PICK)
    timeout_counter = 0
    while int(dut.chest_state.value) == C_RESULT:
        await pulse_frame_tick(dut, 1)
        timeout_counter += 1
        if timeout_counter > 100:
            assert False, f"Timeout! Chip had na 100 frames nog steeds minigame_done = 0"


    # 9. Check de winst! Pot = 80 (reward van ronde 0) en round = 2
    huidige_pot = int(dut.pot.value)
    huidige_ronde = int(dut.round.value)
    assert huidige_pot == 80, f"Pot zou 80 moeten zijn, maar is {huidige_pot}"
    assert huidige_ronde == 2, f"Ronde zou 0 moeten zijn, maar is {huidige_ronde}"

    # 10. Check uitgaande signalen
    assert int(dut.req_coins_add.value) == 0, "req_coins_add is niet 0 na 2x voor cashout!"
    assert int(dut.pot_payout.value) == 0, f"pot_payout was {int(dut.pot_payout.value)}, moest 0 zijn"
    assert int(dut.minigame_done.value) == 0, "minigame_done ongeldig verstuurd!"
    assert int(dut.req_heart_lose_chest.value) == 0, "req_heart_lose_chest ongeldig verstuurd na 2x"

    # 9. Cash out (Stop op tijd)
    dut.btn_pressed.value = (1 << BTN_BACK)
    await pulse_frame_tick(dut, 1)
    dut.btn_pressed.value = 0

    # Wacht 1 clock tick om de combinatorische logica (en reset) door te laten tikken
    await ClockCycles(dut.clk, 1) 

    # 10. Check uitgaande signalen
    assert int(dut.req_coins_add.value) == 1, "req_coins_add is niet 1 na 2x!"
    assert int(dut.pot_payout.value) == 80, f"pot_payout was {int(dut.pot_payout.value)}, moest 80 zijn"
    assert int(dut.minigame_done.value) == 1, "minigame_done niet verstuurd!"
    assert int(dut.req_heart_lose_chest.value) == 0, "req_heart_lose_chest is niet 0 na 2x"

    # home.v ziet minigame_done en sluit de game:
    dut.active.value = 0
    await pulse_frame_tick(dut, 1)
    
    # Verifieer dat de chip echt terug reset naar het begin!
    assert int(dut.chest_state.value) == C_PICK, "Chip resette niet netjes nadat active 0 werd!"


@cocotb.test()
async def test_chest_game_perfect_run(dut):
    """Speelt de minigame perfect uit tot en met ronde 6 (round == 5)"""
    # 1. Start de klok
    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())

    # 2. Reset de chip
    dut.active.value = 0
    dut.btn_pressed.value = 0
    dut.frame_tick.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # 3. Activeer de game
    dut.active.value = 1
    await pulse_frame_tick(dut, 1) # Geef hardware de tijd om 'dealt' op 1 te zetten
    
    assert int(dut.chest_state.value) == C_PICK, "State is niet C_PICK na activatie"

    verwachte_pot = 0

    # 4. Speel 6 rondes (0 tot en met 5)
    for huidige_ronde in range(6):
        print(f"\n--- Start Ronde {huidige_ronde + 1} ---")
        
        # SPIEKEN: We zoeken de beste kist (O_2X is prioriteit, anders O_COIN)
        doel_kist = 0
        gevonden_item = O_COIN
        for i in range(3):
            inhoud = int(dut.contents[i].value)
            if inhoud == O_2X:
                doel_kist = i
                gevonden_item = O_2X
                break # 2X is het beste, we kunnen stoppen met zoeken
            elif inhoud == O_COIN:
                doel_kist = i
                gevonden_item = O_COIN
        
        item_naam = "2X" if gevonden_item == O_2X else "COIN"
        print(f"Spieken: We hebben een {item_naam} gevonden in kist {doel_kist}.")

        # BEREKEN VERWACHTE POT (om later te checken)
        if huidige_ronde == 0:
            verwachte_pot = 40 # Round 0 reward
        elif gevonden_item == O_2X:
            verwachte_pot *= 2
            if verwachte_pot > 999: 
                verwachte_pot = 999
        elif gevonden_item == O_COIN:
            verwachte_pot += int(dut.reward.value)
            if verwachte_pot > 999: 
                verwachte_pot = 999

        # CURSOR VERPLAATSEN
        huidige_sel = int(dut.chest_sel.value)
        while huidige_sel != doel_kist:
            if huidige_sel < doel_kist:
                dut.btn_pressed.value = (1 << BTN_DOWN)
            else:
                dut.btn_pressed.value = (1 << BTN_UP)
            
            await pulse_frame_tick(dut, 1)
            dut.btn_pressed.value = 0
            await pulse_frame_tick(dut, 1)
            huidige_sel = int(dut.chest_sel.value)

        # KIST OPENEN (SELECT)
        dut.btn_pressed.value = (1 << BTN_SELECT)
        await pulse_frame_tick(dut, 1)
        dut.btn_pressed.value = 0
        await ClockCycles(dut.clk, 1) # Registratie tick
        
        assert int(dut.chest_state.value) == C_OPEN, "Niet naar C_OPEN gegaan!"

        # ANIMATIE 1 DOORVERWERKEN (C_OPEN -> C_RESULT)
        timeout = 0
        while int(dut.chest_state.value) == C_OPEN:
            await pulse_frame_tick(dut, 1)
            timeout += 1
            if timeout > 100: assert False, "Vastgelopen in C_OPEN"
            
        assert int(dut.chest_state.value) == C_RESULT, "Niet naar C_RESULT gegaan!"

        # ANIMATIE 2 DOORVERWERKEN (C_RESULT -> Verder)
        timeout = 0
        while int(dut.chest_state.value) == C_RESULT:
            await pulse_frame_tick(dut, 1)
            timeout += 1
            if timeout > 100: assert False, "Vastgelopen in C_RESULT"

        # We zouden nu terug in C_MENU moeten zijn (want COIN triggert geen game over)
        assert int(dut.chest_state.value) == C_MENU, "Niet terug in C_MENU beland"

        # DE UITSLAG CONTROLEREN
        hardware_pot = int(dut.pot.value)
        print(f"Pot staat na ronde {huidige_ronde + 1} op: {hardware_pot} munten.")
        
        assert hardware_pot == verwachte_pot, f"Fout in berekening! Hardware: {hardware_pot}, Verwacht: {verwachte_pot}"

        

        if huidige_ronde < 5:
            # naar volgende ronde vanuit C_MENU (SELECT)
            dut.btn_pressed.value = (1 << BTN_SELECT)
            await pulse_frame_tick(dut, 1)
            dut.btn_pressed.value = 0

            #Geef de chip exact 1 frame om de nieuwe kisten te vullen!
            await pulse_frame_tick(dut, 1)

            # We moeten door naar de volgende ronde, dus terug in C_PICK
            assert int(dut.chest_state.value) == C_PICK, "Spel had door moeten gaan, maar is gestopt!"
        else:
            # Na ronde 6 (index 5) stoppen
            # 9. Cash out (Stop op tijd)
            dut.btn_pressed.value = (1 << BTN_BACK)
            await pulse_frame_tick(dut, 1)
            dut.btn_pressed.value = 0
            assert int(dut.minigame_done.value) == 1, "Ronde 6 voltooid, maar minigame_done is niet 1!"
            assert int(dut.req_coins_add.value) == 1, "req_coins_add pulse ontbreekt na automatische cashout in ronde 6!"

            eind_payout = int(dut.pot_payout.value)
            assert eind_payout == verwachte_pot, f"Payout was {eind_payout}, maar verwachtte de 999 cap!"

            # home.v ziet minigame_done en sluit de game:
            dut.active.value = 0
            await pulse_frame_tick(dut, 1)
            # Verifieer dat de chip echt terug reset naar het begin!
            assert int(dut.chest_state.value) == C_PICK, "Chip resette niet netjes nadat active 0 werd!"

            print(f"✅ PERFECT RUN GESLAAGD! De speler heeft de game uitgespeeld en {hardware_pot} munten gewonnen!")
