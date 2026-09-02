"""
test_dragon_state.py -- dragon_state.v

De enige module die hearts, satisfaction, coins en level schrijft. Alles
loopt op frame_tick; verzoeken zijn eenframe-pulsen uit balance, chest_game
en home.

Wat hier getest wordt:
  1. resetwaarden
  2. lege ticks veranderen niets
  3. satisfaction: grenzen 0..4, overflow op 4, en op 0 kost een extra daling een hartje
  4. hearts: grenzen 0..5, overflow op 5, game_over op 0, ook via de kist
  5. coins: optellen, de 999-cap, en overflow precies op de cap
  6. evolve: te weinig munten doet niets; genoeg munten trekt de prijs af en
     verhoogt level; de hele prijstabel; evolve_now; de puls `evolved`
  7. heal_up: alleen de twee transformaties (naar 3 en naar 7) vullen hearts
  8. winnen: op level 7 kost het 999 en zet you_win
  9. gelijktijdige verzoeken in EEN tick: evolve + uitbetaling, gain + lose,
     heal + lose, sat_up + sat_down
 10. game_over en you_win bevriezen alles; alleen restart komt eruit
 11. de overflow-flits duurt precies 120 ticks na het zetten
 12. 3000 ticks willekeurige verzoeken tegen een Python-referentiemodel,
     met tussentijdse restarts

    make test_dragon_state
"""
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer

PRICE = {1: 90, 2: 220, 3: 180, 4: 250, 5: 340, 6: 400, 7: 999}
CAP = 999
REQ = ("req_heart_gain", "req_heart_lose", "req_sat_up", "req_sat_down",
       "req_coins_add", "req_heart_lose_chest", "req_evolve")


# ---------------------------------------------------------------- model ----
class Model:
    """Spiegelt dragon_state.v regel voor regel, met non-blocking semantiek."""
    def reset(self):
        self.hearts, self.sat, self.coins, self.level = 5, 2, 0, 1
        self.game_over = self.you_win = False
        self.overflow, self.timer = False, 0

    def __init__(self):
        self.reset()

    def price(self):
        return PRICE.get(self.level, 999)

    def evolve_now(self):
        return self.coins >= self.price()

    def tick(self, gain=0, lose=0, sat_up=0, sat_down=0, add=0, amount=0,
             lose_chest=0, evolve=0):
        do_evolve = bool(evolve and self.coins >= self.price())
        if self.game_over or self.you_win:
            return do_evolve            # bevroren; `evolved` is wel nog een draad
        # alle beslissingen op de OUDE waarden
        h, s, c, lvl, t, ov = (self.hearts, self.sat, self.coins, self.level,
                               self.timer, self.overflow)
        sat_floor_hit = bool(sat_down and s == 0)
        lose_any = bool(lose or lose_chest or sat_floor_hit)
        heal_up = do_evolve and lvl in (2, 6)
        set_ov = False

        # overflow-timer
        if t != 0:
            self.timer = t - 1
            if t == 1:
                self.overflow = False

        # hearts: een ketting
        if heal_up:
            self.hearts = 5
        elif lose_any:
            if h <= 1:
                self.hearts = 0
                self.game_over = True
            else:
                self.hearts = h - 1
        elif gain:
            if h != 5:
                self.hearts = h + 1
            else:
                set_ov = True

        # satisfaction
        if sat_up:
            if s != 4:
                self.sat = s + 1
            else:
                set_ov = True
        elif sat_down and s != 0:
            self.sat = s - 1

        # coins: evolve en uitbetaling in EEN som
        if do_evolve or add:
            total = (c - self.price() if do_evolve else c) + (amount if add else 0)
            if total >= CAP:
                self.coins = CAP
                set_ov = True
            else:
                self.coins = total

        # level
        if do_evolve:
            if lvl == 7:
                self.you_win = True
            else:
                self.level = lvl + 1

        if set_ov:
            self.overflow, self.timer = True, 120
        return do_evolve


# -------------------------------------------------------------- helpers ----
async def setup(dut):
    cocotb.start_soon(Clock(dut.clk, 40, unit="ns").start())
    dut.rst_n.value = 0
    dut.frame_tick.value = 0
    dut.restart.value = 0
    dut.coins_amount.value = 0
    for r in REQ:
        getattr(dut, r).value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")


async def tick(dut, gain=0, lose=0, sat_up=0, sat_down=0, add=0, amount=0,
               lose_chest=0, evolve=0):
    """Een frame_tick met deze verzoeken. Geeft `evolved` terug zoals anim.v
    het op die tick ziet."""
    dut.req_heart_gain.value = gain
    dut.req_heart_lose.value = lose
    dut.req_sat_up.value = sat_up
    dut.req_sat_down.value = sat_down
    dut.req_coins_add.value = add
    dut.coins_amount.value = amount
    dut.req_heart_lose_chest.value = lose_chest
    dut.req_evolve.value = evolve
    dut.frame_tick.value = 1
    await Timer(1, unit="ns")
    evolved = int(dut.evolved.value)
    await RisingEdge(dut.clk)
    for r in REQ:
        getattr(dut, r).value = 0
    dut.coins_amount.value = 0
    dut.frame_tick.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    return evolved


async def idle(dut, n):
    for _ in range(n):
        await tick(dut)


async def restart(dut):
    dut.restart.value = 1
    await RisingEdge(dut.clk)
    dut.restart.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")


async def give_coins(dut, n):
    """Munten erbij via de kist, in porties zodat we de cap niet raken."""
    while n > 0:
        chunk = min(n, 200)
        await tick(dut, add=1, amount=chunk)
        n -= chunk


def state(dut):
    return dict(hearts=int(dut.hearts.value), sat=int(dut.satisfaction.value),
                coins=int(dut.coins.value), level=int(dut.level.value),
                game_over=int(dut.game_over.value), you_win=int(dut.you_win.value),
                overflow=int(dut.overflow.value), evolve_now=int(dut.evolve_now.value))


def check(dut, **exp):
    s = state(dut)
    for k, v in exp.items():
        assert s[k] == v, f"{k}: kreeg {s[k]}, verwacht {v}   (toestand {s})"


# ---------------------------------------------------------------- tests ----
@cocotb.test()
async def test_reset_values(dut):
    await setup(dut)
    check(dut, hearts=5, sat=2, coins=0, level=1, game_over=0, you_win=0,
          overflow=0, evolve_now=0)


@cocotb.test()
async def test_idle_ticks_change_nothing(dut):
    await setup(dut)
    before = state(dut)
    await idle(dut, 200)
    assert state(dut) == before


@cocotb.test()
async def test_satisfaction_bounds(dut):
    await setup(dut)
    await tick(dut, sat_up=1); check(dut, sat=3, overflow=0)
    await tick(dut, sat_up=1); check(dut, sat=4, overflow=0)
    await tick(dut, sat_up=1); check(dut, sat=4, overflow=1, hearts=5)
    for exp in (3, 2, 1, 0):
        await tick(dut, sat_down=1); check(dut, sat=exp, hearts=5)
    # op 0: nog een daling kost een hartje, sat blijft 0
    await tick(dut, sat_down=1); check(dut, sat=0, hearts=4)
    await tick(dut, sat_down=1); check(dut, sat=0, hearts=3)


@cocotb.test()
async def test_heart_bounds_and_game_over(dut):
    await setup(dut)
    await tick(dut, gain=1); check(dut, hearts=5, overflow=1)
    await tick(dut, lose=1); check(dut, hearts=4, game_over=0)
    await tick(dut, gain=1); check(dut, hearts=5)
    for exp in (4, 3, 2, 1):
        await tick(dut, lose=1); check(dut, hearts=exp, game_over=0)
    await tick(dut, lose=1); check(dut, hearts=0, game_over=1)


@cocotb.test()
async def test_chest_heart_loss_counts_the_same(dut):
    await setup(dut)
    await tick(dut, lose_chest=1); check(dut, hearts=4)
    for _ in range(3):
        await tick(dut, lose_chest=1)
    check(dut, hearts=1, game_over=0)
    await tick(dut, lose_chest=1); check(dut, hearts=0, game_over=1)


@cocotb.test()
async def test_coins_add_and_cap(dut):
    await setup(dut)
    await tick(dut, add=1, amount=40);  check(dut, coins=40, overflow=0)
    await tick(dut, add=1, amount=160); check(dut, coins=200, overflow=0)
    await tick(dut, add=1, amount=798); check(dut, coins=998, overflow=0)
    # precies op de cap telt al als overflow (>= 999)
    await tick(dut, add=1, amount=1);   check(dut, coins=999, overflow=1)
    await tick(dut, add=1, amount=500); check(dut, coins=999, overflow=1)


@cocotb.test()
async def test_evolve_needs_the_money(dut):
    await setup(dut)
    await give_coins(dut, 89)
    check(dut, evolve_now=0)
    ev = await tick(dut, evolve=1)
    assert ev == 0, "evolved mag niet pulsen zonder geld"
    check(dut, level=1, coins=89)

    await tick(dut, add=1, amount=1)
    check(dut, coins=90, evolve_now=1)
    ev = await tick(dut, evolve=1)
    assert ev == 1, "evolved moet pulsen op de tick van de evolutie"
    check(dut, level=2, coins=0, evolve_now=0)


@cocotb.test()
async def test_full_price_table(dut):
    """Elke stap kost exact wat de tabel zegt, en level 1..7 loopt netjes op."""
    await setup(dut)
    for lvl in range(1, 7):
        check(dut, level=lvl, coins=0)
        await give_coins(dut, PRICE[lvl] - 1)
        check(dut, evolve_now=0)
        await tick(dut, evolve=1)                 # een munt te weinig
        check(dut, level=lvl, coins=PRICE[lvl] - 1)
        await tick(dut, add=1, amount=1)
        check(dut, evolve_now=1)
        await tick(dut, evolve=1)                 # precies genoeg
        check(dut, level=lvl + 1, coins=0, you_win=0)
    check(dut, level=7)


@cocotb.test()
async def test_heal_only_on_transformations(dut):
    """Naar level 3 en naar level 7 vult hearts. De andere stappen niet."""
    await setup(dut)
    await tick(dut, lose=1); await tick(dut, lose=1)
    check(dut, hearts=3, level=1)

    await give_coins(dut, PRICE[1]); await tick(dut, evolve=1)
    check(dut, level=2, hearts=3)             # 1 -> 2: geen heal

    await give_coins(dut, PRICE[2]); await tick(dut, evolve=1)
    check(dut, level=3, hearts=5)             # 2 -> 3: transformatie, heal

    await tick(dut, lose=1); await tick(dut, lose=1); await tick(dut, lose=1)
    check(dut, hearts=2)
    for lvl in (3, 4, 5):
        await give_coins(dut, PRICE[lvl]); await tick(dut, evolve=1)
        check(dut, level=lvl + 1, hearts=2)   # 3->4, 4->5, 5->6: geen heal

    await give_coins(dut, PRICE[6]); await tick(dut, evolve=1)
    check(dut, level=7, hearts=5)             # 6 -> 7: transformatie, heal


@cocotb.test()
async def test_win_costs_999_and_freezes(dut):
    await setup(dut)
    for lvl in range(1, 7):
        await give_coins(dut, PRICE[lvl]); await tick(dut, evolve=1)
    check(dut, level=7, coins=0, you_win=0)

    await give_coins(dut, 998)
    check(dut, coins=998, evolve_now=0)
    await tick(dut, evolve=1)
    check(dut, you_win=0, level=7, coins=998)   # 998 is niet genoeg

    await tick(dut, add=1, amount=1)
    check(dut, coins=999, evolve_now=1)
    ev = await tick(dut, evolve=1)
    assert ev == 1
    check(dut, you_win=1, level=7, coins=0)

    # bevroren: niets doet nog iets, behalve restart
    frozen = state(dut)
    await tick(dut, lose=1, sat_down=1, add=1, amount=500)
    assert state(dut) == frozen, "na you_win mag niets meer veranderen"
    await restart(dut)
    check(dut, hearts=5, sat=2, coins=0, level=1, you_win=0)


@cocotb.test()
async def test_game_over_freezes_until_restart(dut):
    await setup(dut)
    for _ in range(5):
        await tick(dut, lose=1)
    check(dut, hearts=0, game_over=1)
    frozen = state(dut)
    await tick(dut, gain=1, sat_up=1, add=1, amount=100)
    assert state(dut) == frozen, "na game_over mag niets meer veranderen"
    await idle(dut, 50)
    assert state(dut) == frozen
    await restart(dut)
    check(dut, hearts=5, sat=2, coins=0, level=1, game_over=0, overflow=0)


@cocotb.test()
async def test_same_tick_evolve_and_payout(dut):
    """Uit de kist komen met winst en op dezelfde tick evolven: beide tellen."""
    await setup(dut)
    await give_coins(dut, 250)
    await tick(dut, evolve=1, add=1, amount=100)
    check(dut, level=2, coins=250 - 90 + 100)


@cocotb.test()
async def test_same_tick_heart_conflicts(dut):
    await setup(dut)
    # gain + lose: lose wint (staat eerder in de ketting)
    await tick(dut, gain=1, lose=1); check(dut, hearts=4)
    # heal + lose: heal wint
    await tick(dut, lose=1); check(dut, hearts=3)
    await give_coins(dut, PRICE[1]); await tick(dut, evolve=1)      # -> 2
    await give_coins(dut, PRICE[2])
    await tick(dut, evolve=1, lose=1)
    check(dut, level=3, hearts=5)
    # sat_up + sat_down: up wint
    await tick(dut, sat_up=1, sat_down=1); check(dut, sat=3)


@cocotb.test()
async def test_overflow_flash_length(dut):
    """overflow gaat hoog en na precies 120 lege ticks weer laag."""
    await setup(dut)
    await tick(dut, gain=1)
    check(dut, overflow=1)
    await idle(dut, 119)
    check(dut, overflow=1)
    await idle(dut, 1)
    check(dut, overflow=0)
    # opnieuw triggeren halverwege herstart de timer op 120
    await tick(dut, gain=1); await idle(dut, 60)
    await tick(dut, gain=1); await idle(dut, 119)
    check(dut, overflow=1)
    await idle(dut, 1)
    check(dut, overflow=0)


@cocotb.test()
async def test_random_against_model(dut):
    """3000 ticks willekeurige verzoeken, met restarts, exact tegen het model."""
    await setup(dut)
    rng = random.Random(6)     # groep 06; vaste seed = herhaalbaar
    m = Model()
    for i in range(3000):
        if rng.random() < 0.01:
            await restart(dut)
            m.reset()
        kw = dict(
            gain=int(rng.random() < 0.15), lose=int(rng.random() < 0.08),
            sat_up=int(rng.random() < 0.15), sat_down=int(rng.random() < 0.15),
            add=int(rng.random() < 0.20), amount=rng.choice([0, 40, 60, 100, 160, 320, 640, 999]),
            lose_chest=int(rng.random() < 0.04), evolve=int(rng.random() < 0.20),
        )
        exp_ev = m.tick(**kw)
        got_ev = await tick(dut, **kw)
        assert got_ev == exp_ev, f"tick {i}: evolved {got_ev} != {exp_ev}  {kw}"
        s = state(dut)
        exp = dict(hearts=m.hearts, sat=m.sat, coins=m.coins, level=m.level,
                   game_over=int(m.game_over), you_win=int(m.you_win),
                   overflow=int(m.overflow), evolve_now=int(m.evolve_now()))
        assert s == exp, f"tick {i}: {kw}\n  dut   {s}\n  model {exp}"