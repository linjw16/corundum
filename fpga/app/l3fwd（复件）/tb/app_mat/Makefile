# 
# Created on Tue Mar 01 2022
# 
# Copyright (c) 2022 IOA UCAS
# 
# @Filename:	 Makefile
# @Author:		 Jiawei Lin
# @Last edit:	 08:40:21
# 

TOPLEVEL_LANG = verilog

SIM ?= icarus
WAVES ?= 0

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT      = app_mat
TOPLEVEL = $(DUT)
MODULE   = testbench

VERILOG_SOURCES += ../../rtl/$(DUT).v
VERILOG_SOURCES += ../../lib/avst/rtl/avst_fifo.v
VERILOG_SOURCES += ../../lib/avst/rtl/avst_mux.v
VERILOG_SOURCES += ../../lib/axis/rtl/axis_fifo.v
VERILOG_SOURCES += ../../lib/axis/rtl/priority_encoder.v
VERILOG_SOURCES += ../../lib/pcie/rtl/dma_psdpram.v
# FracTCAM
VERILOG_SOURCES += ../../lib/fractcam/tb/fractcam/fractcam_top.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/fractcam/async_demux.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/fractcam/update_logic.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/fractcam/fractcam.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/fractcam/fractcam8x5.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/fractcam/and0.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/fractcam/and6.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/fractcam/andD6slice.v
# FracTCAM sim
VERILOG_SOURCES += ../../lib/fractcam/rtl/sim/FDRE.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/sim/LUT6.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/sim/RAM32M.v
VERILOG_SOURCES += ../../lib/fractcam/rtl/sim/SRLC32E.v
## Match Pipeline
VERILOG_SOURCES += ../../rtl/match_pipe.v
## Action Pipeline
VERILOG_SOURCES += ../../rtl/action_pipe/action_pipe.v
# VERILOG_SOURCES += ../../rtl/action_pipe/hdr_csum_async.v
# VERILOG_SOURCES += ../../rtl/action_pipe/hdr_checksum.v
VERILOG_SOURCES += ../../rtl/action_pipe/hdr_csum.v
VERILOG_SOURCES += ../../rtl/action_pipe/set_field.v
VERILOG_SOURCES += ../../rtl/action_pipe/set_field_async.v
VERILOG_SOURCES += ../../rtl/action_pipe/vlan_op.v
## Parser, deparser 
VERILOG_SOURCES += ../../rtl/parser.v
VERILOG_SOURCES += ../../rtl/deparser.v
## Xilinx TCAM
# VHDL_SOURCES    = ../../rtl/match_pipe/cam_wrapper.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_control.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_mem_blk_extdepth.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_pkg.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_decoder.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_mem_blk.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_regouts.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_init_file_pack_xst.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16_block.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_rtl.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_input_ternary_ternenc.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16_block_word.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_top.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_input_ternary.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16_ternwrcomp.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_input.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/dmem.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_match_enc.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16_wrcomp.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_mem_blk_extdepth_prim.vhd
# VHDL_SOURCES    += ../../lib/xapp1151_cam/src/vhdl/cam_mem.vhd

# module parameters
export PARAM_AVST_DATA_WIDTH				?= 512
export PARAM_AVST_EMPTY_WIDTH				?= 7
export PARAM_AVST_CHANNEL_WIDTH				?= 6
export PARAM_AVST_ERROR_WIDTH				?= 1
export PARAM_dataBitsPerSymbol				?= 8
export PARAM_AVMM_DATA_WIDTH					?= 32
export PARAM_AVMM_STRB_WIDTH					?= 4
export PARAM_AVMM_ADDR_WIDTH					?= 16

ifeq ($(SIM), icarus)
	PLUSARGS += -fst
	
	COMPILE_ARGS += -P $(TOPLEVEL).AVST_DATA_WIDTH=$(PARAM_AVST_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AVST_EMPTY_WIDTH=$(PARAM_AVST_EMPTY_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AVST_CHANNEL_WIDTH=$(PARAM_AVST_CHANNEL_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AVST_ERROR_WIDTH=$(PARAM_AVST_ERROR_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).dataBitsPerSymbol=$(PARAM_dataBitsPerSymbol)
	COMPILE_ARGS += -P $(TOPLEVEL).AVMM_DATA_WIDTH=$(PARAM_AVMM_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AVMM_STRB_WIDTH=$(PARAM_AVMM_STRB_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AVMM_ADDR_WIDTH=$(PARAM_AVMM_ADDR_WIDTH)

	ifeq ($(WAVES), 1)
		VERILOG_SOURCES += iverilog_dump.v
		COMPILE_ARGS += -s iverilog_dump
	endif

else ifeq ($(SIM), verilator)
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH

	COMPILE_ARGS += -GAVST_DATA_WIDTH=$(PARAM_AVST_DATA_WIDTH)
	COMPILE_ARGS += -GAVST_EMPTY_WIDTH=$(PARAM_AVST_EMPTY_WIDTH)
	COMPILE_ARGS += -GAVST_CHANNEL_WIDTH=$(PARAM_AVST_CHANNEL_WIDTH)
	COMPILE_ARGS += -GAVST_ERROR_WIDTH=$(PARAM_AVST_ERROR_WIDTH)
	COMPILE_ARGS += -GdataBitsPerSymbol=$(PARAM_dataBitsPerSymbol)
	COMPILE_ARGS += -GAVMM_DATA_WIDTH=$(PARAM_AVMM_DATA_WIDTH)
	COMPILE_ARGS += -GAVMM_STRB_WIDTH=$(PARAM_AVMM_STRB_WIDTH)
	COMPILE_ARGS += -GAVMM_ADDR_WIDTH=$(PARAM_AVMM_ADDR_WIDTH)

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
	echo '    $$dumpfile("$(TOPLEVEL).fst");' >> $@
	echo '    $$dumpvars(0, $(TOPLEVEL));' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	@rm -rf iverilog_dump.v
	@rm -rf dump.fst $(TOPLEVEL).fst
	@rm -rf *.xml
	@rm -rf __pycache__