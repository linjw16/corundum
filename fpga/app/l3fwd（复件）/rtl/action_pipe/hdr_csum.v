/*
 * Created on Sat Feb 26 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 hdr_csum.v
 * @Author:		 Jiawei Lin
 * @Last edit:	 23:17:59
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Header checksum offload module
 */
module hdr_csum  #(
	parameter I_DATA_WIDTH = 600,
	parameter I_EMPTY_WIDTH = $clog2(I_DATA_WIDTH/dataBitsPerSymbol),
	parameter I_CHANNEL_WIDTH = 6,
	parameter I_ERROR_WIDTH = 4,
	parameter O_DATA_WIDTH = I_DATA_WIDTH,
	parameter O_EMPTY_WIDTH =  $clog2(O_DATA_WIDTH/dataBitsPerSymbol),
	parameter O_CHANNEL_WIDTH = I_CHANNEL_WIDTH,
	parameter O_ERROR_WIDTH = I_ERROR_WIDTH,
	parameter dataBitsPerSymbol = 8,

	parameter CSUM_DATA_WIDTH = 160,
	parameter AVST_ADDR_WIDTH = 9,
	parameter ENABLE = 1
)(
	input  wire clk,
	input  wire rst,
	
	input  wire 						csum_enable,
	input  wire [AVST_ADDR_WIDTH-1:0]	csum_start,
	input  wire [AVST_ADDR_WIDTH-1:0]	csum_offset,

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
localparam CSUM_WIDTH = 16;

reg  [CSUM_DATA_WIDTH-1:0] ip_hdr;
wire [CSUM_WIDTH-1:0] a_0, a_1, a_2, a_3, a_4, a_5, a_6, a_7, a_8, a_9;
wire [CSUM_WIDTH+4:0] sum;
reg  [CSUM_WIDTH+1:0] csum;

assign {a_0, a_1, a_2, a_3, a_4, a_5, a_6, a_7, a_8, a_9} = ip_hdr;
assign sum = a_0+a_1+a_2+a_3+a_4+a_6+a_7+a_8+a_9;

reg  [O_DATA_WIDTH-1:0] 	stream_out_data_reg = {O_DATA_WIDTH{1'b0}}, stream_out_data_next;
reg  [O_EMPTY_WIDTH-1:0] 	stream_out_empty_reg = {O_EMPTY_WIDTH{1'b0}}, stream_out_empty_next;
reg  						stream_out_valid_reg = 1'b0, stream_out_valid_next;
reg  						stream_out_startofpacket_reg = 1'b0, stream_out_startofpacket_next;
reg  						stream_out_endofpacket_reg = 1'b0, stream_out_endofpacket_next;
reg  [O_CHANNEL_WIDTH-1:0] 	stream_out_channel_reg = {O_CHANNEL_WIDTH{1'b0}}, stream_out_channel_next;
reg  [O_ERROR_WIDTH-1:0] 	stream_out_error_reg = {O_ERROR_WIDTH{1'b0}}, stream_out_error_next;

if (ENABLE) begin
	assign stream_out_data = stream_out_data_reg;
	assign stream_out_empty = stream_out_empty_reg;
	assign stream_out_valid = stream_out_valid_reg;
	assign stream_in_ready = !stream_out_valid_reg || stream_out_ready;
	assign stream_out_startofpacket = stream_out_startofpacket_reg;
	assign stream_out_endofpacket = stream_out_endofpacket_reg;
	assign stream_out_channel = stream_out_channel_reg;
	assign stream_out_error = stream_out_error_reg;
end else begin
	assign stream_out_data = stream_in_data;
	assign stream_out_empty = stream_in_empty;
	assign stream_out_valid = stream_in_valid;
	assign stream_in_ready = stream_out_ready;
	assign stream_out_startofpacket = stream_in_startofpacket;
	assign stream_out_endofpacket = stream_in_endofpacket;
	assign stream_out_channel = stream_in_channel;
	assign stream_out_error = stream_in_error;
end
// assign stream_out_data = stream_out_data_reg;
// assign stream_out_empty = stream_out_empty_reg;
// assign stream_out_valid = stream_out_valid_reg;
// assign stream_in_ready = !stream_out_valid_reg || stream_out_ready;
// assign stream_out_startofpacket = stream_out_startofpacket_reg;
// assign stream_out_endofpacket = stream_out_endofpacket_reg;
// assign stream_out_channel = stream_out_channel_reg;
// assign stream_out_error = stream_out_error_reg;

always @(*) begin
	stream_out_data_next = stream_out_data_reg;
	stream_out_empty_next = stream_out_empty_reg;
	stream_out_valid_next = stream_out_valid_reg;
	stream_out_startofpacket_next = stream_out_startofpacket_reg;
	stream_out_endofpacket_next = stream_out_endofpacket_reg;
	stream_out_channel_next = stream_out_channel_reg;
	stream_out_error_next = stream_out_error_reg;

	if (stream_out_valid && stream_out_ready) begin
		stream_out_valid_next = 1'b0;
	end

	if(stream_in_valid && stream_in_ready) begin
		stream_out_data_next = stream_in_data;
		stream_out_empty_next = stream_in_empty+O_DATA_SIZE-I_DATA_SIZE;
		stream_out_valid_next = 1'b1;
		stream_out_startofpacket_next = stream_in_startofpacket;
		stream_out_endofpacket_next = stream_in_endofpacket;
		stream_out_channel_next = stream_in_channel;
		stream_out_error_next = stream_in_error;
		
		ip_hdr = stream_in_data[csum_start +: CSUM_DATA_WIDTH];
		csum = sum[CSUM_WIDTH +: 4] + sum[CSUM_WIDTH-1:0];
		csum = csum[CSUM_WIDTH +: 1] + csum[CSUM_WIDTH-1:0];
		stream_out_data_next[csum_offset +: 16] = ~csum;
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
