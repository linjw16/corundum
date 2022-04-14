/*
 * Created on Wed Jan 05 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 match_pipe.v
 * @Author:		 Jiawei Lin
 * @Last edit:	 09:45:41
 */

/* verilator lint_off PINMISSING */

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Match Table
 */
module match_pipe #(
	parameter I_DATA_WIDTH = 512,
	parameter I_EMPTY_WIDTH = $clog2(I_DATA_WIDTH/8+1),
	parameter I_CHANNEL_WIDTH = 6,
	parameter I_ERROR_WIDTH = 4,
	parameter O_DATA_WIDTH = 600,
	parameter O_EMPTY_WIDTH = $clog2(O_DATA_WIDTH/8+1),
	parameter O_CHANNEL_WIDTH = I_CHANNEL_WIDTH,
	parameter O_ERROR_WIDTH = I_ERROR_WIDTH,
	parameter dataBitsPerSymbol = 8,
	parameter I_USER_WIDTH = 4,
	parameter O_USER_WIDTH = I_USER_WIDTH+ACTN_DATA_WIDTH,

	parameter FRACTCAM_ENABLE = 1,
	parameter TCAM_ADDR_WIDTH = 10,
	parameter TCAM_DATA_WIDTH = FRACTCAM_ENABLE ? 130 : 128,
	parameter TCAM_WR_WIDTH = 128,
	parameter TCAM_DEPTH = 2**TCAM_ADDR_WIDTH,
	parameter ACTN_ADDR_WIDTH = TCAM_ADDR_WIDTH,
	parameter ACTN_DATA_WIDTH = 48,
	parameter ACTN_STRB_WIDTH = ACTN_DATA_WIDTH/8
) (
	input  wire 							clk,
	input  wire 							rst,

	input  wire [I_DATA_WIDTH-1:0] 			stream_in_data,
	input  wire [I_EMPTY_WIDTH-1:0] 		stream_in_empty,
	input  wire 							stream_in_valid,
	output wire 							stream_in_ready,
	input  wire 							stream_in_startofpacket,
	input  wire 							stream_in_endofpacket,
	input  wire [I_CHANNEL_WIDTH-1:0] 		stream_in_channel,
	input  wire [I_ERROR_WIDTH-1:0] 		stream_in_error,
	input  wire [I_USER_WIDTH-1:0] 			stream_in_tuser,

	output wire [O_DATA_WIDTH-1:0] 			stream_out_data,
	output wire [O_EMPTY_WIDTH-1:0] 		stream_out_empty,
	output wire 							stream_out_valid,
	input  wire 							stream_out_ready,
	output wire 							stream_out_startofpacket,
	output wire 							stream_out_endofpacket,
	output wire [O_CHANNEL_WIDTH-1:0] 		stream_out_channel,
	output wire [O_ERROR_WIDTH-1:0] 		stream_out_error,
	output wire [O_USER_WIDTH-1:0] 			stream_out_tuser,
	
	input  wire [TCAM_ADDR_WIDTH-1:0] 		tcam_wr_addr,
	input  wire [8*TCAM_WR_WIDTH-1:0] 		tcam_wr_data,
	input  wire [8*TCAM_WR_WIDTH-1:0] 		tcam_wr_keep,
	input  wire 							tcam_wr_valid,
	output wire 							tcam_wr_ready,
	input  wire [ACTN_ADDR_WIDTH-1:0] 	action_wr_addr,
	input  wire [ACTN_DATA_WIDTH-1:0] 	action_wr_data,
	input  wire [ACTN_STRB_WIDTH-1:0] 	action_wr_strb,
	input  wire 							action_wr_valid,
	output wire 							action_wr_ready,
	output wire 							action_wr_done
);

localparam PT_WIDTH = 4;

initial begin
	if(I_USER_WIDTH != 4) begin
		$error("Error: Self-defined type width should be 4 (instance %m)");
		$finish;
	end
	if (TCAM_DEPTH > 2**TCAM_ADDR_WIDTH) begin
		$error("Error: TCAM_DEPTH > 2**TCAM_ADDR_WIDTH (instance %m)");
		$finish;
	end
	if(I_USER_WIDTH != PT_WIDTH) begin
		$error("Error: I_USER_WIDTH != PT_WIDTH (instance %m)");
		$finish;
	end
	if(O_USER_WIDTH != ACTN_DATA_WIDTH+PT_WIDTH) begin
		$error("Error: O_USER_WIDTH != ACTN_DATA_WIDTH+PT_WIDTH (instance %m)");
		$finish;
	end
end

/*
 * 1. Input prepare. 
 */
localparam O_DATA_SIZE = O_DATA_WIDTH/dataBitsPerSymbol;
localparam I_DATA_SIZE = I_DATA_WIDTH/dataBitsPerSymbol;
localparam 
	PT_IPV4 = 4'h1,
	PT_VLV4 = 4'h2,
	PT_IPV6 = 4'h3,
	PT_VLV6 = 4'h4;
localparam PL_WIDTH = 8, PS_WIDTH = 6, FWD_WIDTH = 4;
localparam IPv4_ADDR_WIDTH = 32;
localparam IPv6_ADDR_WIDTH = 128;
localparam CL_TCAM_DEPTH = $clog2(TCAM_DEPTH);

wire [IPv4_ADDR_WIDTH-1:0] avst_in_ipv4_dst_vlan, avst_in_ipv4_dst; 
wire [IPv6_ADDR_WIDTH-1:0] avst_in_ipv6_dst_vlan, avst_in_ipv6_dst;
wire [TCAM_DATA_WIDTH-1:0] tcam_cmp_din;

wire [I_USER_WIDTH-1:0] pkt_type = stream_in_tuser;
assign avst_in_ipv4_dst = stream_in_data[271:240];
assign avst_in_ipv4_dst_vlan = stream_in_data[239:208];
assign avst_in_ipv6_dst = stream_in_data[207-:128];				// TODO: error
assign avst_in_ipv6_dst_vlan = stream_in_data[175-:128];		// TODO: error
assign tcam_cmp_din = (
	pkt_type == PT_IPV4 ? {98'b0, avst_in_ipv4_dst} : (
		pkt_type == PT_VLV4 ? {98'b0, avst_in_ipv4_dst_vlan} : (
			pkt_type == PT_IPV6 ? {2'b0, avst_in_ipv6_dst} : (
				pkt_type == PT_VLV6 ? {2'b0, avst_in_ipv6_dst_vlan} : {TCAM_DATA_WIDTH{1'b0}}
			)
		)
	)
);

/* 
Packet Type:
	0x0: 		default
	0x1: 		ipv4
	0x2: 		vlan+ipv4
	0x3: 		ipv6
	0x4: 		vlan+ipv6
*/

/*
 * 2. Pipeline registers assignment
 */
localparam LEVELS = 2;
localparam TCAM_IDX = 0;
localparam ACTN_IDX = 1;

reg  [LEVELS*I_DATA_WIDTH-1:0] 		avst_hdr_data_reg = {LEVELS*I_DATA_WIDTH{1'b0}},		avst_hdr_data_next;
reg  [LEVELS*I_EMPTY_WIDTH-1:0] 	avst_hdr_empty_reg = {LEVELS*I_EMPTY_WIDTH{1'b0}},		avst_hdr_empty_next;
reg  [LEVELS-1:0]					avst_hdr_valid_reg = {LEVELS{1'b0}},					avst_hdr_valid_next;
wire [LEVELS-1:0]					avst_hdr_ready;
reg  [LEVELS-1:0]					avst_hdr_startofpacket_reg = {LEVELS{1'b0}},			avst_hdr_startofpacket_next;
reg  [LEVELS-1:0]					avst_hdr_endofpacket_reg = {LEVELS{1'b0}},				avst_hdr_endofpacket_next;
reg  [LEVELS*I_CHANNEL_WIDTH-1:0] 	avst_hdr_channel_reg = {LEVELS*I_CHANNEL_WIDTH{1'b0}},	avst_hdr_channel_next;
reg  [LEVELS*I_ERROR_WIDTH-1:0] 	avst_hdr_error_reg = {LEVELS*I_ERROR_WIDTH{1'b0}},		avst_hdr_error_next;
reg  [LEVELS*I_USER_WIDTH-1:0] 		avst_hdr_tuser_reg = {LEVELS*I_USER_WIDTH{1'b0}},		avst_hdr_tuser_next;

assign stream_in_ready = avst_hdr_ready[TCAM_IDX];
assign avst_hdr_ready[TCAM_IDX] = !tcam_wr_valid && tcam_wr_ready && action_rd_cmd_ready;
assign avst_hdr_ready[ACTN_IDX] = avst_out_ready_int_reg;

reg  [LEVELS-1:0] tcam_match_valid_reg = {LEVELS{1'b0}}, tcam_match_valid_next;
reg  [TCAM_ADDR_WIDTH-1:0] tcam_match_addr_reg = {TCAM_ADDR_WIDTH{1'b0}}, tcam_match_addr_next;
wire [CL_TCAM_DEPTH-1:0] tcam_match_addr;

integer i;
always @(*) begin
	tcam_match_valid_next = tcam_match_valid_reg;
	tcam_match_addr_next = tcam_match_addr_reg;

	avst_hdr_data_next			 = avst_hdr_data_reg;
	avst_hdr_empty_next			 = avst_hdr_empty_reg;
	avst_hdr_valid_next			 = avst_hdr_valid_reg;
	avst_hdr_startofpacket_next	 = avst_hdr_startofpacket_reg;
	avst_hdr_endofpacket_next	 = avst_hdr_endofpacket_reg;
	avst_hdr_channel_next		 = avst_hdr_channel_reg;
	avst_hdr_error_next			 = avst_hdr_error_reg;
	avst_hdr_tuser_next			 = avst_hdr_tuser_reg;
	for (i=0; i<LEVELS; i=i+1) begin	// Initialization
		if (avst_hdr_valid_reg[i] && avst_hdr_ready[i]) begin	// Deassert valid
			avst_hdr_valid_next[i] = 1'b0;
		end
	end

	for (i=0; i<LEVELS-1; i=i+1) begin
		if (avst_hdr_valid_reg[i] && avst_hdr_ready[i]) begin	// Pass data forward. 
			avst_hdr_data_next[(i+1)*I_DATA_WIDTH +: I_DATA_WIDTH]			 = avst_hdr_data_reg[(i)*I_DATA_WIDTH +: I_DATA_WIDTH];
			avst_hdr_empty_next[(i+1)*I_EMPTY_WIDTH +: I_EMPTY_WIDTH]		 = avst_hdr_empty_reg[(i)*I_EMPTY_WIDTH +: I_EMPTY_WIDTH];
			avst_hdr_valid_next[(i+1)] = 1'b1;
			avst_hdr_startofpacket_next[(i+1)]								 = avst_hdr_startofpacket_reg[(i)];
			avst_hdr_endofpacket_next[(i+1)]								 = avst_hdr_endofpacket_reg[(i)];
			avst_hdr_channel_next[(i+1)*I_CHANNEL_WIDTH +: I_CHANNEL_WIDTH]	 = avst_hdr_channel_reg[(i)*I_CHANNEL_WIDTH +: I_CHANNEL_WIDTH];
			avst_hdr_error_next[(i+1)*I_ERROR_WIDTH +: I_ERROR_WIDTH]		 = avst_hdr_error_reg[(i)*I_ERROR_WIDTH +: I_ERROR_WIDTH];
			avst_hdr_tuser_next[(i+1)*I_USER_WIDTH +: I_USER_WIDTH]			 = avst_hdr_tuser_reg[(i)*I_USER_WIDTH +: I_USER_WIDTH];
			tcam_match_valid_next[(i+1)] = tcam_match_valid_reg[(i)];
		end
	end
	
	if (avst_hdr_valid_reg[TCAM_IDX] && avst_hdr_ready[TCAM_IDX]) begin
		tcam_match_addr_next = tcam_match_valid ? {{TCAM_ADDR_WIDTH-CL_TCAM_DEPTH{1'b0}},tcam_match_addr} : {TCAM_ADDR_WIDTH{1'b1}};
		tcam_match_valid_next[ACTN_IDX] = tcam_match_valid;
	end

	if (stream_in_valid && stream_in_ready) begin
		avst_hdr_data_next[I_DATA_WIDTH-1:0]		 = stream_in_data;
		avst_hdr_empty_next[I_EMPTY_WIDTH-1:0]		 = stream_in_empty;
		avst_hdr_valid_next[0]						 = 1'b1;
		avst_hdr_startofpacket_next[0]				 = stream_in_startofpacket;
		avst_hdr_endofpacket_next[0]				 = stream_in_endofpacket;
		avst_hdr_channel_next[I_CHANNEL_WIDTH-1:0]	 = stream_in_channel;
		avst_hdr_error_next[I_ERROR_WIDTH-1:0]		 = stream_in_error;
		avst_hdr_tuser_next[I_USER_WIDTH-1:0]		 = stream_in_tuser;
	end
end

always @ (posedge clk) begin
	if (rst) begin
		tcam_match_valid_reg <= {LEVELS{1'b0}};
		tcam_match_addr_reg <= {TCAM_ADDR_WIDTH{1'b0}};

		avst_hdr_data_reg			 <= {LEVELS*I_DATA_WIDTH{1'b0}};
		avst_hdr_empty_reg			 <= {LEVELS*I_EMPTY_WIDTH{1'b0}};
		avst_hdr_valid_reg			 <= {LEVELS{1'b0}};
		avst_hdr_startofpacket_reg	 <= {LEVELS{1'b0}};
		avst_hdr_endofpacket_reg	 <= {LEVELS{1'b0}};
		avst_hdr_channel_reg		 <= {LEVELS*I_CHANNEL_WIDTH{1'b0}};
		avst_hdr_error_reg			 <= {LEVELS*I_ERROR_WIDTH{1'b0}};
		avst_hdr_tuser_reg			 <= {LEVELS*I_USER_WIDTH{1'b0}};
	end else begin
		tcam_match_valid_reg <= tcam_match_valid_next;
		tcam_match_addr_reg <= tcam_match_addr_next;

		avst_hdr_data_reg			 <= avst_hdr_data_next;
		avst_hdr_empty_reg			 <= avst_hdr_empty_next;
		avst_hdr_valid_reg			 <= avst_hdr_valid_next;
		avst_hdr_startofpacket_reg	 <= avst_hdr_startofpacket_next;
		avst_hdr_endofpacket_reg	 <= avst_hdr_endofpacket_next;
		avst_hdr_channel_reg		 <= avst_hdr_channel_next;
		avst_hdr_error_reg			 <= avst_hdr_error_next;
		avst_hdr_tuser_reg			 <= avst_hdr_tuser_next;
	end
end


/*
 * 3. Match table using TCAM.  
 */
wire [TCAM_DEPTH-1:0] tcam_match_line;
wire tcam_en, tcam_match_valid;
wire tcam_mt_mch, tcam_sg_mch, tcam_rd_wrn;	// TODO: Not yet used. 

assign tcam_en = !rst;
if (FRACTCAM_ENABLE) begin
	fractcam_top #(
		.TCAM_DEPTH			(TCAM_DEPTH),
		.TCAM_WIDTH			(TCAM_DATA_WIDTH),
		.TCAM_WR_WIDTH		(TCAM_WR_WIDTH)
	) fractcam_top_inst (
		.clk				(clk),
		.rst				(rst),
		.search_key			(tcam_cmp_din),
		.wr_tcam_data		(tcam_wr_data),
		.wr_tcam_keep		(tcam_wr_keep),
		.wr_slicem_addr		(tcam_wr_addr[TCAM_ADDR_WIDTH-1:3]),
		.wr_valid			(tcam_wr_valid),
		.wr_ready			(tcam_wr_ready),
		.match				(tcam_match_line)
	);
	priority_encoder #(
		.WIDTH(TCAM_DEPTH),
		.LSB_HIGH_PRIORITY(1)
	) priority_encoder_inst (
		.input_unencoded	(tcam_match_line),
		.output_valid		(tcam_match_valid),
		.output_encoded		(tcam_match_addr),
		.output_unencoded	()
	);
/*
else
	cam_wrapper cam_wrapper_inst(
		.CLK				(clk),
		.EN					(tcam_en),

		.WE					(tcam_wr_valid_reg),
		.WR_ADDR			(tcam_wr_addr_reg),
		.DIN				(tcam_wr_data_reg),
		.DATA_MASK			(tcam_wr_keep_reg),
		
		.CMP_DIN			(tcam_cmp_din),
		.CMP_DATA_MASK		(tcam_cmp_mask),
		.BUSY				(tcam_wr_ready),
		.MATCH				(tcam_match_valid),
		.MATCH_ADDR			(tcam_match_addr),
		.MULTIPLE_MATCH		(tcam_mt_mch),
		.SINGLE_MATCH		(tcam_sg_mch),
		.READ_WARNING		(tcam_rd_wrn)
	);
*/
end

/*
 * 4. Action table. 
 */
localparam CHANNEL_ENABLE = 1;

wire [ACTN_DATA_WIDTH-1:0] action_rd_data, action_code;
wire action_rd_cmd_valid, action_rd_cmd_ready, action_rd_resp_valid;
wire [ACTN_ADDR_WIDTH-1:0] action_rd_cmd_addr;

assign action_rd_cmd_valid = avst_hdr_valid_reg[TCAM_IDX];
assign action_code = tcam_match_valid_reg[ACTN_IDX] ? action_rd_data : {ACTN_DATA_WIDTH{1'b0}};
assign action_rd_cmd_addr = tcam_match_valid ? {{ACTN_ADDR_WIDTH-CL_TCAM_DEPTH{1'b0}},tcam_match_addr} : {ACTN_ADDR_WIDTH{1'b1}};
// assign action_rd_cmd_addr = tcam_match_addr_reg;

dma_psdpram # (
	.SIZE					(TCAM_DEPTH*ACTN_STRB_WIDTH),
	.SEG_COUNT				(1),
	.SEG_DATA_WIDTH			(ACTN_DATA_WIDTH),
	.SEG_ADDR_WIDTH			(ACTN_ADDR_WIDTH),
	.SEG_BE_WIDTH			(ACTN_STRB_WIDTH),
	.PIPELINE				(1)
) action_tbl_inst (
	.clk					(clk),
	.rst					(rst),
	.wr_cmd_addr			(action_wr_addr),
	.wr_cmd_data			(action_wr_data),
	.wr_cmd_be				(action_wr_strb),
	.wr_cmd_valid			(action_wr_valid),
	.wr_cmd_ready			(action_wr_ready),
	.wr_done				(action_wr_done),
	.rd_cmd_addr			(action_rd_cmd_addr),
	.rd_cmd_valid			(action_rd_cmd_valid),
	.rd_cmd_ready			(action_rd_cmd_ready),
	.rd_resp_data			(action_rd_data),
	.rd_resp_valid			(action_rd_resp_valid),
	.rd_resp_ready			(avst_hdr_ready[ACTN_IDX])
);

/*
 * 5. Datapath control
 */
reg store_avst_int_to_output;
reg store_avst_int_to_temp;
reg store_avst_temp_to_output;
reg avst_out_valid_reg = 1'b0, avst_out_valid_next, avst_out_valid_int;
reg temp_avst_out_valid_reg = 1'b0, temp_avst_out_valid_next;
reg avst_out_ready_int_reg = 1'b0;

reg  [O_DATA_WIDTH-1:0] 	avst_out_data_reg = {O_DATA_WIDTH{1'b0}}, 		temp_avst_out_data_reg = {O_DATA_WIDTH{1'b0}}, 			avst_out_data_int;
reg  [O_EMPTY_WIDTH-1:0] 	avst_out_empty_reg = {O_EMPTY_WIDTH{1'b0}}, 	temp_avst_out_empty_reg = {O_EMPTY_WIDTH{1'b0}}, 		avst_out_empty_int;
reg  						avst_out_startofpacket_reg = 1'b0, 				temp_avst_out_startofpacket_reg = 1'b0, 				avst_out_startofpacket_int;
reg  						avst_out_endofpacket_reg = 1'b0, 				temp_avst_out_endofpacket_reg = 1'b0, 					avst_out_endofpacket_int;
reg  [O_CHANNEL_WIDTH-1:0] 	avst_out_channel_reg = {O_CHANNEL_WIDTH{1'b0}}, temp_avst_out_channel_reg = {O_CHANNEL_WIDTH{1'b0}}, 	avst_out_channel_int;
reg  [O_ERROR_WIDTH-1:0] 	avst_out_error_reg = {O_ERROR_WIDTH{1'b0}}, 	temp_avst_out_error_reg = {O_ERROR_WIDTH{1'b0}}, 		avst_out_error_int;
reg  [O_USER_WIDTH-1:0] 	avst_out_tuser_reg = {O_USER_WIDTH{1'b0}}, 		temp_avst_out_tuser_reg = {O_USER_WIDTH{1'b0}}, 		avst_out_tuser_int;

assign stream_out_data			= avst_out_data_reg;
assign stream_out_empty			= avst_out_empty_reg;
assign stream_out_valid			= avst_out_valid_reg;
assign stream_out_startofpacket	= avst_out_startofpacket_reg;
assign stream_out_endofpacket	= avst_out_endofpacket_reg;
assign stream_out_channel		= avst_out_channel_reg;
assign stream_out_error			= avst_out_error_reg;
assign stream_out_tuser			= avst_out_tuser_reg;

/*
 *  enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
 */
localparam IDX = LEVELS-1;

wire avst_out_ready_int_early = stream_out_ready || (!temp_avst_out_valid_reg && (!avst_out_valid_reg || !avst_out_valid_int));

always @* begin
	avst_out_data_int			 = {avst_hdr_data_reg[IDX*I_DATA_WIDTH +: I_DATA_WIDTH],{O_DATA_WIDTH-I_DATA_WIDTH{1'b0}}};
	avst_out_empty_int			 = avst_hdr_empty_reg[IDX*I_EMPTY_WIDTH +: I_EMPTY_WIDTH]+O_DATA_SIZE-I_DATA_SIZE;
	avst_out_startofpacket_int	 = avst_hdr_startofpacket_reg[IDX];
	avst_out_endofpacket_int	 = avst_hdr_endofpacket_reg[IDX];
	avst_out_channel_int		 = avst_hdr_channel_reg[IDX*I_CHANNEL_WIDTH +: I_CHANNEL_WIDTH];
	avst_out_error_int			 = avst_hdr_error_reg[IDX*I_ERROR_WIDTH +: I_ERROR_WIDTH];
	avst_out_tuser_int			 = {action_code, avst_hdr_tuser_reg[IDX*I_USER_WIDTH +: I_USER_WIDTH]};
	avst_out_valid_int			 = action_rd_resp_valid;
	
	avst_out_valid_next = avst_out_valid_reg;
	temp_avst_out_valid_next = temp_avst_out_valid_reg;

	store_avst_int_to_output = 1'b0;
	store_avst_int_to_temp = 1'b0;
	store_avst_temp_to_output = 1'b0;

	if (avst_out_ready_int_reg) begin
		if (stream_out_ready || !avst_out_valid_reg) begin
			avst_out_valid_next = avst_out_valid_int;
			store_avst_int_to_output = 1'b1;
		end else begin
			temp_avst_out_valid_next = avst_out_valid_int;
			store_avst_int_to_temp = 1'b1;
		end
	end else if (stream_out_ready) begin
		avst_out_valid_next = temp_avst_out_valid_reg;
		temp_avst_out_valid_next = 1'b0;
		store_avst_temp_to_output = 1'b1;
	end
end

always @(posedge clk) begin
	if (rst) begin
		avst_out_valid_reg <= 1'b0;
		avst_out_ready_int_reg <= 1'b0;
		temp_avst_out_valid_reg <= 1'b0;

		avst_out_data_reg <= {O_DATA_WIDTH{1'b0}};
		avst_out_empty_reg <= {O_EMPTY_WIDTH{1'b0}};
		avst_out_startofpacket_reg <= 1'b0;
		avst_out_endofpacket_reg <= 1'b0;
		avst_out_channel_reg <= {O_CHANNEL_WIDTH{1'b0}};
		avst_out_error_reg <= {O_ERROR_WIDTH{1'b0}};
		avst_out_tuser_reg <= {O_USER_WIDTH{1'b0}};
		temp_avst_out_data_reg <= {O_DATA_WIDTH{1'b0}};
		temp_avst_out_empty_reg <= {O_EMPTY_WIDTH{1'b0}};
		temp_avst_out_startofpacket_reg <= 1'b0;
		temp_avst_out_endofpacket_reg <= 1'b0;
		temp_avst_out_channel_reg <= {O_CHANNEL_WIDTH{1'b0}};
		temp_avst_out_error_reg <= {O_ERROR_WIDTH{1'b0}};
		temp_avst_out_tuser_reg <= {O_USER_WIDTH{1'b0}};
	end else begin
		avst_out_valid_reg <= avst_out_valid_next;
		avst_out_ready_int_reg <= avst_out_ready_int_early;
		temp_avst_out_valid_reg <= temp_avst_out_valid_next;
	end

	if (store_avst_int_to_output) begin
		avst_out_data_reg <= avst_out_data_int;
		avst_out_empty_reg <= avst_out_empty_int;
		avst_out_startofpacket_reg <= avst_out_startofpacket_int;
		avst_out_endofpacket_reg <= avst_out_endofpacket_int;
		avst_out_channel_reg <= avst_out_channel_int;
		avst_out_error_reg <= avst_out_error_int;
		avst_out_tuser_reg <= avst_out_tuser_int;
	end else if (store_avst_temp_to_output) begin
		avst_out_data_reg <= temp_avst_out_data_reg;
		avst_out_empty_reg <= temp_avst_out_empty_reg;
		avst_out_startofpacket_reg <= temp_avst_out_startofpacket_reg;
		avst_out_endofpacket_reg <= temp_avst_out_endofpacket_reg;
		avst_out_channel_reg <= temp_avst_out_channel_reg;
		avst_out_error_reg <= temp_avst_out_error_reg;
		avst_out_tuser_reg <= temp_avst_out_tuser_reg;
	end

	if (store_avst_int_to_temp) begin
		temp_avst_out_data_reg <= avst_out_data_int;
		temp_avst_out_empty_reg <= avst_out_empty_int;
		temp_avst_out_startofpacket_reg <= avst_out_startofpacket_int;
		temp_avst_out_endofpacket_reg <= avst_out_endofpacket_int;
		temp_avst_out_channel_reg <= avst_out_channel_int;
		temp_avst_out_error_reg <= avst_out_error_int;
		temp_avst_out_tuser_reg <= avst_out_tuser_int;
	end
end

endmodule

`resetall

/*

TCP/UDP Frame (IPv4)

			Field						Length
[47:0]		Destination MAC address	 	6 octets
[95:48]		Source MAC address			6 octets
[111:96]	Ethertype (0x0800)			2 octets
[115:112]	Version (4)					4 bits
[119:116]	IHL (5-15)					4 bits
[125:120]	DSCP (0)					6 bits
[127:126]	ECN (0)						2 bits
[143:128]	length						2 octets
[159:144]	identification (0?)			2 octets
[162:160]	flags (010)					3 bits
[175:163]	fragment offset (0)			13 bits
[183:176]	time to live (64?)			1 octet
[191:184]	protocol (6 or 17)			1 octet
[207:192]	header checksum				2 octets
[239:208]	source IP					4 octets
[271:240]	destination IP				4 octets
			options						(IHL-5)*4 octets
	
			source port					2 octets
			desination port				2 octets
			other fields + payload

TCP/UDP Frame (IPv6)

			Field						Length
[47:0]		Destination MAC address		6 octets
[95:48]		Source MAC address			6 octets
[111:96]	Ethertype (0x86dd)			2 octets
[115:112]	Version (4)					4 bits
[123:116]	Traffic class				8 bits
[143:124]	Flow label					20 bits
[159:144]	length						2 octets
[167:160]	next header (6 or 17)		1 octet
[175:168]	hop limit					1 octet
[303:176]	source IP					16 octets
[431:304]	destination IP				16 octets

[447:432]	source port					2 octets
[463:448]	desination port				2 octets
			other fields + payload

*/