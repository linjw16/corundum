/*
 * Created on Sat Mar 12 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 set_field_async.v
 * @Author:		 Jiawei Lin
 * @Last edit:	 22:13:45
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

module set_field_async #(
	parameter AVST_DATA_WIDTH = 600,
	parameter SET_DATA_WIDTH = 8,
	parameter SET_ADDR_OFFSET = 0
)(
	input  wire [SET_DATA_WIDTH-1:0]		set_data,
	input  wire [AVST_DATA_WIDTH-1:0] 		stream_in_data,
	output wire [AVST_DATA_WIDTH-1:0] 		stream_out_data
);

initial begin
	if (SET_ADDR_OFFSET+SET_DATA_WIDTH > AVST_DATA_WIDTH) begin
		$error("no, (instance %m)");
		$finish;
	end
end

if (SET_ADDR_OFFSET == 0) begin
	assign stream_out_data = {
		stream_in_data[AVST_DATA_WIDTH-1:SET_ADDR_OFFSET+SET_DATA_WIDTH],
		set_data
	};
end else if (SET_ADDR_OFFSET+SET_DATA_WIDTH == AVST_DATA_WIDTH) begin
	assign stream_out_data = {
		set_data,
		stream_in_data[SET_ADDR_OFFSET-1:0]
	};
end else begin
	assign stream_out_data = {
		stream_in_data[AVST_DATA_WIDTH-1:SET_ADDR_OFFSET+SET_DATA_WIDTH],
		set_data,
		stream_in_data[SET_ADDR_OFFSET-1:0]
	};
end

endmodule