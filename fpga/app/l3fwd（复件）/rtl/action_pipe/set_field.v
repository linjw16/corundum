/*
 * Created on Sat Feb 19 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 set_field.v
 * @Author:		 Jiawei Lin
 * @Last edit:	 14:34:27
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

module set_field #(
	parameter I_DATA_WIDTH = 600,
	parameter I_EMPTY_WIDTH = $clog2(I_DATA_WIDTH/dataBitsPerSymbol),
	parameter I_CHANNEL_WIDTH = 6,
	parameter I_ERROR_WIDTH = 4,
	parameter O_DATA_WIDTH = I_DATA_WIDTH,
	parameter O_EMPTY_WIDTH =  $clog2(O_DATA_WIDTH/dataBitsPerSymbol),
	parameter O_CHANNEL_WIDTH = I_CHANNEL_WIDTH,
	parameter O_ERROR_WIDTH = I_ERROR_WIDTH,
	parameter dataBitsPerSymbol = 8,

	parameter SET_DATA_WIDTH = 8,
	parameter SET_ADDR_OFFSET = 0
)(
	input  wire clk,
	input  wire rst,
	
	input  wire [SET_DATA_WIDTH-1:0]	set_data,
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

initial begin
	if (SET_ADDR_OFFSET+SET_DATA_WIDTH > O_DATA_WIDTH) begin
		$error("no, %m");
		$finish;
	end
end

reg  [O_DATA_WIDTH-1:0] 	stream_in_data_temp = {O_DATA_WIDTH{1'b0}};
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
	
	if (SET_ADDR_OFFSET == 0) begin
		stream_in_data_temp = {
			stream_in_data[I_DATA_WIDTH-1:SET_ADDR_OFFSET+SET_DATA_WIDTH],
			set_data,
			{O_DATA_WIDTH-I_DATA_WIDTH{1'b0}}
		};
	end else if (SET_ADDR_OFFSET+SET_DATA_WIDTH == I_DATA_WIDTH) begin
		stream_in_data_temp = {
			set_data,
			stream_in_data[SET_ADDR_OFFSET-1:0],
			{O_DATA_WIDTH-I_DATA_WIDTH{1'b0}}
		};
	end else begin
		stream_in_data_temp = {
			stream_in_data[I_DATA_WIDTH-1:SET_ADDR_OFFSET+SET_DATA_WIDTH],
			set_data,
			stream_in_data[SET_ADDR_OFFSET-1:0],
			{O_DATA_WIDTH-I_DATA_WIDTH{1'b0}}
		};
	end
	
	if(stream_in_valid && stream_in_ready) begin
		stream_out_data_next = stream_in_data_temp;
		stream_out_empty_next = stream_in_empty+O_DATA_SIZE-I_DATA_SIZE;
		stream_out_valid_next = 1'b1;
		stream_out_startofpacket_next = stream_in_startofpacket;
		stream_out_endofpacket_next = stream_in_endofpacket;
		stream_out_channel_next = stream_in_channel;
		stream_out_error_next = stream_in_error;
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