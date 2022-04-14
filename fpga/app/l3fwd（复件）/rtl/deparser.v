/*
 * Created on Sat Mar 05 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 deparser.v
 * @Author:		 Jiawei Lin
 * @Last edit:	 12:58:26
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Deparser merge modified header and payload. 
 */
module deparser # (
	parameter I_DATA_WIDTH = 512,
	parameter I_EMPTY_WIDTH = $clog2(I_DATA_WIDTH/dataBitsPerSymbol+1),
	parameter I_CHANNEL_WIDTH = 6,
	parameter I_ERROR_WIDTH = 4,
	parameter O_DATA_WIDTH = I_DATA_WIDTH,
	parameter O_EMPTY_WIDTH = $clog2(O_DATA_WIDTH/dataBitsPerSymbol+1),
	parameter O_CHANNEL_WIDTH = I_CHANNEL_WIDTH,
	parameter O_ERROR_WIDTH = I_ERROR_WIDTH,
	parameter HDR_DATA_WIDTH = 1024,
	parameter HDR_EMPTY_WIDTH =  $clog2(HDR_DATA_WIDTH/dataBitsPerSymbol),
	parameter HDR_CHANNEL_WIDTH = I_CHANNEL_WIDTH,
	parameter HDR_ERROR_WIDTH = I_ERROR_WIDTH,
	parameter dataBitsPerSymbol = 8
) (
	input  wire clk,
	input  wire rst,

	input  wire [HDR_DATA_WIDTH-1:0] 	stream_in_hdr_data,
	input  wire [HDR_EMPTY_WIDTH-1:0] 	stream_in_hdr_empty,
	input  wire 						stream_in_hdr_valid,
	output wire 						stream_in_hdr_ready,
	input  wire 						stream_in_hdr_startofpacket,
	input  wire 						stream_in_hdr_endofpacket,
	input  wire [HDR_CHANNEL_WIDTH-1:0] stream_in_hdr_channel,
	input  wire [HDR_ERROR_WIDTH-1:0] 	stream_in_hdr_error,

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
	if (I_DATA_WIDTH > O_DATA_WIDTH) begin
		$error("I_DATA_WIDTH > O_DATA_WIDTH, Not support yet. (inst %m)");
		$finish;
	end
	if (I_DATA_WIDTH > HDR_DATA_WIDTH) begin
		$error("I_DATA_WIDTH > HDR_DATA_WIDTH, Not support yet. (inst %m)");
		$finish;
	end
end

/*
 * 1. Payload buffer. 
 */
wire [I_DATA_WIDTH-1:0] 			stream_fifo_data;
wire [O_DATA_WIDTH-1:0] 			stream_fifo_data_pad = {stream_fifo_data, {O_DATA_WIDTH-I_DATA_WIDTH{1'b0}}};
wire [I_EMPTY_WIDTH-1:0] 			stream_fifo_empty;
wire 								stream_fifo_valid;
wire 								stream_fifo_ready;
reg 								stream_fifo_ready_reg = 1'b0, stream_fifo_ready_next;
wire 								stream_fifo_startofpacket;
wire 								stream_fifo_endofpacket;
wire [I_CHANNEL_WIDTH-1:0] 			stream_fifo_channel;
wire [I_ERROR_WIDTH-1:0] 			stream_fifo_error;

assign stream_fifo_ready = stream_fifo_ready_reg;

avst_fifo # (
	.DEPTH							(512), /* 9214 32768 */// write tcam delay 
	.DATA_WIDTH						(I_DATA_WIDTH),
	.EMPTY_ENABLE					(1),
	.EMPTY_WIDTH					(I_EMPTY_WIDTH),
	.SOP_ENABLE						(1),
	.EOP_ENABLE						(1),
	.CHANNEL_ENABLE					(1),
	.CHANNEL_WIDTH					(I_CHANNEL_WIDTH),
	.ERROR_ENABLE					(1),
	.ERROR_WIDTH					(I_ERROR_WIDTH),
	.PIPELINE_OUTPUT				(1),
	.FRAME_FIFO						(0),
	.ERROR_BAD_FRAME_VALUE			(0),
	.ERROR_BAD_FRAME_MASK			(0),
	.DROP_OVERSIZE_FRAME			(0),
	.DROP_BAD_FRAME					(0),
	.DROP_WHEN_FULL					(0)
) avst_fifo_inst (
	.clk							(clk),
	.rst							(rst),
	.avst_in_data					(stream_in_data),
	.avst_in_empty					(stream_in_empty),
	.avst_in_valid					(stream_in_valid),
	.avst_in_ready					(stream_in_ready),
	.avst_in_startofpacket			(stream_in_startofpacket),
	.avst_in_endofpacket			(stream_in_endofpacket),
	.avst_in_channel				(stream_in_channel),
	.avst_in_error					(stream_in_error),
	.avst_out_data					(stream_fifo_data),
	.avst_out_empty					(stream_fifo_empty),
	.avst_out_valid					(stream_fifo_valid),
	.avst_out_ready					(stream_fifo_ready),
	.avst_out_startofpacket			(stream_fifo_startofpacket),
	.avst_out_endofpacket			(stream_fifo_endofpacket),
	.avst_out_channel				(stream_fifo_channel),
	.avst_out_error					(stream_fifo_error),
	.status_overflow				(),
	.status_bad_frame				(),
	.status_good_frame				()
);

/*
 * 2. An FSM for transport
 */

localparam HL_WIDTH = 8, HL_OFFSET = 0;
localparam OFFSET_WIDTH = $clog2(HDR_DATA_WIDTH+1);
localparam HDR_DATA_SIZE = HDR_DATA_WIDTH / dataBitsPerSymbol;
localparam ST_WIDTH = 3,
	ST_IDLE		 = 3'h0,
	ST_OUT		 = 3'h1,
	ST_MERGE	 = 3'h2,
	ST_LAST		 = 3'h3;

reg  [HDR_DATA_WIDTH-1:0]	temp_data_reg = {HDR_DATA_WIDTH{1'b0}}, 	temp_data_next;
reg  [O_EMPTY_WIDTH-1:0] 	temp_empty_reg = {O_EMPTY_WIDTH{1'b0}}, 	temp_empty_next;
reg  						temp_startofpacket_reg = 1'b0, 				temp_startofpacket_next;
reg  						temp_endofpacket_reg = 1'b0, 				temp_endofpacket_next;
reg  [O_CHANNEL_WIDTH-1:0] 	temp_channel_reg = {O_CHANNEL_WIDTH{1'b0}}, temp_channel_next;
reg  [O_ERROR_WIDTH-1:0] 	temp_error_reg = {O_ERROR_WIDTH{1'b0}}, 	temp_error_next;

reg  [OFFSET_WIDTH-1:0] 	temp_width_reg = {OFFSET_WIDTH{1'b0}}, 		temp_width_next;	// TODO: replace width with empty
reg  [OFFSET_WIDTH-1:0] 	temp_bias_reg = {OFFSET_WIDTH{1'b0}}, 		temp_bias_next;

reg  stream_in_hdr_ready_reg = 1'b0, stream_in_hdr_ready_next;
reg  [ST_WIDTH-1:0] state_reg = ST_IDLE, state_next;
reg  [HL_WIDTH-1:0] hdr_len_reg = {HL_WIDTH{1'b0}}, hdr_len_next;

assign stream_in_hdr_ready = stream_in_hdr_ready_reg;	// TODO: get invoved with FSM

always @(*) begin
	state_next = state_reg;
	hdr_len_next = hdr_len_reg;

	avst_out_data_int			= temp_data_reg;
	avst_out_empty_int			= temp_empty_reg;
	avst_out_valid_int			= 1'b0;
	avst_out_startofpacket_int	= temp_startofpacket_reg;
	avst_out_endofpacket_int	= temp_endofpacket_reg;
	avst_out_channel_int		= temp_channel_reg;
	avst_out_error_int			= temp_error_reg;

	temp_data_next = temp_data_reg;
	temp_empty_next = temp_empty_reg;
	temp_startofpacket_next = temp_startofpacket_reg;
	temp_endofpacket_next = temp_endofpacket_reg;
	temp_channel_next = temp_channel_reg;
	temp_error_next = temp_error_reg;

	temp_width_next = temp_width_reg;
	temp_bias_next = temp_bias_reg;

	stream_in_hdr_ready_next = stream_in_hdr_ready_reg;
	stream_fifo_ready_next = stream_fifo_ready_reg;

	case (state_reg)
		ST_IDLE: begin
			stream_in_hdr_ready_next = 1'b1;
			if (stream_in_hdr_valid && stream_in_hdr_ready) begin
				state_next = ST_OUT;
				hdr_len_next = HDR_DATA_SIZE-stream_in_hdr_empty;
				stream_in_hdr_ready_next = 1'b0;
				stream_fifo_ready_next = 1'b1;		/* drop the start of packet */

				temp_data_next = stream_in_hdr_data;
				temp_empty_next = stream_in_hdr_empty;
				temp_startofpacket_next = stream_in_hdr_startofpacket & 1'b1;
				temp_endofpacket_next = stream_in_hdr_endofpacket;
				temp_channel_next = stream_in_hdr_channel;	/* assign once upon a frame */
				temp_error_next = stream_in_hdr_error;
			end
		end
		ST_OUT: begin /* stay one cycle */
			stream_fifo_ready_next = avst_out_ready_int_early;
			if (stream_fifo_valid && stream_fifo_ready_reg) begin
				stream_fifo_ready_next = !stream_fifo_endofpacket;
				if (hdr_len_reg > O_DATA_SIZE) begin
					state_next = stream_fifo_endofpacket ? ST_LAST : ST_MERGE;
					temp_data_next = temp_data_reg >> ((HDR_DATA_SIZE-hdr_len_reg)<<3);
					temp_bias_next = ((O_DATA_SIZE<<1)-hdr_len_reg);
					temp_width_next = (hdr_len_reg - O_DATA_SIZE);
					temp_error_next = stream_fifo_error;
					temp_startofpacket_next = 1'b0;

					avst_out_data_int = temp_data_reg[HDR_DATA_WIDTH-1 -: O_DATA_WIDTH];
					avst_out_empty_int = {O_EMPTY_WIDTH{1'b0}};
					avst_out_valid_int = 1'b1;
					avst_out_startofpacket_int = 1'b1;
					avst_out_endofpacket_int = 1'b0;
				end else if (stream_fifo_endofpacket) begin
					state_next = ST_IDLE;				/* Bonding	 */
					stream_in_hdr_ready_next = 1'b1;	/* Together	 */
					avst_out_data_int = temp_data_reg[HDR_DATA_WIDTH-1 -: O_DATA_WIDTH];
					avst_out_empty_int = O_DATA_SIZE-hdr_len_reg;
					avst_out_valid_int = 1'b1;
					avst_out_startofpacket_int = 1'b1;
					avst_out_endofpacket_int = 1'b1;
				end else begin
					state_next = ST_MERGE;
					temp_data_next = temp_data_reg >> ((HDR_DATA_SIZE - hdr_len_reg)<<3);
					temp_bias_next = (O_DATA_SIZE-hdr_len_reg);
					temp_width_next = hdr_len_reg;
					temp_startofpacket_next = 1'b1;
				end
			end
		end
		ST_MERGE: begin
			stream_fifo_ready_next = avst_out_ready_int_early;
			if (stream_fifo_valid && stream_fifo_ready_reg) begin
				temp_data_next = stream_fifo_data_pad >> ((stream_fifo_empty+O_DATA_SIZE-I_DATA_SIZE) << 3);
				temp_width_next = (I_DATA_SIZE-stream_fifo_empty-temp_bias_reg);
				temp_bias_next = (stream_fifo_empty+temp_bias_reg+O_DATA_SIZE-I_DATA_SIZE);
				temp_startofpacket_next = 1'b0;
				temp_error_next = stream_fifo_error;

				avst_out_data_int = (temp_data_reg << (temp_bias_reg<<3)) | (stream_fifo_data_pad >> (temp_width_reg<<3));
				avst_out_empty_int = {O_EMPTY_WIDTH{1'b0}};
				avst_out_valid_int = 1'b1;
				avst_out_endofpacket_int = 1'b0;
				avst_out_error_int = stream_fifo_error;

				if (stream_fifo_endofpacket) begin	// TODO: wider ouput
					stream_fifo_ready_next = 1'b0;
					if (temp_bias_reg >= (I_DATA_SIZE-stream_fifo_empty)) begin
						state_next = ST_IDLE;
						stream_in_hdr_ready_next = 1'b1;
						avst_out_empty_int = (temp_bias_reg-I_DATA_SIZE+stream_fifo_empty);
						avst_out_endofpacket_int = 1'b1;
					end else begin
						state_next = ST_LAST;
					end
				end
			end
		end
		ST_LAST: begin
			if (avst_out_ready_int_reg) begin
				state_next = ST_IDLE;
				stream_in_hdr_ready_next = 1'b1;
				avst_out_data_int = temp_data_reg << (temp_bias_reg<<3);
				avst_out_empty_int = temp_bias_reg;
				avst_out_valid_int = 1'b1;
				avst_out_startofpacket_int = 1'b0;
				avst_out_endofpacket_int = 1'b1;
			end
		end
		default: begin
			
		end
	endcase
end

always @(posedge clk) begin
	temp_data_reg <= temp_data_next;
	temp_empty_reg <= temp_empty_next;
	temp_startofpacket_reg <= temp_startofpacket_next;
	temp_endofpacket_reg <= temp_endofpacket_next;
	temp_channel_reg <= temp_channel_next;
	temp_error_reg <= temp_error_next;

	temp_width_reg <= temp_width_next;
	temp_bias_reg <= temp_bias_next;

	state_reg <= state_next;
	hdr_len_reg <= hdr_len_next;
	stream_fifo_ready_reg <= stream_fifo_ready_next;
	stream_in_hdr_ready_reg <= stream_in_hdr_ready_next;
end

/*
 * 5. Output datapath
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

assign stream_out_data			= avst_out_data_reg;
assign stream_out_empty			= avst_out_empty_reg;
assign stream_out_valid			= avst_out_valid_reg;
assign stream_out_startofpacket	= avst_out_startofpacket_reg;
assign stream_out_endofpacket	= avst_out_endofpacket_reg;
assign stream_out_channel		= avst_out_channel_reg;
assign stream_out_error			= avst_out_error_reg;

/*
 *  enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
 */

wire avst_out_ready_int_early = stream_out_ready || (!temp_avst_out_valid_reg && (!avst_out_valid_reg || !avst_out_valid_int));

always @* begin
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
		temp_avst_out_data_reg <= {O_DATA_WIDTH{1'b0}};
		temp_avst_out_empty_reg <= {O_EMPTY_WIDTH{1'b0}};
		temp_avst_out_startofpacket_reg <= 1'b0;
		temp_avst_out_endofpacket_reg <= 1'b0;
		temp_avst_out_channel_reg <= {O_CHANNEL_WIDTH{1'b0}};
		temp_avst_out_error_reg <= {O_ERROR_WIDTH{1'b0}};
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
	end else if (store_avst_temp_to_output) begin
		avst_out_data_reg <= temp_avst_out_data_reg;
		avst_out_empty_reg <= temp_avst_out_empty_reg;
		avst_out_startofpacket_reg <= temp_avst_out_startofpacket_reg;
		avst_out_endofpacket_reg <= temp_avst_out_endofpacket_reg;
		avst_out_channel_reg <= temp_avst_out_channel_reg;
		avst_out_error_reg <= temp_avst_out_error_reg;
	end

	if (store_avst_int_to_temp) begin
		temp_avst_out_data_reg <= avst_out_data_int;
		temp_avst_out_empty_reg <= avst_out_empty_int;
		temp_avst_out_startofpacket_reg <= avst_out_startofpacket_int;
		temp_avst_out_endofpacket_reg <= avst_out_endofpacket_int;
		temp_avst_out_channel_reg <= avst_out_channel_int;
		temp_avst_out_error_reg <= avst_out_error_int;
	end
end

endmodule

`resetall

/*
 * 
 * Header:         [<-- hdr_len_reg Bytes ------>XXXXXXXXXXXXXXXXXXXXX]
 * Stream in:              [<-- 64 Bytes payload ---------------->]
 * 
 * Temp data:      [XXXXXXX|XXXX temp_bias XXXX|<-- temp_width -->]
 * Stream out:             [<-- 64B Merged out ------------------>]
 * 
*/