/*
 * Created on Mon Feb 28 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 parser.v
 * @Author:		 Meng Sha, Jiawei Lin
 * @Last edit:	 16:00:08
 */

`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 * Network packet header parser.
 */
module parser #(
	parameter I_DATA_WIDTH = 512,
	parameter I_EMPTY_WIDTH = $clog2(I_DATA_WIDTH/dataBitsPerSymbol+1),
	parameter I_ERROR_WIDTH = 1,
	parameter I_CHANNEL_WIDTH = 1,
	parameter O_DATA_WIDTH = I_DATA_WIDTH,
	parameter O_EMPTY_WIDTH =  $clog2(O_DATA_WIDTH/dataBitsPerSymbol+1),
	parameter O_ERROR_WIDTH = I_ERROR_WIDTH,
	parameter O_CHANNEL_WIDTH = I_CHANNEL_WIDTH,
	parameter HDR_DATA_WIDTH = I_DATA_WIDTH,
	parameter HDR_EMPTY_WIDTH =  $clog2(HDR_DATA_WIDTH/dataBitsPerSymbol+1),
	parameter HDR_ERROR_WIDTH = I_ERROR_WIDTH,
	parameter HDR_CHANNEL_WIDTH = I_CHANNEL_WIDTH,
	parameter dataBitsPerSymbol = 8
) (
	input  wire 						clk,
	input  wire 						rst,

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
	output wire [O_ERROR_WIDTH-1:0] 	stream_out_error,

	output wire [HDR_DATA_WIDTH-1:0] 	stream_hdr_data,
	output wire [HDR_EMPTY_WIDTH-1:0] 	stream_hdr_empty,
	output wire 						stream_hdr_valid,
	input  wire 						stream_hdr_ready,
	output wire 						stream_hdr_startofpacket,
	output wire 						stream_hdr_endofpacket,
	output wire [HDR_CHANNEL_WIDTH-1:0] stream_hdr_channel,
	output wire [HDR_ERROR_WIDTH-1:0] 	stream_hdr_error,

	output wire [47:0]					des_mac,
	output wire [47:0]					src_mac,
	output wire [15:0]					eth_type,
	output wire [31:0]					des_ipv4,
	output wire [31:0]					src_ipv4,
	output wire [127:0]					des_ipv6,
	output wire [127:0]					src_ipv6,
	output wire [15:0]					des_port,
	output wire [15:0]					src_port,

	output wire 						vlan_tag,
	output wire 						qinq_tag,
	output wire 						arp_tag,
	output wire 						lldp_tag,
	output wire 						ipv4_tag,
	output wire 						ipv6_tag,
	output wire 						tcp_tag,
	output wire 						udp_tag,
	output wire 						seadp_tag,

	output wire [3:0]					pkt_type 
);

localparam DATA_SIZE = I_DATA_WIDTH / dataBitsPerSymbol;
localparam CYCLE_COUNT = (68+DATA_SIZE-1)/DATA_SIZE;
localparam PTR_WIDTH = $clog2(CYCLE_COUNT);
localparam MAC_SIZE = 6;
localparam IPV4_WIDTH = 4;
localparam IPV6_WIDTH = 16;
localparam PORT_WIDTH = 2;

reg  [PTR_WIDTH-1:0] ptr_reg = 0, ptr_next;

reg  [47:0] des_mac_reg = 48'd0, des_mac_next;
reg  [47:0] src_mac_reg = 48'd0, src_mac_next;
reg  [15:0] eth_type_reg = 15'd0, eth_type_next;
reg  [15:0] eth_type_vlan_reg = 15'd0, eth_type_vlan_next;
reg  [31:0] des_ipv4_reg = 32'd0, des_ipv4_next;
reg  [31:0] src_ipv4_reg = 32'd0, src_ipv4_next;
reg  [127:0] des_ipv6_reg = 128'd0, des_ipv6_next;
reg  [127:0] src_ipv6_reg = 128'd0, src_ipv6_next;
reg  [15:0] des_port_reg = 16'd0, des_port_next;
reg  [15:0] src_port_reg = 16'd0, src_port_next;
reg  [3:0] pkt_type_reg = 3'h0, pkt_type_next;

reg  vlan_tag_reg = 1'b0, vlan_tag_next;	//8100
reg  qinq_tag_reg = 1'b0, qinq_tag_next;	//88a8
reg  arp_tag_reg = 1'b0,  arp_tag_next;		//0806
reg  lldp_tag_reg = 1'b0, lldp_tag_next;	//88cc
reg  ipv4_tag_reg = 1'b0, ipv4_tag_next;
reg  ipv6_tag_reg = 1'b0, ipv6_tag_next;
reg  tcp_tag_reg = 1'b0, tcp_tag_next;
reg  udp_tag_reg = 1'b0, udp_tag_next;
reg  seadp_tag_reg = 1'b0, seadp_tag_next;

assign des_mac	 = des_mac_reg;
assign src_mac	 = src_mac_reg;
assign eth_type	 = eth_type_reg;
assign des_ipv4	 = des_ipv4_reg;
assign src_ipv4	 = src_ipv4_reg;
assign des_ipv6	 = des_ipv6_reg;
assign src_ipv6	 = src_ipv6_reg;
assign des_port	 = des_port_reg;
assign src_port	 = src_port_reg;
assign pkt_type = pkt_type_reg;

assign vlan_tag	 = vlan_tag_reg;
assign qinq_tag	 = qinq_tag_reg;
assign arp_tag	 = arp_tag_reg;
assign lldp_tag	 = lldp_tag_reg;
assign ipv4_tag	 = ipv4_tag_reg;
assign ipv6_tag	 = ipv6_tag_reg;
assign tcp_tag	 = tcp_tag_reg;
assign udp_tag	 = udp_tag_reg;
assign seadp_tag = seadp_tag_reg;

reg transfer_reg = 1'b0, transfer_next;

integer i;
reg  [I_DATA_WIDTH-1:0] data;

always @(*)  begin
	ptr_next = ptr_reg;
	transfer_next = transfer_reg;

	for(i=0; i<DATA_SIZE; i=i+1)
		data[i*8 +: 8] = stream_in_data[(DATA_SIZE-i-1)*8 +:8];

	stream_hdr_data_next = stream_hdr_data_reg;
	stream_hdr_empty_next = stream_hdr_empty_reg;
	stream_hdr_valid_next = stream_hdr_valid_reg;
	stream_hdr_startofpacket_next = stream_hdr_startofpacket_reg;
	stream_hdr_endofpacket_next = stream_hdr_endofpacket_reg;
	stream_hdr_channel_next = stream_hdr_channel_reg;
	stream_hdr_error_next = stream_hdr_error_reg;

	stream_out_data_next = stream_out_data_reg;
	stream_out_empty_next = stream_out_empty_reg;
	stream_out_valid_next = stream_out_valid_reg;
	stream_out_startofpacket_next = stream_out_startofpacket_reg;
	stream_out_endofpacket_next = stream_out_endofpacket_reg;
	stream_out_channel_next = stream_out_channel_reg;
	stream_out_error_next = stream_out_error_reg;

	if(stream_hdr_valid_reg && stream_hdr_ready) begin
		stream_hdr_valid_next = 1'b0;
		stream_hdr_startofpacket_next = 1'b0;
	end

	if(stream_out_valid_reg && stream_out_ready) begin
		stream_out_valid_next = 1'b0;
	end

	if (stream_in_valid && stream_in_ready) begin
		stream_out_data_next = stream_in_data;
		stream_out_empty_next = stream_in_empty;
		stream_out_valid_next = 1'b1;
		stream_out_startofpacket_next = stream_in_startofpacket;
		stream_out_endofpacket_next = stream_in_endofpacket;
		stream_out_channel_next = stream_in_channel;
		stream_out_error_next = stream_in_error;
	end

	if (stream_in_startofpacket && stream_in_valid && stream_in_ready) begin
		transfer_next = 1'b1;
		stream_hdr_data_next = stream_in_data;
		stream_hdr_empty_next = stream_in_empty;
		stream_hdr_valid_next = 1'b1;
		stream_hdr_startofpacket_next = 1'b1;
		stream_hdr_endofpacket_next = 1'b1;
		stream_hdr_channel_next = stream_in_channel;
		stream_hdr_error_next = stream_in_error;

		ptr_next = ptr_reg + 1;

		if (ptr_reg == 0) begin
			vlan_tag_next = 1'b0;
			qinq_tag_next = 1'b0;
			arp_tag_next =  1'b0;
			lldp_tag_next = 1'b0;
			ipv4_tag_next = 1'b0;
			ipv6_tag_next = 1'b0;
			tcp_tag_next = 1'b0;
			udp_tag_next = 1'b0;
			seadp_tag_next = 1'b0;
			des_mac_next = 48'd0;
			src_mac_next = 48'd0;
			eth_type_next = 15'd0;
			eth_type_vlan_next = 15'd0;
			des_ipv4_next = 32'd0;
			src_ipv4_next = 32'd0;
			des_ipv6_next = 128'd0;
			src_ipv6_next = 128'd0;
			des_port_next = 16'd0;
			src_port_next = 16'd0;
		end else begin
			vlan_tag_next = vlan_tag_reg;
			qinq_tag_next = qinq_tag_reg;
			arp_tag_next = arp_tag_reg;
			lldp_tag_next = lldp_tag_reg;
			ipv4_tag_next = ipv4_tag_reg;
			ipv6_tag_next = ipv6_tag_reg;
			tcp_tag_next = tcp_tag_reg;
			udp_tag_next = udp_tag_reg;
			seadp_tag_next = seadp_tag_reg;
		//	ihl_next = ihl_reg;
			des_mac_next = des_mac_reg;
			src_mac_next = src_mac_reg;
			eth_type_next = eth_type_reg;
			eth_type_vlan_next = eth_type_vlan_reg;
			des_ipv4_next = des_ipv4_reg;
			src_ipv4_next = src_ipv4_reg;
			des_ipv6_next = des_ipv6_reg;
			src_ipv6_next = src_ipv6_reg;
			des_port_next = des_port_reg;
			src_port_next = src_port_reg;
		end

		for (i = MAC_SIZE; i > 0; i=i-1) begin
			if (ptr_reg == (MAC_SIZE-i)/DATA_SIZE) begin
				des_mac_next[(i*8-1)-:8] = data[((MAC_SIZE-i)%DATA_SIZE)*8 +: 8];
			end
		end

		for (i = MAC_SIZE; i > 0; i=i-1) begin
			if (ptr_reg == (MAC_SIZE-i+6)/DATA_SIZE) begin
				src_mac_next[(i*8-1)-:8] = data[((MAC_SIZE-i+6)%DATA_SIZE)*8 +: 8];
			end
		end

		if (ptr_reg == 12/DATA_SIZE) begin
			eth_type_next[15:8] = data[(12%DATA_SIZE)*8 +: 8];
		end
		if (ptr_reg == 13/DATA_SIZE) begin
			eth_type_next[7:0] = data[(13%DATA_SIZE)*8 +: 8];

			if (eth_type_next == 16'h0800) begin
				ipv4_tag_next = 1'b1;
			end else if (eth_type_next == 16'h86dd) begin
				ipv6_tag_next = 1'b1;
			end else if(eth_type_next == 16'h0806)begin
				arp_tag_next = 1'b1;
			end else if(eth_type_next == 16'h88cc)begin
				lldp_tag_next = 1'b1;
			end else if(eth_type_next == 16'h8100)begin
				vlan_tag_next = 1'b1;
			end else if(eth_type_next == 16'h88a8)begin
				qinq_tag_next = 1'b1;
				vlan_tag_next = 1'b1;
			end
		end
		if(vlan_tag_next||qinq_tag_next)begin
			if (ptr_reg == (16+qinq_tag_next*4)/DATA_SIZE) begin
				eth_type_vlan_next[15:8] = data[((16+qinq_tag_next*4)%DATA_SIZE)*8 +: 8];
			end
			if (ptr_reg == (17+qinq_tag_next*4)/DATA_SIZE) begin
				eth_type_vlan_next[7:0] = data[((17+qinq_tag_next*4)%DATA_SIZE)*8 +: 8];
				if(eth_type_vlan_next == 16'h0800)begin
					ipv4_tag_next = 1'b1;
				end else if(eth_type_vlan_next == 16'h86dd)begin
					ipv6_tag_next = 1'b1;
				end  else if(eth_type_vlan_next == 16'h0806)begin
					arp_tag_next = 1'b1;
				end else if(eth_type_vlan_next == 16'h88cc)begin
					lldp_tag_next = 1'b1;
				end
			end
		end

		if (ipv4_tag_next) begin
			if (ptr_reg == (23+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
				// capture protocol
				if (data[((23+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8] == 8'h06) begin
					// TCP
					tcp_tag_next = 1'b1;
				end else if (data[((23+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8] == 8'h11) begin
					// UDP
					udp_tag_next = 1'b1;
				end
			end
			//parser src IP
			for(i = IPV4_WIDTH; i>0; i=i-1)begin
				if (ptr_reg == (IPV4_WIDTH-i+26+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
					src_ipv4_next[(i*8-1)-:8] = data[((IPV4_WIDTH-i+26+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8];
				end
			end
			//parser des IP
			for(i = IPV4_WIDTH; i>0; i=i-1)begin
				if (ptr_reg == (IPV4_WIDTH-i+30+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
					des_ipv4_next[(i*8-1)-:8] = data[((IPV4_WIDTH-i+30+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8];
				end
			end
			if (tcp_tag_next || udp_tag_next) begin
				// TODO IHL (skip options)		æ¥çæ¯å¦æå¡«åå­æ®µ
				// capture source port
				for(i = PORT_WIDTH; i>0; i=i-1)begin
					if (ptr_reg == (PORT_WIDTH-i+34+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
						src_port_next[(i*8-1)-:8] = data[((PORT_WIDTH-i+34+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8];
					end
				end
				// capture dest port
				for(i = PORT_WIDTH; i>0; i=i-1)begin
					if (ptr_reg == (PORT_WIDTH-i+36+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
						des_port_next[(i*8-1)-:8] = data[((PORT_WIDTH-i+36+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8];
					end
				end
			end
		end

		if (ipv6_tag_next) begin
			if (ptr_reg == (20+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
				// capture protocol
				if (data[((20+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8] == 8'h06) begin
					// TCP
					tcp_tag_next = 1'b1;
				end else if (data[((20+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8] == 8'h11) begin
					// UDP
					udp_tag_next = 1'b1;
				end else if (data[((20+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8] == 8'h99) begin
					//SEADP
					seadp_tag_next = 1'b1;
				end

			end
			//parser src IP
			for(i = IPV6_WIDTH; i>0; i=i-1)begin
				if (ptr_reg == (IPV6_WIDTH-i+22+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
					src_ipv6_next[(i*8-1)-:8] = data[((IPV6_WIDTH-i+22+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8];
				end
			end
			//parser des IP
			for(i = IPV6_WIDTH; i>0; i=i-1)begin
				if (ptr_reg == (IPV6_WIDTH-i+38+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
					des_ipv6_next[(i*8-1)-:8] = data[((IPV6_WIDTH-i+38+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8];
				end
			end
			if (tcp_tag_next || udp_tag_next) begin
				// TODO IHL (skip options)		æ¥çæ¯å¦æå¡«åå­æ®µ
				// capture source port
				for(i = PORT_WIDTH; i>0; i=i-1)begin
					if (ptr_reg == (PORT_WIDTH-i+54+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
						src_port_next[(i*8-1)-:8] = data[((PORT_WIDTH-i+54+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8];
					end
				end
				// capture dest port
				for(i = PORT_WIDTH; i>0; i=i-1)begin
					if (ptr_reg == (PORT_WIDTH-i+56+(vlan_tag_next+qinq_tag_next)*4)/DATA_SIZE) begin
						des_port_next[(i*8-1)-:8] = data[((PORT_WIDTH-i+56+(vlan_tag_next+qinq_tag_next)*4)%DATA_SIZE)*8 +: 8];
					end
				end
			end
		end

		if (stream_in_endofpacket) begin
			ptr_next = 0;
		end
	end

	if (des_mac_reg[40]) begin		//multicast packets.
		pkt_type_next = 'd0;
	end else begin
		if (vlan_tag_reg) begin
			if (ipv4_tag_reg) begin
				if (tcp_tag_reg || udp_tag_reg) begin
					pkt_type_next = 'd2;		//vlan_ipv4_t(u)cp: 2, short as IPV4_VLAN for simplicity.
				end else begin
					pkt_type_next = 'd0;
				end
			end else if (ipv6_tag_reg) begin
				if (tcp_tag_reg || udp_tag_reg) begin
					pkt_type_next = 'd4;		//vlan_ipv6_t(u)cp: 4, short as IPV6_VLAN for simplicity.
				end else begin
					pkt_type_next = 'd0;
				end
			end else begin
				pkt_type_next = 'd0;
			end
		end else begin
			if (ipv4_tag_reg) begin
				if (tcp_tag_reg || udp_tag_reg) begin
					pkt_type_next = 'd1;		//ipv4_t(u)dp: 1, short as IPV4 for simplicity.
				end else begin
					pkt_type_next = 'd0;
				end
			end else if (ipv6_tag_reg) begin
				if (tcp_tag_reg || udp_tag_reg) begin
					pkt_type_next = 'd3;		//ipv6_t(u)dp: 1, short as IPV6 for simplicity.
				end else begin
					pkt_type_next = 'd0;
				end
			end else begin
				pkt_type_next = 'd0;
			end
		end
	end
end

/*
 * Output path.
 */

reg  [HDR_DATA_WIDTH-1:0] 	stream_hdr_data_reg = {HDR_DATA_WIDTH{1'b0}}, stream_hdr_data_next;
reg  [HDR_EMPTY_WIDTH-1:0] 	stream_hdr_empty_reg = {HDR_EMPTY_WIDTH{1'b0}}, stream_hdr_empty_next;
reg  						stream_hdr_valid_reg = 1'b0, stream_hdr_valid_next;
reg  						stream_hdr_startofpacket_reg = 1'b0, stream_hdr_startofpacket_next;
reg  						stream_hdr_endofpacket_reg = 1'b0, stream_hdr_endofpacket_next;
reg  [HDR_CHANNEL_WIDTH-1:0] 	stream_hdr_channel_reg = {HDR_CHANNEL_WIDTH{1'b0}}, stream_hdr_channel_next;
reg  [HDR_ERROR_WIDTH-1:0] 	stream_hdr_error_reg = {HDR_ERROR_WIDTH{1'b0}}, stream_hdr_error_next;

reg  [O_DATA_WIDTH-1:0] 	stream_out_data_reg = {O_DATA_WIDTH{1'b0}}, stream_out_data_next;
reg  [O_EMPTY_WIDTH-1:0] 	stream_out_empty_reg = {O_EMPTY_WIDTH{1'b0}}, stream_out_empty_next;
reg  						stream_out_valid_reg = 1'b0, stream_out_valid_next;
reg  						stream_out_startofpacket_reg = 1'b0, stream_out_startofpacket_next;
reg  						stream_out_endofpacket_reg = 1'b0, stream_out_endofpacket_next;
reg  [O_CHANNEL_WIDTH-1:0] 	stream_out_channel_reg = {O_CHANNEL_WIDTH{1'b0}}, stream_out_channel_next;
reg  [O_ERROR_WIDTH-1:0] 	stream_out_error_reg = {O_ERROR_WIDTH{1'b0}}, stream_out_error_next;

assign stream_in_ready = (!stream_out_valid_reg || stream_out_ready) && (!stream_hdr_valid_reg || !stream_out_endofpacket_reg || stream_hdr_ready);

assign stream_hdr_data = stream_hdr_data_reg;
assign stream_hdr_empty = stream_hdr_empty_reg;
assign stream_hdr_valid = stream_hdr_valid_reg;
assign stream_hdr_startofpacket = stream_hdr_startofpacket_reg;
assign stream_hdr_endofpacket = stream_hdr_endofpacket_reg;
assign stream_hdr_channel = stream_hdr_channel_reg;
assign stream_hdr_error = stream_hdr_error_reg;

assign stream_out_data = stream_out_data_reg;
assign stream_out_empty = stream_out_empty_reg;
assign stream_out_valid = stream_out_valid_reg;
assign stream_out_startofpacket = stream_out_startofpacket_reg;
assign stream_out_endofpacket = stream_out_endofpacket_reg;
assign stream_out_channel = stream_out_channel_reg;
assign stream_out_error = stream_out_error_reg;

always @(posedge clk) begin
	if (rst) begin
		ptr_reg <= 0;
		stream_hdr_data_reg			 = {HDR_DATA_WIDTH{1'b0}};
		stream_hdr_empty_reg		 = {HDR_EMPTY_WIDTH{1'b0}};
		stream_hdr_valid_reg		 = 1'b0;
		stream_hdr_startofpacket_reg = 1'b0;
		stream_hdr_endofpacket_reg	 = 1'b0;
		stream_hdr_channel_reg		 = {HDR_CHANNEL_WIDTH{1'b0}};
		stream_hdr_error_reg		 = {HDR_ERROR_WIDTH{1'b0}};
	end else begin
		stream_hdr_data_reg			 <= stream_hdr_data_next;
		stream_hdr_valid_reg		 <= stream_hdr_valid_next;
		stream_hdr_startofpacket_reg <= stream_hdr_startofpacket_next;
		stream_hdr_endofpacket_reg	 <= stream_hdr_endofpacket_next;
		stream_hdr_empty_reg		 <= stream_hdr_empty_next;
		stream_hdr_error_reg		 <= stream_hdr_error_next;
		stream_hdr_channel_reg		 <= stream_hdr_channel_next;
	end

	if (rst) begin
		ptr_reg <= 0;
		stream_out_data_reg			 = {O_DATA_WIDTH{1'b0}};
		stream_out_empty_reg		 = {O_EMPTY_WIDTH{1'b0}};
		stream_out_valid_reg		 = 1'b0;
		stream_out_startofpacket_reg = 1'b0;
		stream_out_endofpacket_reg	 = 1'b0;
		stream_out_channel_reg		 = {O_CHANNEL_WIDTH{1'b0}};
		stream_out_error_reg		 = {O_ERROR_WIDTH{1'b0}};
	end else begin
		stream_out_data_reg			 <= stream_out_data_next;
		stream_out_valid_reg		 <= stream_out_valid_next;
		stream_out_startofpacket_reg <= stream_out_startofpacket_next;
		stream_out_endofpacket_reg	 <= stream_out_endofpacket_next;
		stream_out_empty_reg		 <= stream_out_empty_next;
		stream_out_error_reg		 <= stream_out_error_next;
		stream_out_channel_reg		 <= stream_out_channel_next;
	end

	ptr_reg <= ptr_next;
	vlan_tag_reg <= vlan_tag_next;
	qinq_tag_reg <= qinq_tag_next;
	arp_tag_reg <= arp_tag_next;
	lldp_tag_reg <= lldp_tag_next;
	ipv4_tag_reg <= ipv4_tag_next;
	ipv6_tag_reg <= ipv6_tag_next;
	tcp_tag_reg <= tcp_tag_next;
	udp_tag_reg <= udp_tag_next;
	seadp_tag_reg <= seadp_tag_next;

	des_mac_reg <= des_mac_next;
	src_mac_reg <= src_mac_next;
	eth_type_reg <= eth_type_next;
	eth_type_vlan_reg <= eth_type_vlan_next;
//	ihl_reg <= ihl_next;
	des_ipv4_reg <= des_ipv4_next;
	src_ipv4_reg <= src_ipv4_next;
	des_ipv6_reg <= des_ipv6_next;
	src_ipv6_reg <= src_ipv6_next;
	des_port_reg <= des_port_next;
	src_port_reg <= src_port_next;
	pkt_type_reg <= pkt_type_next;
end

endmodule

`resetall

/*
TCP/UDP Frame (IPv4)

 Field						Length
 Destination MAC address	6 octets
 Source MAC address			6 octets
 Ethertype (0x0800)			2 octets
 Version (4)				4 bits
 IHL (5-15)					4 bits	Check whether there are filled fields according to the head length
 DSCP (0)					6 bits
 ECN (0)					2 bits
 length						2 octets
 identification (0?)		2 octets
 flags (010)				3 bits
 fragment offset (0)		13 bits
 time to live (64?)			1 octet
 protocol (6 or 17)			1 octet
 header checksum			2 octets
 source IP					4 octets
 destination IP				4 octets
 options					(IHL-5)*4 octets

 source port				2 octets
 desination port			2 octets
 other fields + payload

TCP/UDP Frame (IPv6)

 Field						Length
 Destination MAC address	6 octets
 Source MAC address			6 octets
 Ethertype (0x86dd)			2 octets
 Version (4)				4 bits
 Traffic class				8 bits
 Flow label					20 bits
 length						2 octets
 next header (6 or 17)		1 octet
 hop limit					1 octet
 source IP					16 octets
 destination IP				16 octets

 source port				2 octets
 desination port			2 octets
 other fields + payload

*/