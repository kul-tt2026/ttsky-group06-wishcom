# Makefile voor Tiny Tapeout (top-level) + unit tests per module
#
#   make test_top   top-level test (tb.v + test.py) -- dit is wat de TT-CI draait
#   make test_core  de snelle kern: ~3 minuten, vangt alles wat we gevonden hebben
#   make test_all   alles, inclusief de top-level (~10 min, vooral door de FST-dump)
#   make test_<x>   een unit test apart
#
# LET OP: een kale `make` hergebruikt sim_build/ van de vorige run.  Na een
# unit test staat daar de verkeerde toplevel in ("tb != renderer").  Gebruik
# dan `make -B`, of gewoon `make test_top`, dat ruimt eerst op.

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src

# Alle projectbestanden (zonder tb.v!). Houd gelijk met source_files in info.yaml.
PROJECT_SOURCES = project.v hvsync_generator.v anim.v balance.v coinbar.v draw_buttons.v hearts.v buttons.v chest_draw.v chest_game.v dragon_draw.v dragon_state.v home.v renderer.v sprites.v satisfactionbar.v dual_lfsr.v chest_menu.v title_card.v title_egg.v icon_draw.v feed_fx.v water_fx.v

VERILOG_SOURCES = $(addprefix $(SRC_DIR)/, $(PROJECT_SOURCES))

export COCOTB_TOPLEVEL ?= tb
export COCOTB_TEST_MODULES ?= test

ifeq ($(COCOTB_TOPLEVEL),tb)
    VERILOG_SOURCES += $(PWD)/tb.v
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

# ==============================================================================
# UNIT TESTS.  `unit` doet clean + run met alleen de bronnen die de module
# nodig heeft:  $(1) = TOPLEVEL   $(2) = MODULE (python, zonder .py)
#               $(3) = bronbestanden in src/
# ==============================================================================
define unit
	$(MAKE) clean
	$(MAKE) COCOTB_TOPLEVEL=$(1) COCOTB_TEST_MODULES=$(2) VERILOG_SOURCES="$(addprefix $(SRC_DIR)/,$(3))"
endef

# De top-level, met een schone sim_build/ zodat hij nooit een oude toplevel pakt.
test_top:
	$(MAKE) clean
	$(MAKE) COCOTB_TOPLEVEL=tb COCOTB_TEST_MODULES=test

# de renderer met alle tekenmodules eronder, tegen de echte sprites en .hex
RENDER_SOURCES = renderer.v title_card.v title_egg.v dragon_draw.v sprites.v chest_draw.v icon_draw.v \
                 chest_menu.v satisfactionbar.v coinbar.v hearts.v draw_buttons.v feed_fx.v water_fx.v

test_hvsync:
	$(call unit,hvsync_generator,test_hvsync,hvsync_generator.v)

test_renderer:
	$(call unit,renderer,test_renderer,$(RENDER_SOURCES))

test_home:
	$(call unit,home,test_home,home.v)

test_dragon_state:
	$(call unit,dragon_state,test_dragon_state,dragon_state.v)

test_anim:
	$(call unit,anim,test_anim,anim.v)

test_level_box:
	$(call unit,level_box,test_level_box,sprites.v)

test_lfsr:
	$(call unit,dual_lfsr,test_lfsr,dual_lfsr.v)

test_balance:
	$(call unit,balance,test_balance,balance.v)

test_chest:
	$(call unit,chest_game,test_chest,chest_game.v dual_lfsr.v)

# De snelle kern voor lokaal itereren.  Stopt bij de eerste fout.
test_core:
	@for t in hvsync home dragon_state anim level_box lfsr balance chest renderer; do \
	  echo "=== UNIT: $$t ==="; $(MAKE) test_$$t || exit 1; done

# Alles: eerst de kern, dan de top-level (die duurt het langst).
test_all: test_core
	@echo "=== TOP-LEVEL ==="
	$(MAKE) test_top

.PHONY: test_top test_hvsync test_renderer test_home test_dragon_state test_anim test_level_box \
        test_lfsr test_balance test_chest test_core test_all