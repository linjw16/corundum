#
# Created on Tue Feb 22 2022
#
# Copyright (c) 2022 IOA UCAS
#
# @Filename:	 testbench.py
# @Author:		 Jiawei Lin
# @Last edit:	 09:04:13
#

TOPLEVEL_LANG = verilog

SIM ?= icarus
WAVES ?= 1

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT = action_pipe
TOPLEVEL = $(DUT)
MODULE = testbench

VERILOG_SOURCES += ../../rtl/action_pipe/$(DUT).v
# VERILOG_SOURCES += ../../rtl/action_pipe/hdr_csum_async.v
# VERILOG_SOURCES += ../../rtl/action_pipe/hdr_checksum.v
VERILOG_SOURCES += ../../rtl/action_pipe/hdr_csum.v
VERILOG_SOURCES += ../../rtl/action_pipe/set_field.v
VERILOG_SOURCES += ../../rtl/action_pipe/set_field_async.v
VERILOG_SOURCES += ../../rtl/action_pipe/vlan_op.v
VERILOG_SOURCES += ../../lib/avst/rtl/avst_mux.v
# VERILOG_SOURCES += ../../rtl/action_pipe/deparser.v

export PARAM_ACTN_DATA_WIDTH ?= 128
export PARAM_I_DATA_WIDTH ?= 600
export PARAM_O_DATA_WIDTH ?= 1024

ifeq ($(SIM), icarus)
	PLUSARGS += -fst

	COMPILE_ARGS += -P $(TOPLEVEL).ACTN_DATA_WIDTH=$(PARAM_ACTN_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).I_DATA_WIDTH=$(PARAM_I_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).O_DATA_WIDTH=$(PARAM_O_DATA_WIDTH)

	ifeq ($(WAVES), 1)
		VERILOG_SOURCES += iverilog_dump.v
		COMPILE_ARGS += -s iverilog_dump
	endif
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH

	COMPILE_ARGS += -GACTN_DATA_WIDTH=$(PARAM_ACTN_DATA_WIDTH)
	COMPILE_ARGS += -GI_DATA_WIDTH=$(PARAM_I_DATA_WIDTH)
	COMPILE_ARGS += -GO_DATA_WIDTH=$(PARAM_O_DATA_WIDTH)
	
	# COMPILE_ARGS += -I $(HEADER_FILES)

	ifeq ($(WAVES), 1)
		COMPILE_ARGS += --trace-fst
	endif
endif

ifneq ($(filter $(SIM),ius xcelium),)
	SIM_ARGS += -v93
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '	$$dumpfile("$(TOPLEVEL).fst");' >> $@
	echo '	$$dumpvars(0, $(TOPLEVEL));' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	@rm -rf iverilog_dump.v
	@rm -rf dump.fst $(TOPLEVEL).fst
	@rm -rf *.xml
	@rm -rf __pycache__