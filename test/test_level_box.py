"""
test_level_box.py -- level_box (in sprites.v)

"LVL n" linksboven.  De letters zijn een vaste 3x5-bitmap, het cijfer komt
via q_digit/q_row uit de gedeelde digit_rom.

Wat hier getest wordt:
  1. q_digit == level, voor 1..7.  Zie de docstring bij die test.
  2. q_on alleen in het cijfervak (x 36..47, y 0..17), q_row = y / 3
  3. de letters L V L staan er, pixel voor pixel tegen een 3x5-model
  4. buiten het vak is alles uit, ook via de wrap boven/links

    make test_level_box
"""
import cocotb
from cocotb.triggers import Timer

L = ["100", "100", "100", "100", "111"]
V = ["101", "101", "101", "101", "010"]
LETTERS = [(0, L), (11, V), (22, L)]          # x-offset, bitmap; y vanaf 2, schaal 3


def letter_model(x, y):
    if not (2 <= y < 17):
        return 0
    for x0, bm in LETTERS:
        if x0 <= x < x0 + 9:
            return int(bm[(y - 2) // 3][(x - x0) // 3])
    return 0


async def px(dut, x, y, level=1, q_bits=0):
    dut.x.value, dut.y.value = x, y
    dut.level.value, dut.q_bits.value = level, q_bits
    await Timer(1, unit="ns")
    return int(dut.on.value)


@cocotb.test()
async def test_digit_is_level(dut):
    """
    Het spel begint op level 1 en eindigt op 7; dat moet het scherm ook
    tonen.  Faalt dit met 'kreeg 2' bij level 1, dan staat er in sprites.v
    nog een + 4'd1 uit de tijd dat level op 0 begon:
        assign q_digit = {1'b0, level} + 4'd1;   ->   assign q_digit = {1'b0, level};
    """
    for lvl in range(1, 8):
        await px(dut, 40, 8, level=lvl)
        got = int(dut.q_digit.value)
        assert got == lvl, f"level {lvl}: q_digit is {got}"


@cocotb.test()
async def test_digit_box_and_row(dut):
    for y in range(0, 24):
        for x in range(30, 52):
            await px(dut, x, y, level=3, q_bits=0xF)
            inside = 36 <= x < 48 and y < 18
            assert int(dut.q_on.value) == int(inside), f"q_on op ({x},{y})"
            exp_on = int(inside or letter_model(x, y))   # x=30 is nog de laatste L
            assert int(dut.on.value) == exp_on, f"aan/uit op ({x},{y})"
            if inside:
                assert int(dut.q_row.value) == y // 3, f"q_row op y={y}"
    # alleen kolom 0 van het font aan -> alleen x 36..38
    for x in range(36, 48):
        on = await px(dut, x, 8, level=3, q_bits=0b1000)
        assert on == int(x < 39), f"fontkolom-mapping op x={x}"


@cocotb.test()
async def test_lvl_letters(dut):
    for y in range(0, 20):
        for x in range(0, 36):
            on = await px(dut, x, y, level=1, q_bits=0)
            assert on == letter_model(x, y), f"LVL-letter op ({x},{y}): {on}"


@cocotb.test()
async def test_outside_is_off(dut):
    for x, y in ((48, 5), (100, 5), (10, 18), (10, 100), (1023, 5), (10, 1023), (1023, 1023)):
        assert await px(dut, x, y, level=7, q_bits=0xF) == 0, f"({x},{y}) is aan"
        assert int(dut.q_on.value) == 0