"""
test_renderer.py -- renderer.v met ALLE tekenmodules eronder (integratie).

Geen spel, geen FSM's: we zetten een spelstatus rechtstreeks op de ingangen
van de renderer en kijken wat er op het scherm komt.  Zo test je precies de
dingen die je met een PNG niet ziet: is de stapelvolgorde goed, wint de HUD
van een effect, komt er een X uit, klopt het cijfer dat er staat.

Draait tegen de ECHTE sprites.v en de echte .hex in test/.  Alles hieronder
is onafhankelijk van hoe de plaatjes eruitzien: we lezen cijfers terug via
het font (digit_rom), en voor sprites tellen we alleen of er iets staat.

Wat hier getest wordt:
  1. buiten video_active is alles zwart, in elke mode
  2. geen enkele X of Z op het scherm, in acht representatieve statussen
  3. per mode staat er wat er hoort en NIET wat er niet hoort (hartjes niet
     op GAME OVER, geen knoppen in de kistkamer, geen draak op de titel, ...)
  4. hartjes: 0..5 rood gevuld, lege slots alleen omtrek, overflow = wit
  5. het levelnummer dat op het scherm staat IS level_shown (1..7)
  6. de munten: cijfers en balkvulling via de gedeelde digit_rom
  7. de kistkamer: rondenummer en pot via dezelfde digit_rom, highlight op
     de gekozen kist, icoon alleen waar het hoort, dimmen bij RESULT
  8. satisfaction: de ring op precies het gekozen vakje, kleuren 1..5
  9. stapeling: HUD boven vlam en water; vlam en spat boven de draak
 10. dag/nacht: zon geel, maan wit, draak in het nachtpalet
 11. 's nachts leesbaar: levelnummer en lege hartjes tegen de lucht
 12. de evolve-flits hoort alleen in HOME -- niet op de titel na een win

    make test_renderer
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles

TITLE, EGG, HOME, CHEST, GAMEOVER, YOU_WIN = range(6)
PICK, OPEN, RESULT, MENU = range(4)
SKY, NIGHT_SKY = 0b011011, 0b000000
RED, WHITE, BLACK, GOLD, YELLOW = 0b110000, 0b111111, 0b000000, 0b111000, 0b111100
DARK_RED = 0b010000
TITLE_COLOURS = {0b000100, 0b011101, 0b001000}
SAT_COLOURS = [0b110000, 0b110100, 0b111100, 0b101100, 0b001100]

DIGIT_ROM = {
    0: ["0110", "1001", "1001", "1001", "1001", "0110"],
    1: ["0010", "0110", "0010", "0010", "0010", "0111"],
    2: ["0110", "1001", "0001", "0010", "0100", "1111"],
    3: ["1110", "0001", "0110", "0001", "0001", "1110"],
    4: ["1001", "1001", "1111", "0001", "0001", "0001"],
    5: ["1111", "1000", "1110", "0001", "0001", "1110"],
    6: ["0110", "1000", "1110", "1001", "1001", "0110"],
    7: ["1111", "0001", "0010", "0100", "0100", "0100"],
    8: ["0110", "1001", "0110", "1001", "1001", "0110"],
    9: ["0110", "1001", "0111", "0001", "0001", "0110"],
}

DEFAULTS = dict(mode=HOME, menu_sel=0, hearts=5, satisfaction=2, dragon_bob=0, coins=0,
                level=1, evolve_now=0, combo_len=0, chest_state=PICK, chest_sel=0,
                chest_outcome=0, flash=0, evolve_blink=1, night=0, frame_tick=0, btn_level=0,
                fx_kind=0, fx_on=0, fx_age=0, level_shown=1, evo_on=0, evo_r=0, overflow=0,
                chest_contents=0, pot=0, round=0, egg_frame=0, flash_r=0, video_active=1)


# -------------------------------------------------------------- helpers ----
async def setup(dut, **kw):
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())
    dut.rst_n.value = 0
    st = dict(DEFAULTS, **kw)
    for k, v in st.items():
        getattr(dut, k).value = v
    dut.pix_x.value = 0
    dut.pix_y.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


def set_state(dut, **kw):
    for k, v in kw.items():
        getattr(dut, k).value = v


async def px(dut, x, y):
    """Portret-pixel (x 0..479, y 0..639) -> 6-bit RRGGBB.  De draak is op de
    klok gesynchroniseerd, dus we wachten een flank."""
    dut.pix_y.value = x
    dut.pix_x.value = 639 - y
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    r, g, b = dut.R.value, dut.G.value, dut.B.value
    if not (r.is_resolvable and g.is_resolvable and b.is_resolvable):
        return None
    return (int(r) << 4) | (int(g) << 2) | int(b)


async def read_digit(dut, x0, y0, scale, ink):
    """Leest een 4x6 cijfer op (x0,y0) met celgrootte `scale` terug via het
    font.  Geeft 0..9, None als het vak leeg is, of 'garbage'."""
    rows = []
    for r in range(6):
        s = ""
        for c in range(4):
            v = await px(dut, x0 + scale * c + scale // 2, y0 + scale * r + scale // 2)
            s += "1" if v == ink else "0"
        rows.append(s)
    if all(r == "0000" for r in rows):
        return None
    for d, pat in DIGIT_ROM.items():
        if rows == pat:
            return d
    return "garbage:" + "/".join(rows)


async def count(dut, signal, xs, ys):
    n = 0
    for y in ys:
        for x in xs:
            await px(dut, x, y)
            n += int(getattr(dut, signal).value)
    return n


# ---------------------------------------------------------------- tests ----
@cocotb.test()
async def test_blanking_is_black(dut):
    await setup(dut, video_active=0)
    for mode in range(6):
        set_state(dut, mode=mode, hearts=5, coins=999)
        for x, y in ((0, 0), (240, 320), (479, 639), (290, 33), (60, 30)):
            assert await px(dut, x, y) == BLACK, f"mode {mode} ({x},{y}) niet zwart buiten video_active"


@cocotb.test()
async def test_no_undefined_pixels(dut):
    """Acht statussen, hele scherm met stap 3: nooit een X of Z op R/G/B."""
    await setup(dut)
    states = [
        dict(mode=TITLE, egg_frame=0),
        dict(mode=EGG, egg_frame=3, flash_r=300),
        dict(mode=HOME, hearts=3, coins=358, level_shown=4, satisfaction=4, night=0, dragon_bob=9),
        dict(mode=HOME, night=1, fx_on=1, fx_kind=1, fx_age=60, overflow=1),
        dict(mode=HOME, fx_on=1, fx_kind=2, fx_age=20, evo_on=1, evo_r=176, flash=1),
        dict(mode=CHEST, chest_state=PICK, chest_sel=2, pot=999, round=15, chest_contents=0b100011010),
        dict(mode=CHEST, chest_state=RESULT, chest_sel=1, chest_contents=0b011001000),
        dict(mode=CHEST, chest_state=MENU, pot=40, round=3),
        dict(mode=GAMEOVER), dict(mode=YOU_WIN),
    ]
    for st in states:
        set_state(dut, **dict(DEFAULTS, **st))
        bad = 0
        for y in range(0, 640, 3):
            for x in range(0, 480, 3):
                if await px(dut, x, y) is None:
                    bad += 1
        assert bad == 0, f"{st}: {bad} pixels met X/Z"


@cocotb.test()
async def test_mode_gating(dut):
    await setup(dut, hearts=5, coins=500, level_shown=3, satisfaction=3)
    heart0 = (290, 33)          # kern van het eerste hartje
    evolve_btn = (240, 488)     # binnenkant van de EVOLVE-knop
    satbar = (89 + 62 * 3, 340) # ring van het gekozen vakje
    coinbar = (44, 60)          # bovenste vakje (leeg bij 500 -> code 1)

    set_state(dut, mode=HOME)
    assert await px(dut, *heart0) == RED
    assert await px(dut, *evolve_btn) == 0b010010, "evolve-knop (gedimd) ontbreekt in HOME"
    assert await px(dut, *satbar) == WHITE, "satbar-ring ontbreekt in HOME"
    assert await px(dut, *coinbar) == 0b010101, "muntbalk ontbreekt in HOME"
    assert await count(dut, "dragon_on", range(174, 302, 8), range(166, 294, 8)) > 0, "geen draak in HOME"

    set_state(dut, mode=CHEST)
    assert await px(dut, *heart0) == RED, "hartjes horen ook in de kistkamer"
    assert await px(dut, *satbar) != WHITE, "satbar hoort niet in de kistkamer"
    assert await count(dut, "dragon_on", range(174, 302, 8), range(166, 294, 8)) == 0 or \
           await px(dut, 240, 230) not in (0b001100,), "draak zichtbaar in de kistkamer"
    assert int(dut.show_buttons.value) == 0 and int(dut.show_coin.value) == 0

    set_state(dut, mode=TITLE)
    assert await px(dut, *heart0) != RED, "hartjes op het titelscherm"
    assert await px(dut, 240, 190) in TITLE_COLOURS, "titelkaart ontbreekt"
    assert await count(dut, "tegg_on", range(120, 360, 16), range(340, 590, 16)) > 0, "geen ei op de titel"
    assert await px(dut, 240, 600) == 0b001000, "gras ontbreekt onder het ei"

    set_state(dut, mode=EGG, egg_frame=2)
    assert await count(dut, "crack_on", range(120, 360, 4), range(340, 590, 4)) > 0, "geen barst in EGG"
    set_state(dut, egg_frame=5, flash_r=760)
    assert await px(dut, 240, 462) == 0b111000, "flits moet het ei bedekken"
    assert await px(dut, 20, 20) == 0b111000, "flits op 760 moet het hele scherm bedekken"

    set_state(dut, mode=GAMEOVER, flash_r=0, egg_frame=0)
    assert await px(dut, *heart0) == DARK_RED, "hartjes zichtbaar op GAME OVER"
    assert await px(dut, 20, 20) == DARK_RED
    assert await count(dut, "gameover_text_on", range(112, 368, 4), range(240, 394, 4)) > 0

    set_state(dut, mode=YOU_WIN)
    assert await px(dut, *heart0) == BLACK
    assert await count(dut, "win_on", range(104, 376, 4), range(200, 456, 4)) > 0
    assert await px(dut, 120, 205) in (BLACK, GOLD)


@cocotb.test()
async def test_hearts_fill_and_overflow(dut):
    await setup(dut, mode=HOME)
    for h in range(6):
        for ov in (0, 1):
            set_state(dut, hearts=h, overflow=ov)
            for k in range(5):
                core = await px(dut, 290 + 40 * k, 33)
                tip = await px(dut, 290 + 40 * k, 47)
                exp = (WHITE if ov else RED) if k < h else SKY
                assert core == exp, f"hearts={h} ov={ov} slot {k}: kern {core:06b}, verwacht {exp:06b}"
                assert tip == BLACK, f"hearts={h} slot {k}: omtrek ontbreekt"
    # meer dan 5 wordt afgekapt, niet buiten de rij getekend
    set_state(dut, hearts=7, overflow=0)
    assert await px(dut, 290 + 40 * 4, 33) == RED
    assert await px(dut, 290 + 40 * 5, 33) == SKY, "een zesde hartje buiten de rij"


@cocotb.test()
async def test_level_number_on_screen(dut):
    """Wat er op het scherm staat moet level_shown zijn.  Faalt dit met
    'kreeg 2' bij level 1, dan telt level_box er nog een bij: verwijder
    de + 4'd1 in sprites.v (level_box, q_digit)."""
    await setup(dut, mode=HOME, night=0)
    for lvl in range(1, 8):
        set_state(dut, level_shown=lvl, level=lvl)
        got = await read_digit(dut, 60, 24, 3, BLACK)
        assert got == lvl, f"level_shown={lvl}: op het scherm staat {got}"
    # en de letters LVL staan er
    assert await px(dut, 25, 30) == BLACK and await px(dut, 25, 40) == BLACK, "de L van LVL ontbreekt"


@cocotb.test()
async def test_coin_counter_and_bar(dut):
    await setup(dut, mode=HOME)
    for coins, digits in ((0, (None, None, 0)), (7, (None, None, 7)), (40, (None, 4, 0)),
                          (358, (3, 5, 8)), (999, (9, 9, 9))):
        set_state(dut, coins=coins)
        got = tuple([await read_digit(dut, 24 + 14 * k, 252, 3, YELLOW) for k in range(3)])
        assert got == digits, f"coins={coins}: cijfers {got}, verwacht {digits}"
        lit = 0
        for k in range(8):
            v = await px(dut, 44, 50 + 4 + 24 * k + 10)
            assert v in (0b010101, YELLOW), f"coins={coins} vakje {k}: {v:06b}"
            lit += v == YELLOW
        exp_lit = 8 if coins >= 999 else coins >> 7      # vol bij de muntcap
        assert lit == exp_lit, f"coins={coins}: {lit} vakjes, verwacht {exp_lit}"


@cocotb.test()
async def test_chest_room(dut):
    await setup(dut, mode=CHEST, chest_state=PICK, chest_sel=1, pot=999, round=15, chest_contents=0)
    # cijfers via de gedeelde digit_rom: ronde 16 en pot 999
    assert (await read_digit(dut, 208, 94, 4, GOLD), await read_digit(dut, 240, 94, 4, GOLD)) == (1, 6)
    assert tuple([await read_digit(dut, 30 + 32 * k, 19, 4, GOLD) for k in range(3)]) == (9, 9, 9)
    set_state(dut, round=0, pot=40)
    assert (await read_digit(dut, 200, 94, 4, GOLD), await read_digit(dut, 232, 94, 4, GOLD)) == (None, 1)
    assert tuple([await read_digit(dut, 30 + 32 * k, 19, 4, GOLD) for k in range(3)]) == (None, 4, 0)

    # highlight: witte rand ALLEEN op de gekozen kist, alleen in PICK
    for sel in range(3):
        set_state(dut, chest_state=PICK, chest_sel=sel)
        for k in range(3):
            v = await px(dut, 176, 204 + 145 * k + 50)
            assert (v == WHITE) == (k == sel), f"PICK sel={sel} kist {k}: rand {v:06b}"
    set_state(dut, chest_state=OPEN, chest_sel=1)
    assert await px(dut, 176, 204 + 145 + 50) != WHITE, "highlight hoort weg na PICK"

    # icoon: in OPEN alleen op de gekozen kist, in RESULT op alle drie
    def icon_box(k):
        return range(176 + 32, 176 + 96, 4), range(204 + 145 * k + 4, 204 + 145 * k + 68, 4)
    set_state(dut, chest_state=OPEN, chest_sel=1)
    for k in range(3):
        n = await count(dut, "chest_icon_on", *icon_box(k))
        assert (n > 0) == (k == 1), f"OPEN: icoon op kist {k}: {n} px"
    set_state(dut, chest_state=RESULT, chest_sel=1)
    for k in range(3):
        assert await count(dut, "chest_icon_on", *icon_box(k)) > 0, f"RESULT: geen icoon op kist {k}"
    # dimmen: dim_color = {0,c[5], 0,c[3], 0,c[1]} -- het hoge bit van elk
    # kanaal schuift naar de lage plek, dus de hoge bits zijn altijd 0
    for k in (0, 2):
        for y in range(204 + 145 * k + 70, 204 + 145 * k + 120, 8):
            v = await px(dut, 240, y)
            if int(dut.chest_body_on.value):
                assert v & 0b101010 == 0, f"RESULT kist {k} niet gedimd: {v:06b}"

    # MENU: geen kisten, wel de knoppen
    set_state(dut, chest_state=MENU)
    assert await count(dut, "chest_body_on", range(176, 304, 8), range(204, 332, 8)) == 0
    assert await px(dut, 200, 480) == 0b001000, "CONTINUE-knop (groen) ontbreekt in het menu"
    assert await px(dut, 200, 570) == GOLD, "CASH OUT-knop (goud) ontbreekt in het menu"


@cocotb.test()
async def test_satisfaction_ring(dut):
    await setup(dut, mode=HOME)
    for sat in range(5):
        set_state(dut, satisfaction=sat)
        for k in range(5):
            v = await px(dut, 89 + 62 * k, 340)
            exp = WHITE if k == sat else SAT_COLOURS[k]
            assert v == exp, f"sat={sat} vakje {k}: {v:06b}, verwacht {exp:06b}"


@cocotb.test()
async def test_effects_stack_order(dut):
    await setup(dut, mode=HOME, coins=500, hearts=5)
    # vlam op volle lengte: HUD blijft erboven, draak eronder
    set_state(dut, fx_on=1, fx_kind=1, fx_age=60)
    assert await px(dut, 44, 60) == 0b010101, "muntbalk moet boven de vlam staan"
    assert await px(dut, 60, 30) in (BLACK, SKY), "levelvak moet boven de vlam staan"
    flame_px = await px(dut, 180, 210)     # net voor de bek, midden van de wig
    assert flame_px in (YELLOW, 0b111000, RED), f"vlam ontbreekt bij de bek: {flame_px:06b}"
    assert await count(dut, "feed_on", range(0, 186, 4), range(126, 295, 4)) > 500
    # water: spat OVER de draak
    set_state(dut, fx_kind=2, fx_age=20)
    assert await px(dut, 44, 220) in (0b010101, YELLOW, BLACK), "muntbalk moet boven het pistool staan"
    n_over_dragon = 0
    for y in range(172, 240, 4):
        for x in range(186, 220, 4):
            v = await px(dut, x, y)
            n_over_dragon += (v == 0b010111 or v == BLACK) and int(dut.water_on.value)
    assert n_over_dragon > 0, "de spat moet over de draak heen steken"
    # evolve-flits: onder de HUD, boven de draak
    set_state(dut, fx_on=0, evo_on=1, evo_r=176, flash=0)
    assert await px(dut, 44, 60) == 0b010101, "HUD moet boven de evolve-flits staan"
    assert await px(dut, 240, 236) == 0b111000, "evolve-flits ontbreekt in het midden van de draak"
    assert await px(dut, 240, 236 + 170) == RED, "rode bies van de flits"


@cocotb.test()
async def test_day_and_night_palette(dut):
    await setup(dut, mode=HOME, hearts=0)
    DAY   = {1: 0b000000, 2: 0b101010, 3: 0b001100, 4: 0b111111, 5: 0b001000, 6: 0b010101, 7: 0b101101}
    NIGHT = {1: 0b000000, 2: 0b010101, 3: 0b000100, 4: 0b101010, 5: 0b000100, 6: 0b010101, 7: 0b000100}
    for night, pal, sun in ((0, DAY, YELLOW), (1, NIGHT, WHITE)):
        set_state(dut, night=night)
        assert await px(dut, 404, 104) == sun, "zon/maan"
        assert await px(dut, 20, 20) == (NIGHT_SKY if night else SKY)
        seen = 0
        for y in range(170, 294, 8):
            for x in range(176, 300, 8):
                v = await px(dut, x, y)
                if int(dut.dragon_on.value):
                    code = int(dut.dragon_code.value)
                    assert v == pal[code], f"night={night} ({x},{y}) code {code}: {v:06b} != {pal[code]:06b}"
                    seen += 1
        assert seen > 20, f"night={night}: bijna geen draakpixels gezien ({seen})"


@cocotb.test()
async def test_night_legibility(dut):
    """
    's Nachts is de lucht zwart.  LVL n wordt altijd zwart getekend en de
    omtrek van een leeg hartje ook: allebei onzichtbaar.  Faalt deze test,
    kies dan in renderer.v een nachtkleur, bv.
        else if (show_coin && lvl_on)  rgb = night ? 6'b11_11_11 : 6'b00_00_00;
    en voor de hartjes-omtrek (heartsinfo_code 0) idem.
    """
    await setup(dut, mode=HOME, night=1, hearts=2, level_shown=3)
    ink = await px(dut, 25, 30)          # de staander van de L
    bg = await px(dut, 24 + 9, 30)       # het gat tussen L en V: lucht
    assert ink != bg, f"'LVL' 's nachts onzichtbaar: inkt {ink:06b} = lucht {bg:06b}"
    tip = await px(dut, 290 + 40 * 4, 47)   # omtrek van een LEEG hartje
    sky = await px(dut, 290 + 40 * 4, 60)
    assert tip != sky, f"lege hartjes 's nachts onzichtbaar: omtrek {tip:06b} = lucht {sky:06b}"


@cocotb.test()
async def test_evolve_flash_only_in_home(dut):
    """
    Na een win loopt de evolve-reeks nog ~1 s door.  Druk je in die tijd op
    een knop, dan sta je op TITLE met evo_on hoog -- en de renderer tekent de
    flits-achthoek over de titelkaart.  Faalt dit, poort de flits op de mode:
        wire [9:0] fl_r = (evo_on && mode == M_HOME) ? evo_r : flash_r;
    """
    await setup(dut, mode=TITLE, evo_on=1, evo_r=100, flash_r=0)
    v = await px(dut, 240, 236)
    assert v in TITLE_COLOURS, f"evolve-flits op het titelscherm: {v:06b}"