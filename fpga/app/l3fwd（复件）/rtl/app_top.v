/*
 * Created on Wed Jan 05 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 app_top.v
 * @Author:		 Jiawei Lin
 * @Last edit:	 19:38:26
 */

// Language: Verilog 2001

/* verilator lint_off PINMISSING */
/* verilator lint_off LITENDIAN */
`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Application top interface
 */
module app_top #(
	parameter AXIS_DATA_WIDTH	 = 512,
	parameter AXIS_KEEP_ENABLE	 = 1,
	parameter AXIS_KEEP_WIDTH	 = AXIS_DATA_WIDTH/8,
	parameter AXIS_ID_ENABLE	 = 1,
	parameter AXIS_ID_WIDTH		 = 8,
	parameter AXIS_DEST_ENABLE	 = 1,
	parameter AXIS_DEST_WIDTH	 = 4,
	parameter AXIS_USER_ENABLE	 = 1,
	parameter AXIS_USER_WIDTH	 = 128,
	parameter AXIS_LAST_ENABLE	 = 1,
	parameter AXIL_ADDR_WIDTH	 = 16,
	parameter AXIL_DATA_WIDTH	 = 32,
	parameter AXIL_STRB_WIDTH	 = AXIL_DATA_WIDTH/8
) (
	input  wire clk,
	input  wire rst,

	input  wire [AXIS_DATA_WIDTH-1:0] 			s_axis_rx_tdata,
	input  wire [AXIS_KEEP_WIDTH-1:0] 			s_axis_rx_tkeep,
	input  wire 								s_axis_rx_tvalid,
	output wire 								s_axis_rx_tready,
	input  wire 								s_axis_rx_tlast,
	input  wire [AXIS_ID_WIDTH-1:0] 			s_axis_rx_tid,
	input  wire [AXIS_DEST_WIDTH-1:0] 			s_axis_rx_tdest,
	input  wire [AXIS_USER_WIDTH-1:0] 			s_axis_rx_tuser,

	output wire [AXIS_DATA_WIDTH-1:0] 			m_axis_rx_tdata,
	output wire [AXIS_KEEP_WIDTH-1:0] 			m_axis_rx_tkeep,
	output wire 								m_axis_rx_tvalid,
	input  wire 								m_axis_rx_tready,
	output wire 								m_axis_rx_tlast,
	output wire [AXIS_ID_WIDTH-1:0] 			m_axis_rx_tid,
	output wire [AXIS_DEST_WIDTH-1:0] 			m_axis_rx_tdest,
	output wire [AXIS_USER_WIDTH-1:0] 			m_axis_rx_tuser,

	input  wire [AXIL_ADDR_WIDTH-1:0]			s_axil_awaddr,
	input  wire [2:0]							s_axil_awprot,
	input  wire									s_axil_awvalid,
	output wire									s_axil_awready,
	input  wire [AXIL_DATA_WIDTH-1:0]			s_axil_wdata,
	input  wire [AXIL_STRB_WIDTH-1:0]			s_axil_wstrb,
	input  wire									s_axil_wvalid,
	output wire									s_axil_wready,
	output wire [1:0]							s_axil_bresp,
	output wire									s_axil_bvalid,
	input  wire									s_axil_bready,
	input  wire [AXIL_ADDR_WIDTH-1:0]			s_axil_araddr,
	input  wire [2:0]							s_axil_arprot,
	input  wire									s_axil_arvalid,
	output wire									s_axil_arready,
	output wire [AXIL_DATA_WIDTH-1:0]			s_axil_rdata,
	output wire [1:0]							s_axil_rresp,
	output wire									s_axil_rvalid,
	input  wire									s_axil_rready
);

localparam dataBitsPerSymbol = 8;
localparam AVST_DATA_WIDTH = AXIS_DATA_WIDTH;
localparam AVST_EMPTY_WIDTH = $clog2(AVST_DATA_WIDTH/dataBitsPerSymbol+1);
localparam AVST_CHANNEL_WIDTH = AXIS_DEST_WIDTH;
localparam AVST_ERROR_WIDTH = 2;

initial begin
	if (AVST_DATA_WIDTH != 512) begin
		$error("ERROR: MAT data width are restricted to 512.  (instance %m)");
		$finish;
	end
	if (AXIL_DATA_WIDTH != 32) begin
		$error("ERROR: CSR data width are restricted to 32.  (instance %m)");
		$finish;
	end
end

// `define BYPASS
`ifdef BYPASS

assign m_axis_rx_tdata	 = s_axis_rx_tdata;
assign m_axis_rx_tkeep	 = s_axis_rx_tkeep;
assign m_axis_rx_tvalid	 = s_axis_rx_tvalid;
assign s_axis_rx_tready	 = m_axis_rx_tready;
assign m_axis_rx_tlast	 = s_axis_rx_tlast;
assign m_axis_rx_tid	 = s_axis_rx_tid;
assign m_axis_rx_tdest	 = s_axis_rx_tdest;
assign m_axis_rx_tuser	 = s_axis_rx_tuser;

assign s_axil_awready	 = 1'b0;
assign s_axil_wready	 = 1'b0;
assign s_axil_bresp		 = 2'b00;
assign s_axil_bvalid	 = 1'b0;
assign s_axil_arready	 = 1'b0;
assign s_axil_rdata		 = {AXIL_DATA_WIDTH{1'b0}};
assign s_axil_rresp		 = 2'b00;
assign s_axil_rvalid	 = 1'b0;

`else

/*
 * Match Action Table structure.
 */
wire [AVST_DATA_WIDTH-1:0] 			avst_rx_in_data;
wire [AVST_EMPTY_WIDTH-1:0] 		avst_rx_in_empty;
wire 								avst_rx_in_valid;
wire 								avst_rx_in_ready;
wire 								avst_rx_in_startofpacket;
wire 								avst_rx_in_endofpacket;
wire [AXIS_ID_WIDTH-1:0] 			avst_rx_in_tid;
wire [AVST_CHANNEL_WIDTH-1:0] 		avst_rx_in_channel;
wire [AXIS_USER_WIDTH-1:0] 			avst_rx_in_tuser;
wire [AVST_ERROR_WIDTH-1:0] 		avst_rx_in_error;

wire [AVST_DATA_WIDTH-1:0] 			avst_rx_out_data;
wire [AVST_EMPTY_WIDTH-1:0] 		avst_rx_out_empty;
wire 								avst_rx_out_valid;
wire 								avst_rx_out_ready;
wire 								avst_rx_out_startofpacket;
wire 								avst_rx_out_endofpacket;
wire [AXIS_ID_WIDTH-1:0] 			avst_rx_out_tid;
wire [AVST_CHANNEL_WIDTH-1:0] 		avst_rx_out_channel;
wire [AXIS_USER_WIDTH-1:0] 			avst_rx_out_tuser;
wire [AVST_ERROR_WIDTH-1:0] 		avst_rx_out_error;

wire [AVST_ERROR_WIDTH-1:0]			s_axis_rx_terror;
wire [AVST_ERROR_WIDTH-1:0]			m_axis_rx_terror;

wire [AXIL_DATA_WIDTH-1:0] 			csr_agent_readdata;
wire [1:0]							csr_agent_response;
wire 								csr_agent_waitrequest;
wire 								csr_agent_readdatavalid;
wire 								csr_agent_writeresponsevalid;
wire [AXIL_ADDR_WIDTH-1:0] 			csr_agent_address;
wire 								csr_agent_read;
wire 								csr_agent_write;
wire [AXIL_DATA_WIDTH-1:0] 			csr_agent_writedata;
wire [AXIL_STRB_WIDTH-1:0] 			csr_agent_byteenable;
wire 								csr_agent_debugaccess;
wire 								csr_agent_lock;
wire 								csr_agent_burstcount;
wire 								csr_agent_beginbursttransfer;

app_mat #(
	.AVST_DATA_WIDTH				(AVST_DATA_WIDTH	),
	.AVST_EMPTY_WIDTH				(AVST_EMPTY_WIDTH	),
	.AVST_CHANNEL_WIDTH				(AVST_CHANNEL_WIDTH	),
	.AVST_ERROR_WIDTH				(AVST_ERROR_WIDTH	),
	.AVMM_DATA_WIDTH				(AXIL_DATA_WIDTH	),
	.AVMM_STRB_WIDTH				(AXIL_STRB_WIDTH	),
	.AVMM_ADDR_WIDTH				(AXIL_ADDR_WIDTH	)
) app_mat_inst (
	.clk							(clk),
	.rst							(rst),

	.avst_rx_in_data				(avst_rx_in_data			),
	.avst_rx_in_empty				(avst_rx_in_empty			),
	.avst_rx_in_valid				(avst_rx_in_valid			),
	.avst_rx_in_ready				(avst_rx_in_ready			),
	.avst_rx_in_startofpacket		(avst_rx_in_startofpacket	),
	.avst_rx_in_endofpacket			(avst_rx_in_endofpacket		),
	.avst_rx_in_channel				(avst_rx_in_channel			),
	.avst_rx_in_error				(avst_rx_in_error			),

	.avst_rx_out_data				(avst_rx_out_data			),
	.avst_rx_out_empty				(avst_rx_out_empty			),
	.avst_rx_out_valid				(avst_rx_out_valid			),
	.avst_rx_out_ready				(avst_rx_out_ready			),
	.avst_rx_out_startofpacket		(avst_rx_out_startofpacket	),
	.avst_rx_out_endofpacket		(avst_rx_out_endofpacket	),
	.avst_rx_out_channel			(avst_rx_out_channel		),
	.avst_rx_out_error				(avst_rx_out_error			),

	.csr_agent_readdata				(csr_agent_readdata				),
	.csr_agent_response				(csr_agent_response				),
	.csr_agent_waitrequest			(csr_agent_waitrequest			),
	.csr_agent_readdatavalid		(csr_agent_readdatavalid		),
	.csr_agent_writeresponsevalid	(csr_agent_writeresponsevalid	),
	.csr_agent_address				(csr_agent_address				),
	.csr_agent_read					(csr_agent_read					),
	.csr_agent_write				(csr_agent_write				),
	.csr_agent_writedata			(csr_agent_writedata			),
	.csr_agent_byteenable			(csr_agent_byteenable			),
	.csr_agent_debugaccess			(csr_agent_debugaccess			),
	.csr_agent_lock					(csr_agent_lock					),
	.csr_agent_burstcount			(csr_agent_burstcount			),
	.csr_agent_beginbursttransfer	(csr_agent_beginbursttransfer	)
);

assign s_axis_rx_terror = {AVST_ERROR_WIDTH{1'b0}};

axis_to_avst # (
	.S_DATA_WIDTH					(AXIS_DATA_WIDTH),
	.S_KEEP_ENABLE					(1),
	.S_KEEP_WIDTH					(AXIS_KEEP_WIDTH),
	.O_DATA_WIDTH					(AVST_DATA_WIDTH),
	.O_EMPTY_ENABLE					(1),
	.O_EMPTY_WIDTH					(AVST_EMPTY_WIDTH),
	.ID_ENABLE						(AXIS_ID_ENABLE),
	.ID_WIDTH						(AXIS_ID_WIDTH),
	.DEST_ENABLE					(AXIS_DEST_ENABLE),
	.DEST_WIDTH						(AXIS_DEST_WIDTH),
	.USER_ENABLE					(AXIS_USER_ENABLE),
	.USER_WIDTH						(AXIS_USER_WIDTH),
	.ERROR_ENABLE					(1),
	.ERROR_WIDTH					(AVST_ERROR_WIDTH),
	.CHANNEL_WIDTH					(AVST_CHANNEL_WIDTH),
	.dataBitsPerSymbol				(dataBitsPerSymbol),
	.firstSymbolInHighOrderBits		(1)
) axis_to_avst_inst (
	.clk(clk),
	.rst(rst),

	.s_axis_tdata					(s_axis_rx_tdata		),
	.s_axis_tkeep					(s_axis_rx_tkeep		),
	.s_axis_tvalid					(s_axis_rx_tvalid		),
	.s_axis_tready					(s_axis_rx_tready		),
	.s_axis_tlast					(s_axis_rx_tlast		),
	.s_axis_tid						(s_axis_rx_tid			),
	.s_axis_tdest					(s_axis_rx_tdest		),
	.s_axis_tuser					(s_axis_rx_tuser		),
	.s_axis_terror					(s_axis_rx_terror		),

	.stream_out_data				(avst_rx_in_data			),
	.stream_out_empty				(avst_rx_in_empty			),
	.stream_out_valid				(avst_rx_in_valid			),
	.stream_out_ready				(avst_rx_in_ready			),
	.stream_out_startofpacket		(avst_rx_in_startofpacket	),
	.stream_out_endofpacket			(avst_rx_in_endofpacket		),
	.stream_out_id					(avst_rx_in_tid				),	// NU
	.stream_out_channel				(avst_rx_in_channel			),
	.stream_out_user				(avst_rx_in_tuser			),	// NU
	.stream_out_error				(avst_rx_in_error			)
);

assign avst_rx_out_tuser = {AXIS_USER_WIDTH{1'b0}};
assign avst_rx_out_tid = {AXIS_ID_WIDTH{1'b0}};

avst_to_axis # (
	.M_DATA_WIDTH					(AXIS_DATA_WIDTH),
	.M_KEEP_ENABLE					(1),
	.M_KEEP_WIDTH					(AXIS_KEEP_WIDTH),
	.I_DATA_WIDTH					(AVST_DATA_WIDTH),
	.I_EMPTY_ENABLE					(1),
	.I_EMPTY_WIDTH					(AVST_EMPTY_WIDTH),
	.ID_ENABLE						(AXIS_ID_ENABLE),
	.ID_WIDTH						(AXIS_ID_WIDTH),
	.DEST_ENABLE					(AXIS_DEST_ENABLE),
	.DEST_WIDTH						(AXIS_DEST_WIDTH),
	.USER_ENABLE					(AXIS_USER_ENABLE),
	.USER_WIDTH						(AXIS_USER_WIDTH),
	.ERROR_ENABLE					(1),
	.ERROR_WIDTH					(AVST_ERROR_WIDTH),
	.CHANNEL_WIDTH					(AVST_CHANNEL_WIDTH),
	.dataBitsPerSymbol				(dataBitsPerSymbol),
	.firstSymbolInHighOrderBits		(1)
) avst_to_axis_inst (
	.clk(clk),
	.rst(rst),

	.stream_in_data					(avst_rx_out_data			),
	.stream_in_empty				(avst_rx_out_empty			),
	.stream_in_valid				(avst_rx_out_valid			),
	.stream_in_ready				(avst_rx_out_ready			),
	.stream_in_startofpacket		(avst_rx_out_startofpacket	),
	.stream_in_endofpacket			(avst_rx_out_endofpacket	),
	.stream_in_id					(avst_rx_out_tid			),
	.stream_in_channel				(avst_rx_out_channel		),
	.stream_in_user					(avst_rx_out_tuser			),
	.stream_in_error				(avst_rx_out_error			),

	.m_axis_tdata					(m_axis_rx_tdata	),
	.m_axis_tkeep					(m_axis_rx_tkeep	),
	.m_axis_tvalid					(m_axis_rx_tvalid	),
	.m_axis_tready					(m_axis_rx_tready	),
	.m_axis_tlast					(m_axis_rx_tlast	),
	.m_axis_tid						(m_axis_rx_tid		),
	.m_axis_tdest					(m_axis_rx_tdest	),
	.m_axis_tuser					(m_axis_rx_tuser	),
	.m_axis_terror					(m_axis_rx_terror	)
);

axil_to_avmm # (
	.ADDR_WIDTH			(AXIL_ADDR_WIDTH),
	.S_DATA_WIDTH		(AXIL_DATA_WIDTH),
	.S_STRB_WIDTH		(AXIL_STRB_WIDTH),
	.M_DATA_WIDTH		(AXIL_DATA_WIDTH),
	.M_STRB_WIDTH		(AXIL_STRB_WIDTH),
	.firstSymbolInHighOrderBits (0)
) axil_to_avmm_inst (
	.clk(clk),
	.rst(rst),

	.s_axil_awaddr					(s_axil_awaddr	),
	.s_axil_awprot					(s_axil_awprot	),
	.s_axil_awvalid					(s_axil_awvalid	),
	.s_axil_awready					(s_axil_awready	),
	.s_axil_wdata					(s_axil_wdata	),
	.s_axil_wstrb					(s_axil_wstrb	),
	.s_axil_wvalid					(s_axil_wvalid	),
	.s_axil_wready					(s_axil_wready	),
	.s_axil_bresp					(s_axil_bresp	),
	.s_axil_bvalid					(s_axil_bvalid	),
	.s_axil_bready					(s_axil_bready	),

	.s_axil_araddr					(s_axil_araddr	),
	.s_axil_arprot					(s_axil_arprot	),
	.s_axil_arvalid					(s_axil_arvalid	),
	.s_axil_arready					(s_axil_arready	),
	.s_axil_rdata					(s_axil_rdata	),
	.s_axil_rresp					(s_axil_rresp	),
	.s_axil_rvalid					(s_axil_rvalid	),
	.s_axil_rready					(s_axil_rready	),
	
	.csr_host_readdata				(csr_agent_readdata				),
	.csr_host_response				(csr_agent_response				),
	.csr_host_waitrequest			(csr_agent_waitrequest			),
	.csr_host_readdatavalid			(csr_agent_readdatavalid		),
	.csr_host_writeresponsevalid	(csr_agent_writeresponsevalid	),
	.csr_host_address				(csr_agent_address				),
	.csr_host_read					(csr_agent_read					),
	.csr_host_write					(csr_agent_write				),
	.csr_host_writedata				(csr_agent_writedata			),
	.csr_host_byteenable			(csr_agent_byteenable			),
	.csr_host_debugaccess			(csr_agent_debugaccess			),
	.csr_host_lock					(csr_agent_lock					),
	.csr_host_burstcount			(csr_agent_burstcount			),
	.csr_host_beginbursttransfer	(csr_agent_beginbursttransfer	)
);

`endif

endmodule

`resetall