#
# Created on Wed Jan 05 2022
#
# Copyright (c) 2022 IOA UCAS
#
# @Filename:	 Makefile
# @Author:		 Jiawei Lin
# @Last edit:	 10:24:40
#

TOPLEVEL_LANG = verilog

SIM ?= icarus
WAVES ?= 1

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT      = match_pipe
TOPLEVEL = $(DUT)
MODULE   = testbench

VERILOG_SOURCES += ../../rtl/$(TOPLEVEL).v
# VERILOG_SOURCES += ../../rtl/match_pipe/$(TOPLEVEL).v
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
export PARAM_I_DATA_WIDTH 		?= 512
export PARAM_I_CHANNEL_WIDTH 	?= 6
export PARAM_I_ERROR_WIDTH 		?= 4
export PARAM_O_DATA_WIDTH 		?= 528
export PARAM_FRACTCAM_ENABLE 	?= 1
export PARAM_TCAM_ADDR_WIDTH 	?= 4
export PARAM_TCAM_DATA_WIDTH 	?= 130
export PARAM_TCAM_WR_WIDTH 		?= 128
export PARAM_TCAM_DEPTH 		?= 16
export PARAM_ACTN_DATA_WIDTH 	?= 48
export PARAM_I_USER_WIDTH		?= 4
export PARAM_O_USER_WIDTH		?= $(PARAM_ACTN_DATA_WIDTH)+$(PARAM_I_USER_WIDTH)

ifeq ($(SIM), icarus)
	PLUSARGS += -fst

	COMPILE_ARGS += -P $(TOPLEVEL).I_DATA_WIDTH=$(PARAM_I_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).I_CHANNEL_WIDTH=$(PARAM_I_CHANNEL_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).I_ERROR_WIDTH=$(PARAM_I_ERROR_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).FRACTCAM_ENABLE=$(PARAM_FRACTCAM_ENABLE)
	COMPILE_ARGS += -P $(TOPLEVEL).TCAM_ADDR_WIDTH=$(PARAM_TCAM_ADDR_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).TCAM_DATA_WIDTH=$(PARAM_TCAM_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).TCAM_WR_WIDTH=$(PARAM_TCAM_WR_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).TCAM_DEPTH=$(PARAM_TCAM_DEPTH)
	COMPILE_ARGS += -P $(TOPLEVEL).ACTN_DATA_WIDTH=$(PARAM_ACTN_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).O_DATA_WIDTH=$(PARAM_O_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).I_USER_WIDTH=$(PARAM_I_USER_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).O_USER_WIDTH=$(PARAM_O_USER_WIDTH)


	ifeq ($(WAVES), 1)
		VERILOG_SOURCES += iverilog_dump.v
		COMPILE_ARGS += -s iverilog_dump
	endif

else ifeq ($(SIM), verilator)
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH

	COMPILE_ARGS += -GIF_COUNT=$(PARAM_IF_COUNT)
	COMPILE_ARGS += -GI_DATA_WIDTH=$(PARAM_I_DATA_WIDTH)
	COMPILE_ARGS += -GI_CHANNEL_WIDTH=$(PARAM_I_CHANNEL_WIDTH)
	COMPILE_ARGS += -GI_ERROR_WIDTH=$(PARAM_I_ERROR_WIDTH)
	COMPILE_ARGS += -GFRACTCAM_ENABLE=$(PARAM_FRACTCAM_ENABLE)
	COMPILE_ARGS += -GTCAM_ADDR_WIDTH=$(PARAM_TCAM_ADDR_WIDTH)
	COMPILE_ARGS += -GTCAM_DATA_WIDTH=$(PARAM_TCAM_DATA_WIDTH)
	COMPILE_ARGS += -GTCAM_WR_WIDTH=$(PARAM_TCAM_WR_WIDTH)
	COMPILE_ARGS += -GTCAM_DEPTH=$(PARAM_TCAM_DEPTH)
	COMPILE_ARGS += -GACTN_DATA_WIDTH=$(PARAM_ACTN_DATA_WIDTH)
	COMPILE_ARGS += -GO_DATA_WIDTH=$(PARAM_O_DATA_WIDTH)
	COMPILE_ARGS += -GI_USER_WIDTH=$(PARAM_I_USER_WIDTH)
	COMPILE_ARGS += -GO_USER_WIDTH=$(PARAM_O_USER_WIDTH)

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
	@rm -rf __pycache__
	@rm -rf *.xml