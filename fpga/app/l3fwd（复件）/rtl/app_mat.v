/*
 * Created on Wed Jan 05 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 app_mat.v
 * @Author:		 Jiawei Lin
 * @Last edit:	 18:00:13
 */

// Language: Verilog 2001

/* verilator lint_off PINMISSING */

`resetall
`timescale 1ns / 1ps
`default_nettype none

module app_mat # (
	parameter AVST_DATA_WIDTH = 512,
	parameter AVST_EMPTY_WIDTH = $clog2(AVST_DATA_WIDTH/dataBitsPerSymbol+1),
	parameter AVST_CHANNEL_WIDTH = 4,
	parameter AVST_ERROR_WIDTH = 3,
	parameter dataBitsPerSymbol = 8,

	parameter AVMM_DATA_WIDTH = 32,
	parameter AVMM_STRB_WIDTH = 32/8,
	parameter AVMM_ADDR_WIDTH = 16,

	parameter APP_MAT_TYPE = 32'h0102_0304,	/* Vendor, Type */
	parameter APP_MAT_VER = 32'h0000_0100,	/* Major, Minor, Patch, Meta */
	parameter APP_MAT_NP = 32'h0000_0000,

	parameter ACTN_EN = 1
) (

	input  wire 							clk,
	input  wire 							rst,

	input  wire [AVST_DATA_WIDTH-1:0]		avst_rx_in_data,
	input  wire [AVST_EMPTY_WIDTH-1:0]		avst_rx_in_empty,
	input  wire 							avst_rx_in_valid,
	output wire 							avst_rx_in_ready,
	input  wire 							avst_rx_in_startofpacket,
	input  wire 							avst_rx_in_endofpacket,
	input  wire [AVST_CHANNEL_WIDTH-1:0]	avst_rx_in_channel,
	input  wire [AVST_ERROR_WIDTH-1:0]		avst_rx_in_error,

	output wire [AVST_DATA_WIDTH-1:0]		avst_rx_out_data,
	output wire [AVST_EMPTY_WIDTH-1:0]		avst_rx_out_empty,
	output wire 							avst_rx_out_valid,
	input  wire 							avst_rx_out_ready,
	output wire 							avst_rx_out_startofpacket,
	output wire 							avst_rx_out_endofpacket,
	output wire [AVST_CHANNEL_WIDTH-1:0]	avst_rx_out_channel,
	output wire [AVST_ERROR_WIDTH-1:0]		avst_rx_out_error,

	/*
	 * Avalon Memory Mapped agent interface
	 */
	output wire [AVMM_DATA_WIDTH-1:0] 		csr_agent_readdata,
	output wire [1:0]						csr_agent_response,				// TODO: NU
	output wire 							csr_agent_waitrequest,
	output wire 							csr_agent_readdatavalid,
	output wire 							csr_agent_writeresponsevalid,
	input  wire [AVMM_ADDR_WIDTH-1:0] 		csr_agent_address,
	input  wire 							csr_agent_read,
	input  wire 							csr_agent_write,
	input  wire [AVMM_DATA_WIDTH-1:0] 		csr_agent_writedata,
	input  wire [AVMM_STRB_WIDTH-1:0] 		csr_agent_byteenable,			// TODO: NU
	input  wire 							csr_agent_debugaccess,			// TODO: NU. 
	input  wire 							csr_agent_lock,					// TODO: NU
	input  wire 							csr_agent_burstcount,			// TODO: NU
	input  wire 							csr_agent_beginbursttransfer	// TODO: NU
);

// `define BYPASS
`ifdef BYPASS

assign avst_rx_out_data				 = avst_rx_in_data;
assign avst_rx_out_empty			 = avst_rx_in_empty;
assign avst_rx_out_valid			 = avst_rx_in_valid;
assign avst_rx_in_ready				 = avst_rx_out_ready;
assign avst_rx_out_startofpacket	 = avst_rx_in_startofpacket;
assign avst_rx_out_endofpacket		 = avst_rx_in_endofpacket;
assign avst_rx_out_channel			 = avst_rx_in_channel;
assign avst_rx_out_error			 = avst_rx_in_error;

assign csr_agent_readdata = {AVMM_DATA_WIDTH{1'b0}};
assign csr_agent_response = 2'b00;
assign csr_agent_waitrequest = 1'b0;
assign csr_agent_readdatavalid = 1'b1;
assign csr_agent_writeresponsevalid = 1'b1;

`else

/*
 * 0. CSR implementation using avmm. 
 */
localparam BAR_TCAM_DATA = 16'h0100;
localparam BAR_TCAM_KEEP = 16'h0180;
localparam BAR_ACTN_DATA = 16'h0010;
localparam BAR_CSR = 16'h0020;

reg  [AVMM_DATA_WIDTH-1:0] csr_agent_readdata_reg = {AVMM_DATA_WIDTH{1'b0}};
reg  [1:0] csr_agent_response_reg = 2'b0;
reg  csr_agent_readdatavalid_reg = 1'b0;
reg  csr_agent_writeresponsevalid_reg = 1'b0;

assign csr_agent_readdata = csr_agent_readdata_reg;
assign csr_agent_response = csr_agent_response_reg;
assign csr_agent_waitrequest = tcam_wr_valid && !tcam_wr_ready;
assign csr_agent_readdatavalid = csr_agent_readdatavalid_reg;
assign csr_agent_writeresponsevalid = csr_agent_writeresponsevalid_reg;

always @(*) begin
	csr_data_next = csr_data_reg;
	if (tcam_wr_valid && tcam_wr_ready) begin
		csr_data_next = csr_data_next & {{CSR_ACTN_WIDTH{1'b1}},{CSR_TCAM_WIDTH{1'b0}}};
	end
	if (action_wr_valid && action_wr_ready) begin
		csr_data_next = csr_data_next & {{CSR_ACTN_WIDTH{1'b0}},{CSR_TCAM_WIDTH{1'b1}}};
	end
end

always @(posedge clk) begin

	if (csr_agent_read) begin
		// read operation
		csr_agent_readdatavalid_reg <= !csr_agent_waitrequest;
		case ({csr_agent_address >> 2, 2'b00})
			16'h0000: csr_agent_readdata_reg <= APP_MAT_TYPE;
			16'h0004: csr_agent_readdata_reg <= APP_MAT_VER;
			16'h0008: csr_agent_readdata_reg <= APP_MAT_NP;
			BAR_TCAM_DATA+16'h0000: csr_agent_readdata_reg <= tcam_wr_data_reg[0*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0004: csr_agent_readdata_reg <= tcam_wr_data_reg[1*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0008: csr_agent_readdata_reg <= tcam_wr_data_reg[2*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h000C: csr_agent_readdata_reg <= tcam_wr_data_reg[3*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0010: csr_agent_readdata_reg <= tcam_wr_data_reg[4*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0014: csr_agent_readdata_reg <= tcam_wr_data_reg[5*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0018: csr_agent_readdata_reg <= tcam_wr_data_reg[6*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h001C: csr_agent_readdata_reg <= tcam_wr_data_reg[7*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];/*
			BAR_TCAM_DATA+16'h0020: csr_agent_readdata_reg <= tcam_wr_data_reg[8*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0024: csr_agent_readdata_reg <= tcam_wr_data_reg[9*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0028: csr_agent_readdata_reg <= tcam_wr_data_reg[10*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h002C: csr_agent_readdata_reg <= tcam_wr_data_reg[11*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0030: csr_agent_readdata_reg <= tcam_wr_data_reg[12*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0034: csr_agent_readdata_reg <= tcam_wr_data_reg[13*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0038: csr_agent_readdata_reg <= tcam_wr_data_reg[14*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h003C: csr_agent_readdata_reg <= tcam_wr_data_reg[15*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0040: csr_agent_readdata_reg <= tcam_wr_data_reg[16*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0044: csr_agent_readdata_reg <= tcam_wr_data_reg[17*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0048: csr_agent_readdata_reg <= tcam_wr_data_reg[18*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h004C: csr_agent_readdata_reg <= tcam_wr_data_reg[19*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0050: csr_agent_readdata_reg <= tcam_wr_data_reg[20*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0054: csr_agent_readdata_reg <= tcam_wr_data_reg[21*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0058: csr_agent_readdata_reg <= tcam_wr_data_reg[22*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h005C: csr_agent_readdata_reg <= tcam_wr_data_reg[23*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0060: csr_agent_readdata_reg <= tcam_wr_data_reg[24*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0064: csr_agent_readdata_reg <= tcam_wr_data_reg[25*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0068: csr_agent_readdata_reg <= tcam_wr_data_reg[26*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h006C: csr_agent_readdata_reg <= tcam_wr_data_reg[27*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0070: csr_agent_readdata_reg <= tcam_wr_data_reg[28*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0074: csr_agent_readdata_reg <= tcam_wr_data_reg[29*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h0078: csr_agent_readdata_reg <= tcam_wr_data_reg[30*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_DATA+16'h007C: csr_agent_readdata_reg <= tcam_wr_data_reg[31*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];*/

			BAR_TCAM_KEEP+16'h0000: csr_agent_readdata_reg <= tcam_wr_keep_reg[0*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0004: csr_agent_readdata_reg <= tcam_wr_keep_reg[1*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0008: csr_agent_readdata_reg <= tcam_wr_keep_reg[2*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h000C: csr_agent_readdata_reg <= tcam_wr_keep_reg[3*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0010: csr_agent_readdata_reg <= tcam_wr_keep_reg[4*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0014: csr_agent_readdata_reg <= tcam_wr_keep_reg[5*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0018: csr_agent_readdata_reg <= tcam_wr_keep_reg[6*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h001C: csr_agent_readdata_reg <= tcam_wr_keep_reg[7*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];/*
			BAR_TCAM_KEEP+16'h0020: csr_agent_readdata_reg <= tcam_wr_keep_reg[8*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0024: csr_agent_readdata_reg <= tcam_wr_keep_reg[9*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0028: csr_agent_readdata_reg <= tcam_wr_keep_reg[10*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h002C: csr_agent_readdata_reg <= tcam_wr_keep_reg[11*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0030: csr_agent_readdata_reg <= tcam_wr_keep_reg[12*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0034: csr_agent_readdata_reg <= tcam_wr_keep_reg[13*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0038: csr_agent_readdata_reg <= tcam_wr_keep_reg[14*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h003C: csr_agent_readdata_reg <= tcam_wr_keep_reg[15*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0040: csr_agent_readdata_reg <= tcam_wr_keep_reg[16*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0044: csr_agent_readdata_reg <= tcam_wr_keep_reg[17*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0048: csr_agent_readdata_reg <= tcam_wr_keep_reg[18*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h004C: csr_agent_readdata_reg <= tcam_wr_keep_reg[19*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0050: csr_agent_readdata_reg <= tcam_wr_keep_reg[20*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0054: csr_agent_readdata_reg <= tcam_wr_keep_reg[21*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0058: csr_agent_readdata_reg <= tcam_wr_keep_reg[22*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h005C: csr_agent_readdata_reg <= tcam_wr_keep_reg[23*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0060: csr_agent_readdata_reg <= tcam_wr_keep_reg[24*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0064: csr_agent_readdata_reg <= tcam_wr_keep_reg[25*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0068: csr_agent_readdata_reg <= tcam_wr_keep_reg[26*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h006C: csr_agent_readdata_reg <= tcam_wr_keep_reg[27*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0070: csr_agent_readdata_reg <= tcam_wr_keep_reg[28*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0074: csr_agent_readdata_reg <= tcam_wr_keep_reg[29*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h0078: csr_agent_readdata_reg <= tcam_wr_keep_reg[30*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_TCAM_KEEP+16'h007C: csr_agent_readdata_reg <= tcam_wr_keep_reg[31*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];*/

			BAR_ACTN_DATA+16'h0000: csr_agent_readdata_reg <= action_wr_data_reg[0*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_ACTN_DATA+16'h0004: csr_agent_readdata_reg <= action_wr_data_reg[1*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_ACTN_DATA+16'h0008: csr_agent_readdata_reg <= action_wr_data_reg[2*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];
			BAR_ACTN_DATA+16'h000C: csr_agent_readdata_reg <= action_wr_data_reg[3*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH];

			BAR_CSR: csr_agent_readdata_reg <= csr_data_reg;	/* addr: 16'h0110 */
			default: csr_agent_readdata_reg <= csr_agent_readdata_reg;
		endcase
	end else begin
		csr_agent_readdatavalid_reg <= 1'b0;
	end

	if (csr_agent_write & !csr_agent_waitrequest) begin
		// write operation
		csr_agent_writeresponsevalid_reg <= 1'b1;	// TODO: block one cycle. 
		case ({csr_agent_address >> 2, 2'b00})
			BAR_TCAM_DATA+16'h0000: tcam_wr_data_reg[0*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0004: tcam_wr_data_reg[1*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0008: tcam_wr_data_reg[2*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h000C: tcam_wr_data_reg[3*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0010: tcam_wr_data_reg[4*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0014: tcam_wr_data_reg[5*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0018: tcam_wr_data_reg[6*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h001C: tcam_wr_data_reg[7*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;/*
			BAR_TCAM_DATA+16'h0020: tcam_wr_data_reg[8*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0024: tcam_wr_data_reg[9*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0028: tcam_wr_data_reg[10*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h002C: tcam_wr_data_reg[11*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0030: tcam_wr_data_reg[12*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0034: tcam_wr_data_reg[13*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0038: tcam_wr_data_reg[14*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h003C: tcam_wr_data_reg[15*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0040: tcam_wr_data_reg[16*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0044: tcam_wr_data_reg[17*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0048: tcam_wr_data_reg[18*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h004C: tcam_wr_data_reg[19*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0050: tcam_wr_data_reg[20*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0054: tcam_wr_data_reg[21*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0058: tcam_wr_data_reg[22*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h005C: tcam_wr_data_reg[23*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0060: tcam_wr_data_reg[24*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0064: tcam_wr_data_reg[25*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0068: tcam_wr_data_reg[26*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h006C: tcam_wr_data_reg[27*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0070: tcam_wr_data_reg[28*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0074: tcam_wr_data_reg[29*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h0078: tcam_wr_data_reg[30*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_DATA+16'h007C: tcam_wr_data_reg[31*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;*/

			BAR_TCAM_KEEP+16'h0000: tcam_wr_keep_reg[0*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0004: tcam_wr_keep_reg[1*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0008: tcam_wr_keep_reg[2*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h000C: tcam_wr_keep_reg[3*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0010: tcam_wr_keep_reg[4*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0014: tcam_wr_keep_reg[5*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0018: tcam_wr_keep_reg[6*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h001C: tcam_wr_keep_reg[7*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;/* 
			BAR_TCAM_KEEP+16'h0020: tcam_wr_keep_reg[8*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0024: tcam_wr_keep_reg[9*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0028: tcam_wr_keep_reg[10*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h002C: tcam_wr_keep_reg[11*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0030: tcam_wr_keep_reg[12*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0034: tcam_wr_keep_reg[13*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0038: tcam_wr_keep_reg[14*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h003C: tcam_wr_keep_reg[15*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0040: tcam_wr_keep_reg[16*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0044: tcam_wr_keep_reg[17*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0048: tcam_wr_keep_reg[18*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h004C: tcam_wr_keep_reg[19*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0050: tcam_wr_keep_reg[20*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0054: tcam_wr_keep_reg[21*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0058: tcam_wr_keep_reg[22*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h005C: tcam_wr_keep_reg[23*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0060: tcam_wr_keep_reg[24*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0064: tcam_wr_keep_reg[25*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0068: tcam_wr_keep_reg[26*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h006C: tcam_wr_keep_reg[27*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0070: tcam_wr_keep_reg[28*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0074: tcam_wr_keep_reg[29*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h0078: tcam_wr_keep_reg[30*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;
			BAR_TCAM_KEEP+16'h007C: tcam_wr_keep_reg[31*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH]	 <= csr_agent_writedata;*/

			BAR_ACTN_DATA+16'h0000: action_wr_data_reg[0*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH] <= csr_agent_writedata;
			BAR_ACTN_DATA+16'h0004: action_wr_data_reg[1*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH] <= csr_agent_writedata;
			BAR_ACTN_DATA+16'h0008: action_wr_data_reg[2*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH] <= csr_agent_writedata;
			BAR_ACTN_DATA+16'h000C: action_wr_data_reg[3*AVMM_DATA_WIDTH +: AVMM_DATA_WIDTH] <= csr_agent_writedata;

			BAR_CSR: csr_data_reg <= csr_agent_writedata;
			default: ;
		endcase
	end else begin
		csr_agent_writeresponsevalid_reg <= 1'b0;
		csr_data_reg <= csr_data_next;
	end

	if (rst) begin
		csr_data_reg <= {AVMM_DATA_WIDTH{1'b0}};
	end
end

/*
 * 1. Parser
 */
localparam MAC_WIDTH = 48;
localparam IPv4_WIDTH = 32;
localparam IPv6_WIDTH = 128;
localparam PORT_WIDTH = 16;
localparam ETH_TYPE_WIDTH = 16;
localparam PT_WIDTH = 4, PSR_USER_WIDTH = PT_WIDTH;

wire [AVST_DATA_WIDTH-1:0]		avst_psr_hdr_data, avst_psr_data;
wire [AVST_EMPTY_WIDTH-1:0]		avst_psr_hdr_empty, avst_psr_empty;
wire 							avst_psr_hdr_valid, avst_psr_valid;
wire 							avst_psr_hdr_ready, avst_psr_ready;
wire 							avst_psr_hdr_startofpacket, avst_psr_startofpacket;
wire 							avst_psr_hdr_endofpacket, avst_psr_endofpacket;
wire [AVST_CHANNEL_WIDTH-1:0]	avst_psr_hdr_channel, avst_psr_channel;
wire [AVST_ERROR_WIDTH-1:0] 	avst_psr_hdr_error, avst_psr_error;
wire [PSR_USER_WIDTH-1:0] 		avst_psr_hdr_tuser; 

wire [MAC_WIDTH-1:0]			des_mac_reg;
wire [MAC_WIDTH-1:0]			src_mac_reg;
wire [IPv4_WIDTH-1:0]			des_ipv4_reg;
wire [IPv4_WIDTH-1:0]			src_ipv4_reg;
wire [IPv6_WIDTH-1:0]			des_ipv6_reg;
wire [IPv6_WIDTH-1:0]			src_ipv6_reg;
wire [PORT_WIDTH-1:0]			des_port_reg;
wire [PORT_WIDTH-1:0]			src_port_reg;
wire 							vlan_tag_reg;
wire 							qinq_tag_reg;
wire 							arp_tag_reg;
wire 							lldp_tag_reg;
wire 							ipv4_tag_reg;
wire 							ipv6_tag_reg;
wire 							tcp_tag_reg;
wire 							udp_tag_reg;
wire 							seadp_tag_reg;
wire [ETH_TYPE_WIDTH-1:0]		eth_type_reg;

parser #(
	.I_DATA_WIDTH				(AVST_DATA_WIDTH),
	.I_EMPTY_WIDTH				(AVST_EMPTY_WIDTH),
	.I_ERROR_WIDTH				(AVST_ERROR_WIDTH),
	.I_CHANNEL_WIDTH			(AVST_CHANNEL_WIDTH),
	.O_DATA_WIDTH				(AVST_DATA_WIDTH),
	.O_EMPTY_WIDTH				(AVST_EMPTY_WIDTH),
	.O_ERROR_WIDTH				(AVST_ERROR_WIDTH),
	.O_CHANNEL_WIDTH			(AVST_CHANNEL_WIDTH)
) parser_inst (
	.clk(clk),
	.rst(rst),

	.stream_in_data				(avst_rx_in_data),
	.stream_in_empty			(avst_rx_in_empty),
	.stream_in_valid			(avst_rx_in_valid),
	.stream_in_ready			(avst_rx_in_ready),	// TODO: should be and gate
	.stream_in_startofpacket	(avst_rx_in_startofpacket),
	.stream_in_endofpacket		(avst_rx_in_endofpacket),
	.stream_in_channel			(avst_rx_in_channel),
	.stream_in_error			(avst_rx_in_error),

	.stream_hdr_data			(avst_psr_hdr_data),
	.stream_hdr_empty			(avst_psr_hdr_empty),
	.stream_hdr_valid			(avst_psr_hdr_valid),
	.stream_hdr_ready			(avst_psr_hdr_ready),
	.stream_hdr_startofpacket	(avst_psr_hdr_startofpacket),
	.stream_hdr_endofpacket		(avst_psr_hdr_endofpacket),
	.stream_hdr_channel			(avst_psr_hdr_channel),
	.stream_hdr_error			(avst_psr_hdr_error),

	.stream_out_data			(avst_psr_data),
	.stream_out_empty			(avst_psr_empty),
	.stream_out_valid			(avst_psr_valid),
	.stream_out_ready			(avst_psr_ready),
	.stream_out_startofpacket	(avst_psr_startofpacket),
	.stream_out_endofpacket		(avst_psr_endofpacket),
	.stream_out_channel			(avst_psr_channel),
	.stream_out_error			(avst_psr_error),

	.des_mac					(des_mac_reg),
	.src_mac					(src_mac_reg),
	.eth_type					(eth_type_reg),
	.des_ipv4					(des_ipv4_reg),
	.src_ipv4					(src_ipv4_reg),
	.des_ipv6					(des_ipv6_reg),
	.src_ipv6					(src_ipv6_reg),
	.des_port					(des_port_reg),
	.src_port					(src_port_reg),
	.vlan_tag					(vlan_tag_reg),
	.qinq_tag					(qinq_tag_reg),
	.arp_tag					(arp_tag_reg),
	.lldp_tag					(lldp_tag_reg),

	.ipv4_tag					(ipv4_tag_reg),
	.ipv6_tag					(ipv6_tag_reg),
	.tcp_tag					(tcp_tag_reg),
	.udp_tag					(udp_tag_reg),
	.seadp_tag					(seadp_tag_reg)
);

assign avst_psr_hdr_tuser = vlan_tag_reg ? (
	(tcp_tag_reg || udp_tag_reg) ? (
		ipv4_tag_reg ? 3'h2 : (ipv6_tag_reg ? 3'h4 :3'h0)
	) : 3'h0
) : (tcp_tag_reg || udp_tag_reg) ? (
	ipv4_tag_reg ? 3'h1 : (ipv6_tag_reg ? 3'h3 :3'h0)
) : 3'h0;

/*
 * 2. Match Action Table
 */
localparam HDR_DATA_WIDTH = 600;
localparam HDR_EMPTY_WIDTH = $clog2(HDR_DATA_WIDTH/dataBitsPerSymbol+1);

localparam TCAM_ADDR_WIDTH = 10;
localparam TCAM_DATA_WIDTH = 35;
localparam TCAM_DEPTH = 16;
localparam TCAM_WR_WIDTH = AVMM_DATA_WIDTH;		// TODO: 32 -> 128
localparam TCAM_USER_WIDTH = PT_WIDTH+ACTN_DATA_WIDTH;

localparam ACTN_ADDR_WIDTH = TCAM_ADDR_WIDTH;
localparam ACTN_DATA_WIDTH = 128;
localparam ACTN_STRB_WIDTH = ACTN_DATA_WIDTH/8;

localparam CSR_TCAM_WR = 15, CSR_ACTN_WR = 31;
localparam CSR_TCAM_OFFSET = 0, CSR_TCAM_WIDTH = 16;
localparam CSR_ACTN_OFFSET = CSR_TCAM_OFFSET+CSR_TCAM_WIDTH, CSR_ACTN_WIDTH = 16;

reg  [8*TCAM_WR_WIDTH-1:0] tcam_wr_data_reg = {8*TCAM_WR_WIDTH{1'b0}};
reg  [8*TCAM_WR_WIDTH-1:0] tcam_wr_keep_reg = {8*TCAM_WR_WIDTH{1'b0}};
reg  [ACTN_DATA_WIDTH-1:0] action_wr_data_reg = {ACTN_DATA_WIDTH{1'b0}};
reg  [ACTN_STRB_WIDTH-1:0] action_wr_strb_reg = {ACTN_STRB_WIDTH{1'b1}};
reg  [AVMM_DATA_WIDTH-1:0] csr_data_reg = {AVMM_DATA_WIDTH{1'b0}}, csr_data_next;

wire [TCAM_ADDR_WIDTH-1:0] tcam_wr_addr;
wire tcam_wr_valid, tcam_wr_ready;
wire action_wr_valid, action_wr_ready, action_wr_done;
wire [ACTN_ADDR_WIDTH-1:0] action_wr_addr;

/*
 * CSR format:
 * 	[31]		TCAM write valid
 * 	[30]		Action table write valid
 * 	[29:20]		Reserved
 * 	[19:10]		Action write address
 * 	[9:0]		TCAM write address
 */
assign tcam_wr_addr = csr_data_reg[CSR_TCAM_OFFSET +: TCAM_ADDR_WIDTH];
assign tcam_wr_valid = csr_data_reg[CSR_TCAM_WR];
assign action_wr_addr = csr_data_reg[CSR_ACTN_OFFSET +: ACTN_ADDR_WIDTH];
assign action_wr_valid = csr_data_reg[CSR_ACTN_WR];

wire [HDR_DATA_WIDTH-1:0] 		avst_mch_hdr_data;
wire [HDR_EMPTY_WIDTH-1:0] 		avst_mch_hdr_empty;
wire 							avst_mch_hdr_valid;
wire 							avst_mch_hdr_ready;
wire 							avst_mch_hdr_startofpacket;
wire 							avst_mch_hdr_endofpacket;
wire [AVST_CHANNEL_WIDTH-1:0]	avst_mch_hdr_channel;
wire [AVST_ERROR_WIDTH-1:0] 	avst_mch_hdr_error;
wire [TCAM_USER_WIDTH-1:0] 		avst_mch_hdr_tuser;

match_pipe #(
	.I_DATA_WIDTH				(AVST_DATA_WIDTH),
	.I_EMPTY_WIDTH				(AVST_EMPTY_WIDTH),
	.I_CHANNEL_WIDTH			(AVST_CHANNEL_WIDTH),
	.I_ERROR_WIDTH				(AVST_ERROR_WIDTH),
	.O_DATA_WIDTH				(HDR_DATA_WIDTH),
	.O_EMPTY_WIDTH				(HDR_EMPTY_WIDTH),
	.O_CHANNEL_WIDTH			(AVST_CHANNEL_WIDTH),
	.O_ERROR_WIDTH				(AVST_ERROR_WIDTH),
	.dataBitsPerSymbol			(8),
	.I_USER_WIDTH				(PT_WIDTH),
	.O_USER_WIDTH				(TCAM_USER_WIDTH),

	.FRACTCAM_ENABLE			(1),
	.TCAM_ADDR_WIDTH			(TCAM_ADDR_WIDTH),
	.TCAM_DATA_WIDTH			(TCAM_DATA_WIDTH),
	.TCAM_WR_WIDTH				(TCAM_WR_WIDTH),
	.TCAM_DEPTH					(TCAM_DEPTH),
	.ACTN_DATA_WIDTH			(ACTN_DATA_WIDTH),
	.ACTN_STRB_WIDTH			(ACTN_STRB_WIDTH)
) match_pipe_inst (
	.clk(clk),
	.rst(rst),

	.stream_in_data				(avst_psr_hdr_data			),
	.stream_in_empty			(avst_psr_hdr_empty			),
	.stream_in_valid			(avst_psr_hdr_valid			),
	.stream_in_ready			(avst_psr_hdr_ready			),
	.stream_in_startofpacket	(avst_psr_hdr_startofpacket	),
	.stream_in_endofpacket		(avst_psr_hdr_endofpacket	),
	.stream_in_channel			(avst_psr_hdr_channel		),
	.stream_in_error			(avst_psr_hdr_error			),
	.stream_in_tuser			(avst_psr_hdr_tuser			),

	.stream_out_data			(avst_mch_hdr_data			),
	.stream_out_empty			(avst_mch_hdr_empty			),
	.stream_out_valid			(avst_mch_hdr_valid			),
	.stream_out_ready			(avst_mch_hdr_ready			),
	.stream_out_startofpacket	(avst_mch_hdr_startofpacket	),
	.stream_out_endofpacket		(avst_mch_hdr_endofpacket	),
	.stream_out_channel			(avst_mch_hdr_channel		),
	.stream_out_error			(avst_mch_hdr_error			),
	.stream_out_tuser			(avst_mch_hdr_tuser			),
/*
	.csr_address				(csr_agent_address		),
	.csr_readdata				(csr_agent_readdata		),
	.csr_readdatavalid			(csr_agent_readdatavalid),
	.csr_read					(csr_agent_read			),
	.csr_write					(csr_agent_write		),
	.csr_waitrequest			(csr_agent_waitrequest	),
	.csr_writedata				(csr_agent_writedata	),
*/
	.tcam_wr_addr				(tcam_wr_addr			),
	.tcam_wr_data				(tcam_wr_data_reg		),
	.tcam_wr_keep				(tcam_wr_keep_reg		),
	.tcam_wr_valid				(tcam_wr_valid			),
	.tcam_wr_ready				(tcam_wr_ready			),
	.action_wr_addr				(action_wr_addr			),
	.action_wr_data				(action_wr_data_reg		),
	.action_wr_strb				(action_wr_strb_reg		),
	.action_wr_valid			(action_wr_valid		),
	.action_wr_ready			(action_wr_ready		),
	.action_wr_done				(action_wr_done			)
);


/*
 * 3. Action handling pipeline
 */
wire [HDR_DATA_WIDTH-1:0] 		avst_act_hdr_data;
wire [HDR_EMPTY_WIDTH-1:0] 		avst_act_hdr_empty;
wire 							avst_act_hdr_valid;
wire 							avst_act_hdr_ready;
wire 							avst_act_hdr_startofpacket;
wire 							avst_act_hdr_endofpacket;
wire [AVST_CHANNEL_WIDTH-1:0]	avst_act_hdr_channel;
wire [AVST_ERROR_WIDTH-1:0] 	avst_act_hdr_error;

action_pipe #(
	.I_DATA_WIDTH				(HDR_DATA_WIDTH),
	.I_EMPTY_WIDTH				(HDR_EMPTY_WIDTH),
	.I_CHANNEL_WIDTH			(AVST_CHANNEL_WIDTH),
	.I_ERROR_WIDTH				(AVST_ERROR_WIDTH),
	.O_DATA_WIDTH				(HDR_DATA_WIDTH),
	.O_EMPTY_WIDTH				(HDR_EMPTY_WIDTH),
	.O_CHANNEL_WIDTH			(AVST_CHANNEL_WIDTH),
	.O_ERROR_WIDTH				(AVST_ERROR_WIDTH),
	.I_USER_WIDTH				(TCAM_USER_WIDTH),
	.O_USER_WIDTH				(TCAM_USER_WIDTH),
	.ACTN_DATA_WIDTH			(ACTN_DATA_WIDTH),
	.ENABLE						(ACTN_EN)
) action_pipe_inst (
	.clk(clk),
	.rst(rst),
	
	.stream_in_data				(avst_mch_hdr_data			),
	.stream_in_empty			(avst_mch_hdr_empty			),
	.stream_in_valid			(avst_mch_hdr_valid			),
	.stream_in_ready			(avst_mch_hdr_ready			),
	.stream_in_startofpacket	(avst_mch_hdr_startofpacket	),
	.stream_in_endofpacket		(avst_mch_hdr_endofpacket	),
	.stream_in_channel			(avst_mch_hdr_channel		),
	.stream_in_error			(avst_mch_hdr_error			),
	.stream_in_tuser			(avst_mch_hdr_tuser			),

	.stream_out_data			(avst_act_hdr_data			),
	.stream_out_empty			(avst_act_hdr_empty			),
	.stream_out_valid			(avst_act_hdr_valid			),
	.stream_out_ready			(avst_act_hdr_ready			),
	.stream_out_startofpacket	(avst_act_hdr_startofpacket	),
	.stream_out_endofpacket		(avst_act_hdr_endofpacket	),
	.stream_out_channel			(avst_act_hdr_channel		),
	.stream_out_error			(avst_act_hdr_error			),
	.stream_out_tuser			(			)
);

/*
 * 4. Deparser
 */

wire [AVST_DATA_WIDTH-1:0]		avst_dps_data;
wire [AVST_EMPTY_WIDTH-1:0]		avst_dps_empty;
wire 							avst_dps_valid;
wire 							avst_dps_ready;
wire 							avst_dps_startofpacket;
wire 							avst_dps_endofpacket;
wire [AVST_CHANNEL_WIDTH-1:0]	avst_dps_channel;
wire [AVST_ERROR_WIDTH-1:0]		avst_dps_error;

deparser #(
	.I_DATA_WIDTH					(AVST_DATA_WIDTH),
	.I_EMPTY_WIDTH					(AVST_EMPTY_WIDTH),
	.I_ERROR_WIDTH					(AVST_ERROR_WIDTH),
	.I_CHANNEL_WIDTH				(AVST_CHANNEL_WIDTH),
	.O_DATA_WIDTH					(AVST_DATA_WIDTH),
	.O_EMPTY_WIDTH					(AVST_EMPTY_WIDTH),
	.O_CHANNEL_WIDTH				(AVST_CHANNEL_WIDTH),
	.O_ERROR_WIDTH					(AVST_ERROR_WIDTH),
	.HDR_DATA_WIDTH					(HDR_DATA_WIDTH),
	.HDR_EMPTY_WIDTH				(HDR_EMPTY_WIDTH)
) deparser_inst (
	.clk(clk),
	.rst(rst),
	
	.stream_in_hdr_data				(avst_act_hdr_data),
	.stream_in_hdr_empty			(avst_act_hdr_empty),
	.stream_in_hdr_valid			(avst_act_hdr_valid),
	.stream_in_hdr_ready			(avst_act_hdr_ready),
	.stream_in_hdr_startofpacket	(avst_act_hdr_startofpacket),
	.stream_in_hdr_endofpacket		(avst_act_hdr_endofpacket),
	.stream_in_hdr_channel			(avst_act_hdr_channel),
	.stream_in_hdr_error			(avst_act_hdr_error),

	.stream_in_data					(avst_psr_data),
	.stream_in_empty				(avst_psr_empty),
	.stream_in_valid				(avst_psr_valid),
	.stream_in_ready				(avst_psr_ready),
	.stream_in_startofpacket		(avst_psr_startofpacket),
	.stream_in_endofpacket			(avst_psr_endofpacket),
	.stream_in_channel				(avst_psr_channel),
	.stream_in_error				(avst_psr_error),

	.stream_out_data				(avst_dps_data),
	.stream_out_empty				(avst_dps_empty),
	.stream_out_valid				(avst_dps_valid),
	.stream_out_ready				(avst_dps_ready),
	.stream_out_startofpacket		(avst_dps_startofpacket),
	.stream_out_endofpacket			(avst_dps_endofpacket),
	.stream_out_channel				(avst_dps_channel),
	.stream_out_error				(avst_dps_error)
);
/**/

assign avst_rx_out_data			 = avst_dps_data;
assign avst_rx_out_empty		 = avst_dps_empty;
assign avst_rx_out_valid		 = avst_dps_valid;
assign avst_dps_ready			 = avst_rx_out_ready;
assign avst_rx_out_startofpacket = avst_dps_startofpacket;
assign avst_rx_out_endofpacket	 = avst_dps_endofpacket;
assign avst_rx_out_channel		 = avst_dps_channel;
assign avst_rx_out_error		 = avst_dps_error;

`endif

endmodule

`resetall
