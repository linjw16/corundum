# 
# Created on Fri Mar 04 2022
# 
# Copyright (c) 2022 IOA UCAS
# 
# @Filename:	 Makefile
# @Author:		 Jiawei Lin
# @Last edit:	 16:15:26
# 

TOPLEVEL_LANG = verilog

SIM ?= icarus
WAVES ?= 0

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT      = app_top
TOPLEVEL = $(DUT)
MODULE   = testbench

VERILOG_SOURCES += ../../rtl/$(DUT).v
VERILOG_SOURCES += ../../rtl/app_mat.v
VERILOG_SOURCES += ../../lib/avst/rtl/avst_mux.v
VERILOG_SOURCES += ../../lib/avst/rtl/avst_fifo.v
VERILOG_SOURCES += ../../lib/axis/rtl/axis_fifo.v
VERILOG_SOURCES += ../../lib/axis/rtl/priority_encoder.v
VERILOG_SOURCES += ../../lib/pcie/rtl/dma_psdpram.v
# Bus wrapper
VERILOG_SOURCES += ../../lib/bus_wrapper/rtl/axis_to_avst.v
VERILOG_SOURCES += ../../lib/bus_wrapper/rtl/avst_to_axis.v
VERILOG_SOURCES += ../../lib/bus_wrapper/rtl/axil_to_avmm.v
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
# SRL16E-based TCAM IP
# VHDL_SOURCES += ../../rtl/match_pipe/cam_wrapper.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_control.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_mem_blk_extdepth.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_pkg.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_decoder.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_mem_blk.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_regouts.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_init_file_pack_xst.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16_block.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_rtl.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_input_ternary_ternenc.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16_block_word.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_top.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_input_ternary.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16_ternwrcomp.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_input.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/dmem.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_match_enc.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_mem_srl16_wrcomp.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_mem_blk_extdepth_prim.vhd
# VHDL_SOURCES += ../../lib/xapp1151_cam/src/vhdl/cam_mem.vhd

# module parameters
export PARAM_AXIS_DATA_WIDTH	 ?= 512
export PARAM_AXIS_KEEP_ENABLE	 ?= 1
export PARAM_AXIS_KEEP_WIDTH	 ?= $(shell python -c "print(int($(PARAM_AXIS_DATA_WIDTH)/8))")
export PARAM_AXIS_ID_ENABLE		 ?= 1
export PARAM_AXIS_ID_WIDTH		 ?= 8
export PARAM_AXIS_DEST_ENABLE	 ?= 1
export PARAM_AXIS_DEST_WIDTH	 ?= 8
export PARAM_AXIS_USER_ENABLE	 ?= 1
export PARAM_AXIS_USER_WIDTH	 ?= 128
export PARAM_AXIS_LAST_ENABLE	 ?= 1
export PARAM_AXIL_DATA_WIDTH	 ?= 32
export PARAM_AXIL_ADDR_WIDTH	 ?= 10
export PARAM_AXIL_STRB_WIDTH	 ?= 4

ifeq ($(SIM), icarus)
	PLUSARGS += -fst

	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_DATA_WIDTH=$(PARAM_AXIS_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_KEEP_ENABLE=$(PARAM_AXIS_KEEP_ENABLE)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_KEEP_WIDTH=$(PARAM_AXIS_KEEP_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_ID_ENABLE=$(PARAM_AXIS_ID_ENABLE)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_ID_WIDTH=$(PARAM_AXIS_ID_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_DEST_ENABLE=$(PARAM_AXIS_DEST_ENABLE)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_DEST_WIDTH=$(PARAM_AXIS_DEST_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_USER_ENABLE=$(PARAM_AXIS_USER_ENABLE)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_USER_WIDTH=$(PARAM_AXIS_USER_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIS_LAST_ENABLE=$(PARAM_AXIS_LAST_ENABLE)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIL_DATA_WIDTH=$(PARAM_AXIL_DATA_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIL_ADDR_WIDTH=$(PARAM_AXIL_ADDR_WIDTH)
	COMPILE_ARGS += -P $(TOPLEVEL).AXIL_STRB_WIDTH=$(PARAM_AXIL_STRB_WIDTH)

	ifeq ($(WAVES), 1)
		VERILOG_SOURCES += iverilog_dump.v
		COMPILE_ARGS += -s iverilog_dump
	endif
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH

	COMPILE_ARGS += -GDATA_WIDTH=$(PARAM_DATA_WIDTH)
	COMPILE_ARGS += -GKEEP_ENABLE=$(PARAM_KEEP_ENABLE)
	COMPILE_ARGS += -GKEEP_WIDTH=$(PARAM_KEEP_WIDTH)
	COMPILE_ARGS += -GID_ENABLE=$(PARAM_ID_ENABLE)
	COMPILE_ARGS += -GID_WIDTH=$(PARAM_ID_WIDTH)
	COMPILE_ARGS += -GDEST_ENABLE=$(PARAM_DEST_ENABLE)
	COMPILE_ARGS += -GDEST_WIDTH=$(PARAM_DEST_WIDTH)
	COMPILE_ARGS += -GUSER_ENABLE=$(PARAM_USER_ENABLE)
	COMPILE_ARGS += -GUSER_WIDTH=$(PARAM_USER_WIDTH)
	COMPILE_ARGS += -GLAST_ENABLE=$(PARAM_LAST_ENABLE)
	COMPILE_ARGS += -GAXIL_DATA_WIDTH=$(PARAM_AXIL_DATA_WIDTH)
	COMPILE_ARGS += -GAXIL_ADDR_WIDTH=$(PARAM_AXIL_ADDR_WIDTH)
	COMPILE_ARGS += -GAXIL_STRB_WIDTH=$(PARAM_AXIL_STRB_WIDTH)

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