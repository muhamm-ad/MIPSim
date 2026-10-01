# MIPSim build system (GHDL)
#
#   make check            analyse + elaborate every module in hdl_export/
#   make test             run every self-checking testbench in tb/
#   make test T=tb_alu    run a single testbench
#   make wave T=tb_alu    run one testbench and dump build/tb_alu.ghw
#   make all              check + test
#   make clean            remove build artefacts

GHDL      ?= ghdl
STD       ?= 08
BUILD     := build
SRC_DIR   := hdl_export
TB_DIR    := tb
GHDLFLAGS := --std=$(STD) --workdir=$(BUILD)

SRCS    := $(sort $(wildcard $(SRC_DIR)/*.vhd))
TBS     := $(sort $(wildcard $(TB_DIR)/tb_*.vhd))
ENTITIES := $(basename $(notdir $(SRCS)))
ALL_TESTS := $(basename $(notdir $(TBS)))
TESTS   := $(if $(T),$(T),$(ALL_TESTS))

.PHONY: all check test wave clean
all: check test

$(BUILD):
	@mkdir -p $(BUILD)

# Import every file once, then make each design unit so that all of them are
# analysed and elaborated (catches missing ports, bad generics, ...).
check: | $(BUILD)
	@$(GHDL) -i $(GHDLFLAGS) $(SRCS) $(TBS)
	@set -e; for e in $(ENTITIES); do \
	    echo "[check] $$e"; \
	    $(GHDL) -m $(GHDLFLAGS) $$e; \
	done
	@echo "check: all $(words $(ENTITIES)) design units OK"

test: | $(BUILD)
	@set -e; \
	if [ -z "$(TESTS)" ]; then \
	    echo "test: no testbench found in $(TB_DIR)/"; \
	else \
	    $(GHDL) -i $(GHDLFLAGS) $(SRCS) $(TBS); \
	    pass=0; \
	    for t in $(TESTS); do \
	        echo "[test] $$t"; \
	        $(GHDL) -m $(GHDLFLAGS) $$t; \
	        $(GHDL) -r $(GHDLFLAGS) $$t --assert-level=error; \
	        pass=$$((pass+1)); \
	    done; \
	    echo "test: $$pass testbench(es) passed"; \
	fi

wave: | $(BUILD)
	@test -n "$(T)" || { echo "usage: make wave T=<testbench>"; exit 1; }
	@$(GHDL) -i $(GHDLFLAGS) $(SRCS) $(TBS)
	@$(GHDL) -m $(GHDLFLAGS) $(T)
	@$(GHDL) -r $(GHDLFLAGS) $(T) --assert-level=error --wave=$(BUILD)/$(T).ghw
	@echo "waveform written to $(BUILD)/$(T).ghw"

clean:
	rm -rf $(BUILD)
