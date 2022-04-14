/*
 * Created on Sat Feb 19 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 action_pipe.v
 * @Author:		 Jiawei Lin
 * @Last edit:	 11:23:40
 */
/*
	Action Code: size: 16B
		[127:80]	Destination MAC		6 octets
		[79:32]		Source MAC			6 octets
		[31:16]		VLAN Data			2 octets
		[15:8]		Channel				1 octets
		[7:0]		Op. code			1 octets
	Operation code: size 1 byte
		[7]			set DMAC			1 bit
		[6]			set DMAC			1 bit
		[5:4]		VLAN OP				2 bit
					2'b01				insert
					2'b10				remove
					2'b11				modify
		[3]			set Channel 		1 bit
		[2]			Calculate Checksum 	1 bit
		[1:0]		Reserved			2 bit
*/

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Action operation pipeline
 */
module action_pipe #(
	parameter I_DATA_WIDTH = 600,
	parameter I_EMPTY_WIDTH = $clog2(I_DATA_WIDTH/dataBitsPerSymbol),
	parameter I_CHANNEL_WIDTH = 6,
	parameter I_ERROR_WIDTH = 4,
	parameter O_DATA_WIDTH = I_DATA_WIDTH,
	parameter O_EMPTY_WIDTH =  $clog2(O_DATA_WIDTH/dataBitsPerSymbol),
	parameter O_CHANNEL_WIDTH = I_CHANNEL_WIDTH,
	parameter O_ERROR_WIDTH = I_ERROR_WIDTH,
	parameter dataBitsPerSymbol = 8,
	parameter I_USER_WIDTH = 132,
	parameter O_USER_WIDTH = I_USER_WIDTH,
	parameter ACTN_DATA_WIDTH = 128,
	parameter ENABLE = 1
) (
	input  wire clk,
	input  wire rst,

	input  wire [I_DATA_WIDTH-1:0] 		stream_in_data,
	input  wire [I_EMPTY_WIDTH-1:0] 	stream_in_empty,
	input  wire 						stream_in_valid,
	output wire 						stream_in_ready,
	input  wire 						stream_in_startofpacket,
	input  wire 						stream_in_endofpacket,
	input  wire [I_CHANNEL_WIDTH-1:0] 	stream_in_channel,	
	input  wire [I_ERROR_WIDTH-1:0] 	stream_in_error,	
	input  wire [I_USER_WIDTH-1:0] 		stream_in_tuser,

	output wire [O_DATA_WIDTH-1:0] 		stream_out_data,
	output wire [O_EMPTY_WIDTH-1:0] 	stream_out_empty,
	output wire 						stream_out_valid,
	input  wire 						stream_out_ready,
	output wire 						stream_out_startofpacket,
	output wire 						stream_out_endofpacket,
	output wire [O_CHANNEL_WIDTH-1:0] 	stream_out_channel,
	output wire [O_ERROR_WIDTH-1:0] 	stream_out_error,
	output wire [O_USER_WIDTH-1:0] 		stream_out_tuser
);

localparam O_DATA_SIZE = O_DATA_WIDTH/dataBitsPerSymbol;
localparam I_DATA_SIZE = I_DATA_WIDTH/dataBitsPerSymbol;
localparam PT_WIDTH = 4;
localparam 
	PT_IPV4 = 4'h1,
	PT_VLV4 = 4'h2,
	PT_IPV6 = 4'h3,
	PT_VLV6 = 4'h4;
localparam LEVELS = 4;
localparam TTL_WIDTH = 8;
localparam 
	TTL_OFFSET_IPV4 = I_DATA_WIDTH-184,
	TTL_OFFSET_VLV4 = I_DATA_WIDTH-216,
	TTL_OFFSET_IPV6 = I_DATA_WIDTH-176,
	TTL_OFFSET_VLV6 = I_DATA_WIDTH-208;
localparam IPv4_WIDTH = 32;
localparam 
	CSUM_START_IPV4 = I_DATA_WIDTH-272,
	CSUM_START_VLV4 = I_DATA_WIDTH-304,
	CSUM_OFFSET_IPV4 = CSUM_START_IPV4 + IPv4_WIDTH*2,
	CSUM_OFFSET_VLV4 = CSUM_START_VLV4 + IPv4_WIDTH*2;
localparam VD_OFFSET = 34;
localparam OP_CSUM_OFFSET = 2;

initial begin
	if (ACTN_DATA_WIDTH+PT_WIDTH != I_USER_WIDTH) begin
		$error("ACTN_DATA_WIDTH should be 128! %m");
		$error("Error: Self-defined type width should be 4 (instance %m)");
		$finish;
	end
end

/*
 * Pipeline registers assignment. 
 */
wire [I_DATA_WIDTH-1:0] 			stream_hdr_data[LEVELS-1:0];
wire [I_EMPTY_WIDTH-1:0] 			stream_hdr_empty[LEVELS-1:0];
wire [LEVELS-1:0] 					stream_hdr_valid, stream_hdr_ready;
wire [LEVELS-1:0] 					stream_hdr_startofpacket, stream_hdr_endofpacket;
wire [I_CHANNEL_WIDTH-1:0] 			stream_hdr_channel[LEVELS-1:0];
wire [I_ERROR_WIDTH+I_USER_WIDTH-1:0] stream_hdr_error[LEVELS-1:0];

/*
 * 1. Decrease the TTL of packet header 
 */
localparam PT_NUM = 4;

wire [PT_WIDTH-1:0] pkt_type = stream_in_tuser[PT_WIDTH-1:0];
wire [TTL_WIDTH-1:0] ttl_ipv4, ttl_vlv4, ttl_ipv6, ttl_vlv6;
wire [I_DATA_WIDTH*PT_NUM-1:0] stream_ttl_data;
wire [PT_NUM-1:0] stream_ttl_ready;

assign stream_in_ready = |stream_ttl_ready;

if (ENABLE) begin
	assign ttl_ipv4 = stream_in_data[TTL_OFFSET_IPV4 +: TTL_WIDTH]-1;
	assign ttl_vlv4 = stream_in_data[TTL_OFFSET_VLV4 +: TTL_WIDTH]-1;
	assign ttl_ipv6 = stream_in_data[TTL_OFFSET_IPV6 +: TTL_WIDTH]-1;
	assign ttl_vlv6 = stream_in_data[TTL_OFFSET_VLV6 +: TTL_WIDTH]-1;
end else begin
	assign ttl_ipv4 = stream_in_data[TTL_OFFSET_IPV4 +: TTL_WIDTH];
	assign ttl_vlv4 = stream_in_data[TTL_OFFSET_VLV4 +: TTL_WIDTH];
	assign ttl_ipv6 = stream_in_data[TTL_OFFSET_IPV6 +: TTL_WIDTH];
	assign ttl_vlv6 = stream_in_data[TTL_OFFSET_VLV6 +: TTL_WIDTH];
end

set_field_async #(
	.AVST_DATA_WIDTH	(I_DATA_WIDTH),
	.SET_DATA_WIDTH		(TTL_WIDTH),
	.SET_ADDR_OFFSET	(TTL_OFFSET_IPV4)
) ttl_ipv4_inst (
	.set_data			(ttl_ipv4),
	.stream_in_data		(stream_in_data),
	.stream_out_data	(stream_ttl_data[I_DATA_WIDTH-1:0])
);

set_field_async #(
	.AVST_DATA_WIDTH	(I_DATA_WIDTH),
	.SET_DATA_WIDTH		(TTL_WIDTH),
	.SET_ADDR_OFFSET	(TTL_OFFSET_VLV4)
) ttl_vlv4_inst (
	.set_data			(ttl_vlv4),
	.stream_in_data		(stream_in_data),
	.stream_out_data	(stream_ttl_data[1*I_DATA_WIDTH +: I_DATA_WIDTH])
);

set_field_async #(
	.AVST_DATA_WIDTH	(I_DATA_WIDTH),
	.SET_DATA_WIDTH		(TTL_WIDTH),
	.SET_ADDR_OFFSET	(TTL_OFFSET_IPV6)
) ttl_ipv6_inst (
	.set_data			(ttl_ipv6),
	.stream_in_data		(stream_in_data),
	.stream_out_data	(stream_ttl_data[2*I_DATA_WIDTH +: I_DATA_WIDTH])
);

set_field_async #(
	.AVST_DATA_WIDTH	(I_DATA_WIDTH),
	.SET_DATA_WIDTH		(TTL_WIDTH),
	.SET_ADDR_OFFSET	(TTL_OFFSET_VLV6)
) ttl_vlv6_inst (
	.set_data			(ttl_vlv6),
	.stream_in_data		(stream_in_data),
	.stream_out_data	(stream_ttl_data[3*I_DATA_WIDTH +: I_DATA_WIDTH])
);

avst_mux # (
	.S_COUNT					(PT_NUM),
	.DATA_WIDTH					(I_DATA_WIDTH),
	.EMPTY_ENABLE				(1),
	.EMPTY_WIDTH				(I_EMPTY_WIDTH),
	.CHANNEL_ENABLE				(1),
	.CHANNEL_WIDTH				(I_CHANNEL_WIDTH),
	.ERROR_ENABLE				(1),
	.ERROR_WIDTH				(I_ERROR_WIDTH+I_USER_WIDTH)
) ttl_mux_inst (
	.clk						(clk),
	.rst						(rst),

	.stream_in_data				(stream_ttl_data),
	.stream_in_empty			({PT_NUM{stream_in_empty}}),
	.stream_in_valid			({PT_NUM{stream_in_valid}}),
	.stream_in_ready			(stream_ttl_ready),
	.stream_in_startofpacket	({PT_NUM{stream_in_startofpacket}}),
	.stream_in_endofpacket		({PT_NUM{stream_in_endofpacket}}),
	.stream_in_channel			({PT_NUM{stream_in_channel}}),
	.stream_in_error			({PT_NUM{{stream_in_tuser, stream_in_error}}}),

	.stream_out_data			(stream_hdr_data[0]),
	.stream_out_empty			(stream_hdr_empty[0]),
	.stream_out_valid			(stream_hdr_valid[0]),
	.stream_out_ready			(stream_hdr_ready[0]),
	.stream_out_startofpacket	(stream_hdr_startofpacket[0]),
	.stream_out_endofpacket		(stream_hdr_endofpacket[0]),
	.stream_out_channel			(stream_hdr_channel[0]),
	.stream_out_error			(stream_hdr_error[0]),

	.enable						(1'b1),
	.select						(pkt_type-1'b1)
);

/*
 * 2. Set the MAC of packet header 
 */
localparam MAC_WIDTH = 48;
localparam DMAC_OFFSET = I_DATA_WIDTH-MAC_WIDTH;
localparam SMAC_OFFSET = I_DATA_WIDTH-2*MAC_WIDTH;
localparam ERROR_WIDTH = I_ERROR_WIDTH+I_USER_WIDTH;
localparam PT_OFFSET = I_ERROR_WIDTH;
localparam ACTN_OFFSET = PT_OFFSET+PT_WIDTH;
localparam ACTN_DMAC_OFFSET = ACTN_OFFSET+ACTN_DATA_WIDTH-MAC_WIDTH;
localparam ACTN_SMAC_OFFSET = ACTN_OFFSET+ACTN_DATA_WIDTH-2*MAC_WIDTH;
localparam OP_DMAC_OFFSET = 7;
localparam OP_SMAC_OFFSET = 6;

wire [MAC_WIDTH-1:0] dmac_init = stream_hdr_data[0][DMAC_OFFSET +: MAC_WIDTH];
wire [MAC_WIDTH-1:0] smac_init = stream_hdr_data[0][SMAC_OFFSET +: MAC_WIDTH];
wire [MAC_WIDTH-1:0] dmac_act = stream_hdr_error[0][ACTN_DMAC_OFFSET +: MAC_WIDTH];
wire [MAC_WIDTH-1:0] smac_act = stream_hdr_error[0][ACTN_SMAC_OFFSET +: MAC_WIDTH];
wire op_dmac = stream_hdr_error[0][ACTN_OFFSET + OP_DMAC_OFFSET];
wire op_smac = stream_hdr_error[0][ACTN_OFFSET + OP_SMAC_OFFSET];
wire [MAC_WIDTH-1:0] dmac = op_dmac ? dmac_act : dmac_init;
wire [MAC_WIDTH-1:0] smac = op_smac ? smac_act : smac_init;

set_field #(
	.I_DATA_WIDTH				(I_DATA_WIDTH),
	.I_EMPTY_WIDTH				(I_EMPTY_WIDTH),
	.I_CHANNEL_WIDTH			(I_CHANNEL_WIDTH),
	.I_ERROR_WIDTH				(ERROR_WIDTH),
	.O_DATA_WIDTH				(I_DATA_WIDTH),
	.O_EMPTY_WIDTH				(I_EMPTY_WIDTH),
	.O_CHANNEL_WIDTH			(I_CHANNEL_WIDTH),
	.O_ERROR_WIDTH				(ERROR_WIDTH),

	.SET_DATA_WIDTH				(2*MAC_WIDTH),
	.SET_ADDR_OFFSET			(I_DATA_WIDTH-2*MAC_WIDTH)
) set_mac (
	.clk(clk),
	.rst(rst),

	.set_data					({dmac, smac}),
	
	.stream_in_data				(stream_hdr_data[0]),
	.stream_in_empty			(stream_hdr_empty[0]),
	.stream_in_valid			(stream_hdr_valid[0]),
	.stream_in_ready			(stream_hdr_ready[0]),
	.stream_in_startofpacket	(stream_hdr_startofpacket[0]),
	.stream_in_endofpacket		(stream_hdr_endofpacket[0]),
	.stream_in_channel			(stream_hdr_channel[0]),
	.stream_in_error			(stream_hdr_error[0]),

	.stream_out_data			(stream_hdr_data[1]),
	.stream_out_empty			(stream_hdr_empty[1]),
	.stream_out_valid			(stream_hdr_valid[1]),
	.stream_out_ready			(stream_hdr_ready[1]),
	.stream_out_startofpacket	(stream_hdr_startofpacket[1]),
	.stream_out_endofpacket		(stream_hdr_endofpacket[1]),
	.stream_out_channel			(stream_hdr_channel[1]),
	.stream_out_error			(stream_hdr_error[1])
);

/*
 * 3. Calculate header's checksum
 */
localparam CSUM_DATA_WIDTH = 160;
localparam CL_DATA_WIDTH = $clog2(I_DATA_WIDTH);

wire [PT_WIDTH-1:0] hdr_pkt_type_1 = stream_hdr_error[1][PT_OFFSET +: PT_WIDTH];
wire csum_enable = ((hdr_pkt_type_1 == PT_IPV4) || (hdr_pkt_type_1 == PT_VLV4));
wire [CL_DATA_WIDTH-1:0] csum_start, csum_offset;

assign csum_start = (hdr_pkt_type_1 == PT_IPV4) ? CSUM_START_IPV4 : CSUM_START_VLV4;
assign csum_offset = (hdr_pkt_type_1 == PT_IPV4) ? CSUM_OFFSET_IPV4 : CSUM_OFFSET_VLV4;

hdr_csum  #(
	.I_DATA_WIDTH				(I_DATA_WIDTH),
	.I_EMPTY_WIDTH				(I_EMPTY_WIDTH),
	.I_CHANNEL_WIDTH			(I_CHANNEL_WIDTH),
	.I_ERROR_WIDTH				(ERROR_WIDTH),
	.O_DATA_WIDTH				(I_DATA_WIDTH),
	.O_EMPTY_WIDTH				(I_EMPTY_WIDTH),
	.O_CHANNEL_WIDTH			(I_CHANNEL_WIDTH),
	.O_ERROR_WIDTH				(ERROR_WIDTH),
	.CSUM_DATA_WIDTH			(CSUM_DATA_WIDTH),
	.AVST_ADDR_WIDTH			(CL_DATA_WIDTH),
	.ENABLE						(ENABLE)
) hdr_csum_inst (
	.clk(clk),
	.rst(rst),
	
	.csum_enable				(csum_enable),
	.csum_start					(csum_start),
	.csum_offset				(csum_offset),

	.stream_in_data				(stream_hdr_data[1]),
	.stream_in_empty			(stream_hdr_empty[1]),
	.stream_in_valid			(stream_hdr_valid[1]),
	.stream_in_ready			(stream_hdr_ready[1]),
	.stream_in_startofpacket	(stream_hdr_startofpacket[1]),
	.stream_in_endofpacket		(stream_hdr_endofpacket[1]),
	.stream_in_channel			(stream_hdr_channel[1]),
	.stream_in_error			(stream_hdr_error[1]),

	.stream_out_data			(stream_hdr_data[2]),
	.stream_out_empty			(stream_hdr_empty[2]),
	.stream_out_valid			(stream_hdr_valid[2]),
	.stream_out_ready			(stream_hdr_ready[2]),
	.stream_out_startofpacket	(stream_hdr_startofpacket[2]),
	.stream_out_endofpacket		(stream_hdr_endofpacket[2]),
	.stream_out_channel			(stream_hdr_channel[2]),
	.stream_out_error			(stream_hdr_error[2])
);


/*
 * 4. VLAN modification.
 */
localparam OP_VLAN_WIDTH = 2;
localparam OP_VLAN_OFFSET = 4;
localparam ACTN_VLAN_WIDTH = 16;
localparam ACTN_VLAN_OFFSET = 16;

wire [PT_WIDTH-1:0] hdr_pkt_type_2 = stream_hdr_error[2][PT_OFFSET +: PT_WIDTH];
wire [OP_VLAN_WIDTH-1:0] vlan_op;
wire [ACTN_VLAN_WIDTH-1:0] vlan_data;

assign vlan_op = stream_hdr_error[2][ACTN_OFFSET+OP_VLAN_OFFSET +: OP_VLAN_WIDTH];
assign vlan_data = stream_hdr_error[2][ACTN_OFFSET+ACTN_VLAN_OFFSET +: ACTN_VLAN_WIDTH];

vlan_op #(
	.I_DATA_WIDTH				(I_DATA_WIDTH),
	.I_EMPTY_WIDTH				(I_EMPTY_WIDTH),
	.I_CHANNEL_WIDTH			(I_CHANNEL_WIDTH),
	.I_ERROR_WIDTH				(ERROR_WIDTH),
	.O_DATA_WIDTH				(I_DATA_WIDTH),
	.O_EMPTY_WIDTH				(I_EMPTY_WIDTH),
	.O_CHANNEL_WIDTH			(I_CHANNEL_WIDTH),
	.O_ERROR_WIDTH				(ERROR_WIDTH),

	.VLAN_OP_WIDTH				(OP_VLAN_WIDTH),
	.PT_IPV4					(PT_IPV4),
	.PT_VLV4					(PT_VLV4),
	.PT_IPV6					(PT_IPV6),
	.PT_VLV6					(PT_VLV6)
) vlan_op_inst (
	.clk(clk),
	.rst(rst),
	
	.pkt_type					(hdr_pkt_type_2),
	.vlan_op					(vlan_op),
	.vlan_data					(vlan_data),

	.stream_in_data				(stream_hdr_data[2]),
	.stream_in_empty			(stream_hdr_empty[2]),
	.stream_in_valid			(stream_hdr_valid[2]),
	.stream_in_ready			(stream_hdr_ready[2]),
	.stream_in_startofpacket	(stream_hdr_startofpacket[2]),
	.stream_in_endofpacket		(stream_hdr_endofpacket[2]),
	.stream_in_channel			(stream_hdr_channel[2]),
	.stream_in_error			(stream_hdr_error[2]),

	.stream_out_data			(stream_hdr_data[3]),
	.stream_out_empty			(stream_hdr_empty[3]),
	.stream_out_valid			(stream_hdr_valid[3]),
	.stream_out_ready			(stream_hdr_ready[3]),
	.stream_out_startofpacket	(stream_hdr_startofpacket[3]),
	.stream_out_endofpacket		(stream_hdr_endofpacket[3]),
	.stream_out_channel			(stream_hdr_channel[3]),
	.stream_out_error			(stream_hdr_error[3])
);

/*
 * 5. Set channel
*/
localparam OP_FWD_OFFSET = 2;
localparam ACTN_FWD_OFFSET = 8, ACTN_FWD_WIDTH = 8;

wire [ACTN_FWD_WIDTH-1:0] fwd_channel = stream_hdr_error[3][ACTN_OFFSET+ACTN_FWD_OFFSET +: ACTN_FWD_WIDTH];
wire set_channel = stream_hdr_error[3][ACTN_OFFSET+OP_FWD_OFFSET];

/*
 * Output datapath. 
 */
assign stream_out_data = {
	stream_hdr_data[(LEVELS-1)],//*I_DATA_WIDTH +: I_DATA_WIDTH],
	{O_DATA_WIDTH-I_DATA_WIDTH{1'b0}}
};
assign stream_out_empty				 = stream_hdr_empty[(LEVELS-1)]+O_DATA_SIZE-I_DATA_SIZE;
assign stream_out_valid				 = stream_hdr_valid[(LEVELS-1)];
assign stream_hdr_ready[(LEVELS-1)]	 = stream_out_ready;
assign stream_out_startofpacket		 = stream_hdr_startofpacket[(LEVELS-1)];
assign stream_out_endofpacket		 = stream_hdr_endofpacket[(LEVELS-1)];
assign stream_out_channel			 = set_channel ? fwd_channel : stream_hdr_channel[(LEVELS-1)];
assign stream_out_error				 = stream_hdr_error[(LEVELS-1)][I_ERROR_WIDTH-1:0];

endmodule

`resetall