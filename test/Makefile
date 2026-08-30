# Makefile voor Tiny Tapeout (Top-level) + Unit Tests

# Standaard Cocotb instellingen
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src

# Al je projectbestanden (zonder tb.v!)
PROJECT_SOURCES = project.v hvsync_generator.v anim.v balance.v coinbar.v draw_buttons.v hearts.v buttons.v chest_draw.v chest_game.v dragon_draw.v dragon_state.v home.v renderer.v sprites.v satisfactionbar.v dual_lfsr.v chest_menu.v title_card.v title_egg.v icon_draw.v feed_fx.v water_fx.v

# Zet de bronpaden goed
VERILOG_SOURCES = $(addprefix $(SRC_DIR)/, $(PROJECT_SOURCES))

# --- DYNAMISCHE VARIABELEN ---
# Als we niets specificeren, test hij de top-level (tb) en voert hij test.py uit
export TOPLEVEL ?= tb
export MODULE ?= test

# Alleen als we de 'tb' toplevel testen, voegen we de testwrapper (tb.v) toe
ifeq ($(TOPLEVEL),tb)
    VERILOG_SOURCES += $(PWD)/tb.v
endif

# Laad de standaard Cocotb regels in
include $(shell cocotb-config --makefiles)/Makefile.sim


# ==============================================================================
# CUSTOM UNIT TEST TARGETS
# ==============================================================================

# 1. Balance
test_balance:
	$(MAKE) clean
	$(MAKE) TOPLEVEL=balance MODULE=test_balance VERILOG_SOURCES="$(SRC_DIR)/balance.v"

# 2. Chest Game
test_chest:
	$(MAKE) clean
	$(MAKE) TOPLEVEL=chest_game MODULE=test_chest VERILOG_SOURCES="$(SRC_DIR)/chest_game.v"

# 3. LFSR
test_lfsr:
	$(MAKE) clean
	$(MAKE) TOPLEVEL=dual_lfsr MODULE=test_lfsr VERILOG_SOURCES="$(SRC_DIR)/dual_lfsr.v"

# 4. Alles lokaal draaien
test_all:
	@echo "--- STARTING TOP-LEVEL TEST ---"
	$(MAKE) clean
	$(MAKE) TOPLEVEL=tb MODULE=test
	@echo "--- STARTING BALANCE UNIT TEST ---"
	$(MAKE) test_balance
	@echo "--- STARTING CHEST UNIT TEST ---"
	$(MAKE) test_chest
	@echo "--- STARTING LFSR UNIT TEST ---"
	$(MAKE) test_lfsr