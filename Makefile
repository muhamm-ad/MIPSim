# MIPSim build system (GHDL)
#
#   make check                 analyse + elaborate every module in hdl_export/
#   make test                  unit testbenches (tb/) + every program in programs/
#   make test T=tb_alu         run a single unit testbench
#   make test-tools            unit tests of the assembler (tools/test_asm.py)
#   make programs              assemble programs/*.s -> programs/*.hex (+ .expect)
#   make sim PROG=programs/gcd run one program and print every store it performs
#   make wave T=tb_alu         run one testbench and dump build/tb_alu.ghw
#   make all                   check + test + test-tools
#   make clean                 remove build artefacts

GHDL      ?= ghdl
PYTHON    ?= python3
STD       ?= 08
BUILD     := build
SRC_DIR   := hdl_export
TB_DIR    := tb
PROG_DIR  := programs
GHDLFLAGS := --std=$(STD) --workdir=$(BUILD)
RUNFLAGS  := --assert-level=error --ieee-asserts=disable-at-0

SRCS      := $(sort $(wildcard $(SRC_DIR)/*.vhd))
TB_FILES  := $(sort $(wildcard $(TB_DIR)/*.vhd))
TBS       := $(sort $(wildcard $(TB_DIR)/tb_*.vhd))
ENTITIES  := $(basename $(notdir $(SRCS)))
# tb_mips is data driven (needs a program): it is run by the programs loop below
ALL_TESTS := $(filter-out tb_mips,$(basename $(notdir $(TBS))))
TESTS     := $(if $(T),$(T),$(ALL_TESTS))
PROG_SRCS := $(sort $(wildcard $(PROG_DIR)/*.s))
PROG_HEX  := $(PROG_SRCS:.s=.hex)

.PHONY: all check test test-tools programs sim wave clean
all: check test test-tools

$(BUILD):
	@mkdir -p $(BUILD)

# Import every file once, then make each design unit so that all of them are
# analysed and elaborated (catches missing ports, bad generics, ...).
check: | $(BUILD)
	@$(GHDL) -i $(GHDLFLAGS) $(SRCS) $(TB_FILES)
	@set -e; for e in $(ENTITIES); do \
	    echo "[check] $$e"; \
	    $(GHDL) -m $(GHDLFLAGS) $$e; \
	done
	@echo "check: all $(words $(ENTITIES)) design units OK"

# Unit testbenches, then (unless a single testbench was requested with T=) every
# program of programs/ run through tb_mips with its expectations.
test: | $(BUILD)
	@set -e; \
	$(GHDL) -i $(GHDLFLAGS) $(SRCS) $(TB_FILES); \
	pass=0; \
	for t in $(TESTS); do \
	    echo "[test] $$t"; \
	    $(GHDL) -m $(GHDLFLAGS) $$t; \
	    $(GHDL) -r $(GHDLFLAGS) $$t $(RUNFLAGS); \
	    pass=$$((pass+1)); \
	done; \
	echo "test: $$pass testbench(es) passed"; \
	if [ -z "$(T)" ] && [ -n "$(PROG_HEX)" ]; then \
	    $(GHDL) -m $(GHDLFLAGS) tb_mips; \
	    progs=0; \
	    for h in $(PROG_HEX); do \
	        e=$${h%.hex}.expect; \
	        echo "[program] $$h"; \
	        if [ -f $$e ]; then eopt="-gEXPECT=$$e"; else eopt=""; fi; \
	        $(GHDL) -r $(GHDLFLAGS) tb_mips -gPROGRAM=$$h $$eopt $(RUNFLAGS); \
	        progs=$$((progs+1)); \
	    done; \
	    echo "test: $$progs program(s) passed"; \
	fi

test-tools:
	@$(PYTHON) -m unittest discover -s tools

# Assemble every program (the generated .hex/.expect files are committed so that
# simulating does not need Python; CI checks they are up to date).
programs:
	@set -e; for s in $(PROG_SRCS); do \
	    echo "[asm] $$s"; \
	    $(PYTHON) tools/asm.py $$s; \
	done

sim: | $(BUILD)
	@test -n "$(PROG)" || { echo "usage: make sim PROG=programs/<name>   (without extension)"; exit 1; }
	@$(PYTHON) tools/asm.py $(PROG).s
	@$(GHDL) -i $(GHDLFLAGS) $(SRCS) $(TB_FILES)
	@$(GHDL) -m $(GHDLFLAGS) tb_mips
	@e=$(PROG).expect; if [ -f $$e ]; then eopt="-gEXPECT=$$e"; else eopt=""; fi; \
	$(GHDL) -r $(GHDLFLAGS) tb_mips -gPROGRAM=$(PROG).hex $$eopt -gVERBOSE=true $(RUNFLAGS)

wave: | $(BUILD)
	@test -n "$(T)" || { echo "usage: make wave T=<testbench>"; exit 1; }
	@$(GHDL) -i $(GHDLFLAGS) $(SRCS) $(TB_FILES)
	@$(GHDL) -m $(GHDLFLAGS) $(T)
	@$(GHDL) -r $(GHDLFLAGS) $(T) $(RUNFLAGS) --wave=$(BUILD)/$(T).ghw
	@echo "waveform written to $(BUILD)/$(T).ghw"

clean:
	rm -rf $(BUILD)
