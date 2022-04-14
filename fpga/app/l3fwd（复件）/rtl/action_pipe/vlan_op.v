/*
 * Created on Mon Feb 21 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 vlan_op.v
 * @Author:		 Jiawei Lin
 * @Last edit:	 11:00:43
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Modify VLAN of packet header.
 */
module vlan_op #(
	parameter I_DATA_WIDTH = 512,
	parameter I_EMPTY_WIDTH = $clog2(I_DATA_WIDTH/dataBitsPerSymbol),
	parameter I_CHANNEL_WIDTH = 6,
	parameter I_ERROR_WIDTH = 4,
	parameter O_DATA_WIDTH = I_DATA_WIDTH,
	parameter O_EMPTY_WIDTH =  $clog2(O_DATA_WIDTH/dataBitsPerSymbol),
	parameter O_CHANNEL_WIDTH = I_CHANNEL_WIDTH,
	parameter O_ERROR_WIDTH = I_ERROR_WIDTH,
	parameter dataBitsPerSymbol = 8,

	parameter VLAN_OP_WIDTH = 2,
	parameter PT_WIDTH = 4,
	parameter PT_IPV4 = 4'h1,
	parameter PT_VLV4 = 4'h2,
	parameter PT_IPV6 = 4'h3,
	parameter PT_VLV6 = 4'h4
) (
	input  wire clk,
	input  wire rst,

	input  wire [VLAN_OP_WIDTH-1:0] 	vlan_op,
	input  wire [VLAN_WIDTH-1:0] 		vlan_data,
	input  wire [PT_WIDTH-1:0]			pkt_type,

	input  wire [I_DATA_WIDTH-1:0] 		stream_in_data,
	input  wire [I_EMPTY_WIDTH-1:0] 	stream_in_empty,
	input  wire 						stream_in_valid,
	output wire 						stream_in_ready,
	input  wire 						stream_in_startofpacket,
	input  wire 						stream_in_endofpacket,
	input  wire [I_CHANNEL_WIDTH-1:0] 	stream_in_channel,	
	input  wire [I_ERROR_WIDTH-1:0] 	stream_in_error,	

	output wire [O_DATA_WIDTH-1:0] 		stream_out_data,
	output wire [O_EMPTY_WIDTH-1:0] 	stream_out_empty,
	output wire 						stream_out_valid,
	input  wire 						stream_out_ready,
	output wire 						stream_out_startofpacket,
	output wire 						stream_out_endofpacket,
	output wire [O_CHANNEL_WIDTH-1:0] 	stream_out_channel,
	output wire [O_ERROR_WIDTH-1:0] 	stream_out_error
);

localparam O_DATA_SIZE = O_DATA_WIDTH/dataBitsPerSymbol;
localparam I_DATA_SIZE = I_DATA_WIDTH/dataBitsPerSymbol;
localparam 
	VLAN_INSERT = 2'b01,
	VLAN_MODIFY = 2'b11,
	VLAN_REMOVE = 2'b10;
localparam MAC_WIDTH = 48, MAC_OFFSET = I_DATA_WIDTH-2*MAC_WIDTH;
localparam VTAG_WIDTH = 16, VTAG_TPID = 16'h8100;
localparam VLAN_WIDTH = 16, VLAN_OFFSET = MAC_OFFSET-VTAG_WIDTH-VLAN_WIDTH;

reg  [O_DATA_WIDTH-1:0] 	stream_out_data_reg = {O_DATA_WIDTH{1'b0}}, stream_out_data_next;
reg  [O_EMPTY_WIDTH-1:0] 	stream_out_empty_reg = {O_EMPTY_WIDTH{1'b0}}, stream_out_empty_next;
reg  						stream_out_valid_reg = 1'b0, stream_out_valid_next;
reg  						stream_out_startofpacket_reg = 1'b0, stream_out_startofpacket_next;
reg  						stream_out_endofpacket_reg = 1'b0, stream_out_endofpacket_next;
reg  [O_CHANNEL_WIDTH-1:0] 	stream_out_channel_reg = {O_CHANNEL_WIDTH{1'b0}}, stream_out_channel_next;
reg  [O_ERROR_WIDTH-1:0] 	stream_out_error_reg = {O_ERROR_WIDTH{1'b0}}, stream_out_error_next;

assign stream_out_data = stream_out_data_reg;
assign stream_out_empty = stream_out_empty_reg;
assign stream_out_valid = stream_out_valid_reg;
assign stream_in_ready = !stream_out_valid_reg || stream_out_ready;
assign stream_out_startofpacket = stream_out_startofpacket_reg;
assign stream_out_endofpacket = stream_out_endofpacket_reg;
assign stream_out_channel = stream_out_channel_reg;
assign stream_out_error = stream_out_error_reg;

/* 
	Packet Type:
		0x0: 		default
		0x1: 		ipv4
		0x2: 		vlan+ipv4
		0x3: 		ipv6
		0x4: 		vlan+ipv6
*/
always @(*) begin
	stream_out_data_next = stream_out_data_reg;
	stream_out_empty_next = stream_out_empty_reg;
	stream_out_valid_next = stream_out_valid_reg;
	stream_out_startofpacket_next = stream_out_startofpacket_reg;
	stream_out_endofpacket_next = stream_out_endofpacket_reg;
	stream_out_channel_next = stream_out_channel_reg;
	stream_out_error_next = stream_out_error_reg;

	if(stream_out_valid && stream_out_ready) begin
		stream_out_valid_next = 1'b0;
	end
	
	if(stream_in_valid && stream_in_ready) begin
		stream_out_data_next = stream_in_data;
		stream_out_empty_next = stream_in_empty;
		stream_out_valid_next = 1'b1;
		stream_out_startofpacket_next = stream_in_startofpacket;
		stream_out_endofpacket_next = stream_in_endofpacket;
		stream_out_channel_next = stream_in_channel;
		stream_out_error_next = stream_in_error;

		case (vlan_op)
			VLAN_INSERT: begin
				if (pkt_type == PT_IPV4 || pkt_type == PT_IPV6) begin
					stream_out_data_next = {
						stream_in_data[MAC_OFFSET +: 2*MAC_WIDTH],
						VTAG_TPID,
						vlan_data,
						stream_in_data[MAC_OFFSET-1 : VTAG_WIDTH+VLAN_WIDTH],
						{O_DATA_WIDTH-I_DATA_WIDTH{1'b0}}
					};
					stream_out_empty_next = stream_in_empty+O_DATA_SIZE-I_DATA_SIZE-4;
				end 
			end
			VLAN_MODIFY: begin	// TODO: UT
				if (pkt_type == PT_VLV4 || pkt_type == PT_VLV6) begin
					stream_out_data_next = {
						stream_in_data[MAC_OFFSET +: 2*MAC_WIDTH],
						VTAG_TPID,
						vlan_data,
						stream_in_data[VLAN_OFFSET-1:0],
						{O_DATA_WIDTH-I_DATA_WIDTH{1'b0}}
					};
					stream_out_empty_next = stream_in_empty+O_DATA_SIZE-I_DATA_SIZE;
				end
			end
			VLAN_REMOVE: begin	// TODO: UT
				if (pkt_type == PT_VLV4 || pkt_type == PT_VLV6) begin
					stream_out_data_next = {
						stream_in_data[MAC_OFFSET +: 2*MAC_WIDTH],
						stream_in_data[VLAN_OFFSET-1:0],
						{VTAG_WIDTH+VLAN_WIDTH{1'b0}},
						{O_DATA_WIDTH-I_DATA_WIDTH{1'b0}}
					};
					stream_out_empty_next = stream_in_empty+O_DATA_SIZE-I_DATA_SIZE+4;
				end
			end
			default: begin	// 2'b00
			end
		endcase
	end
end

always @(posedge clk) begin
	if (rst) begin
		stream_out_data_reg = {O_DATA_WIDTH{1'b0}};
		stream_out_empty_reg = {O_EMPTY_WIDTH{1'b0}};
		stream_out_valid_reg = 1'b0;
		stream_out_startofpacket_reg = 1'b0;
		stream_out_endofpacket_reg = 1'b0;
		stream_out_channel_reg = {O_CHANNEL_WIDTH{1'b0}};
		stream_out_error_reg = {O_ERROR_WIDTH{1'b0}};
	end else begin
		stream_out_data_reg <= stream_out_data_next;
		stream_out_empty_reg <= stream_out_empty_next;
		stream_out_valid_reg <= stream_out_valid_next;
		stream_out_startofpacket_reg <= stream_out_startofpacket_next;
		stream_out_endofpacket_reg <= stream_out_endofpacket_next;
		stream_out_channel_reg <= stream_out_channel_next;
		stream_out_error_reg <= stream_out_error_next;
	end
end

endmodule

`resetall

/*

TCP/UDP Frame (IPv4)

			Field						Length
[47:0]		Destination MAC address	 	6 octets
[95:48]		Source MAC address			6 octets
[]			VLAN Tag					4 octets
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

VLAN Tag in 802.1Q:

[31:16]		Tag Protocol Identifier		2 octets	0x8100
[15:13]		Priority					3 bits 		0~7
[12]		Cannonical Format Indicator	1 bits		0 for Ethernet
[11:0]		VLAN Identifier				12 bits		1~4094

*/