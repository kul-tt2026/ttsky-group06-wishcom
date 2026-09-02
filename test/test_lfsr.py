"""
test_lfsr.py -- dual_lfsr.v

Twee 16-bits LFSR's. B schuift alleen door als bit 0 van A hoog staat, zodat
rand_val niet gewoon de framecounter volgt.

Wat hier getest wordt:
  1. resetwaarden en de eerste stap (met de hand narekenbaar)
  2. stilstand zonder frame_tick -- de klok alleen doet niets
  3. exacte gelijkheid met een Python-referentiemodel over 500 ticks
  4. geen van beide registers wordt ooit 0 (dan zou hij voor eeuwig 0 blijven)
  5. rand_val varieert echt: alle 8 waarden komen voor en hij blijft niet hangen

    make test_lfsr
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer

SEED_A, SEED_B = 0xACE1, 0xBED2


# ---------------------------------------------------------------- model ----
def step_a(a):
    fb = ((a >> 15) ^ (a >> 13) ^ (a >> 12) ^ (a >> 10)) & 1
    return ((a << 1) | fb) & 0xFFFF

def step_b(b):
    fb = ((b >> 15) ^ (b >> 14) ^ (b >> 12) ^ (b >> 3)) & 1
    return ((b << 1) | fb) & 0xFFFF

class Model:
    def __init__(self):
        self.a, self.b = SEED_A, SEED_B
    def tick(self):
        # B kijkt naar bit 0 van A VOOR de schuif (non-blocking semantiek)
        if self.a & 1:
            self.b = step_b(self.b)
        self.a = step_a(self.a)
    @property
    def rand_val(self):
        return self.b & 7


# -------------------------------------------------------------- helpers ----
async def setup(dut):
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())
    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

async def tick(dut):
    dut.frame_tick.value = 1
    await RisingEdge(dut.clk)
    dut.frame_tick.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")


# ---------------------------------------------------------------- tests ----
@cocotb.test()
async def test_reset_and_first_step(dut):
    """Resetwaarden en de eerste tick, met de hand na te rekenen."""
    await setup(dut)
    assert int(dut.lfsr_a.value) == SEED_A
    assert int(dut.lfsr_b.value) == SEED_B
    assert int(dut.rand_val.value) == (SEED_B & 7), "rand_val na reset"

    await tick(dut)
    m = Model(); m.tick()
    assert int(dut.lfsr_a.value) == m.a
    assert int(dut.lfsr_b.value) == m.b
    assert int(dut.rand_val.value) == m.rand_val


@cocotb.test()
async def test_no_change_without_frame_tick(dut):
    """Alleen frame_tick schuift; 200 klokken zonder tick veranderen niets."""
    await setup(dut)
    await tick(dut); await tick(dut)
    a, b = int(dut.lfsr_a.value), int(dut.lfsr_b.value)
    await ClockCycles(dut.clk, 200)
    assert int(dut.lfsr_a.value) == a, "lfsr_a bewoog zonder frame_tick"
    assert int(dut.lfsr_b.value) == b, "lfsr_b bewoog zonder frame_tick"


@cocotb.test()
async def test_matches_reference_model(dut):
    """500 ticks exact gelijk aan het Python-model, inclusief de bit-0-koppeling."""
    await setup(dut)
    m = Model()
    for i in range(500):
        await tick(dut)
        m.tick()
        assert int(dut.lfsr_a.value) == m.a, f"tick {i}: lfsr_a wijkt af"
        assert int(dut.lfsr_b.value) == m.b, f"tick {i}: lfsr_b wijkt af"
        assert int(dut.rand_val.value) == m.rand_val, f"tick {i}: rand_val wijkt af"


@cocotb.test()
async def test_never_zero(dut):
    """Een LFSR die op 0 komt blijft op 0. Mag dus nooit gebeuren."""
    await setup(dut)
    for i in range(2000):
        await tick(dut)
        assert int(dut.lfsr_a.value) != 0, f"lfsr_a is 0 na tick {i}"
        assert int(dut.lfsr_b.value) != 0, f"lfsr_b is 0 na tick {i}"


@cocotb.test()
async def test_output_actually_varies(dut):
    """rand_val moet alle 8 waarden halen en mag niet blijven hangen."""
    await setup(dut)
    seen = set()
    longest_run, run, prev = 0, 0, None
    for _ in range(400):
        await tick(dut)
        v = int(dut.rand_val.value)
        seen.add(v)
        run = run + 1 if v == prev else 1
        longest_run = max(longest_run, run)
        prev = v
    assert seen == set(range(8)), f"niet alle waarden gezien: {sorted(seen)}"
    # B schuift maar in de helft van de ticks (alleen als bit 0 van A hoog is),
    # dus herhalingen zijn normaal. Over de VOLLEDIGE periode is de langste
    # herhaling 29 ticks (nagerekend met het model). Voor het spel maakt dat
    # niets uit -- de kist trekt een sample per ronde. Deze grens vangt alleen
    # een echt kapotte LFSR (verkeerde taps, korte cyclus) af.
    assert longest_run <= 32, f"rand_val bleef {longest_run} ticks op dezelfde waarde"