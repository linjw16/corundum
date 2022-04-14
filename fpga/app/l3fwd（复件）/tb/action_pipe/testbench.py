#
# Created on Tue Feb 22 2022
#
# Copyright (c) 2022 IOA UCAS
#
# @Filename:	 testbench.py
# @Author:		 Jiawei Lin
# @Last edit:	 09:12:04
#

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.regression import TestFactory
from cocotb_bus.drivers import BitDriver
from cocotb_bus.drivers.avalon import AvalonSTPkts as AvalonSTDriver
from cocotb_bus.monitors.avalon import AvalonSTPkts as AvalonSTMonitor
import itertools
import logging
import random
import warnings
warnings.filterwarnings("ignore")

import scapy.utils
from scapy.layers.l2 import Ether
from scapy.layers.inet import IP, UDP

try:
	import libmat
except ImportError:
	# attempt import from current directory
	sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
	try:
		import libmat
	finally:
		del sys.path[0]

class ActionPipeTB(object):
	def __init__(self, dut, debug=True):
		level = logging.DEBUG if debug else logging.WARNING
		self.log = logging.getLogger("AP_TB")
		self.log.setLevel(level)

		self.dut = dut
		self.stream_in = AvalonSTDriver(dut, "stream_in", dut.clk)
		self.stream_out = AvalonSTMonitor(dut, "stream_out", dut.clk)
		self.backpressure = BitDriver(self.dut.stream_out_ready, self.dut.clk)
		self.stream_in.log.setLevel(level)
		self.stream_out.log.setLevel(level)

		self.ACTN_DATA_WIDTH = self.dut.ACTN_DATA_WIDTH.value
		self.I_DATA_WIDTH = self.dut.I_DATA_WIDTH.value
		self.O_DATA_WIDTH = self.dut.O_DATA_WIDTH.value
		self.log.debug("ACTN_DATA_WIDTH = %d" % self.ACTN_DATA_WIDTH)
		self.log.debug("I_DATA_WIDTH = %d" % self.I_DATA_WIDTH)
		self.log.debug("O_DATA_WIDTH = %d" % self.O_DATA_WIDTH)
		self.PT_IPV4 = self.dut.PT_IPV4.value
		self.PT_VLV4 = self.dut.PT_VLV4.value
		self.PT_IPV6 = self.dut.PT_IPV6.value
		self.PT_VLV6 = self.dut.PT_VLV6.value
		
		self.expected_recv = []
		self.action_code = 0

		cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())

	async def reset(self):
		await RisingEdge(self.dut.clk)
		await RisingEdge(self.dut.clk)
		self.dut.stream_in_data.value = 0
		self.dut.stream_in_empty.value = 0
		self.dut.stream_in_valid.value = 0
		self.dut.stream_out_ready.value = 0
		self.dut.stream_in_startofpacket.value = 0
		self.dut.stream_in_endofpacket.value = 0
		self.dut.stream_in_error.value = 0
		self.dut.stream_in_channel.value = 0
		self.dut.stream_in_tuser.value = 0
		self.log.info("reset begin")
		self.dut.rst.setimmediatevalue(0)
		await RisingEdge(self.dut.clk)
		await RisingEdge(self.dut.clk)
		self.dut.rst <= 1
		await RisingEdge(self.dut.clk)
		await RisingEdge(self.dut.clk)
		self.dut.rst.value = 0
		await RisingEdge(self.dut.clk)
		await RisingEdge(self.dut.clk)
		self.log.info("reset end")
		self.dut.stream_out_ready.value = 1


async def run_test(dut, payload_lengths=None, payload_data=None, config_coroutine=None, idle_inserter=None, backpressure_inserter=None):
	tb = ActionPipeTB(dut)
	await tb.reset()

	if idle_inserter is not None:
		tb.stream_in.set_valid_generator(idle_inserter())
	if backpressure_inserter is not None:
		tb.backpressure.start(backpressure_inserter())

	MAC_WIDTH = 48
	DMAC_OFFSET = tb.O_DATA_WIDTH-MAC_WIDTH
	SMAC_OFFSET = DMAC_OFFSET-MAC_WIDTH
	VLAN_WIDTH = 16
	VLAN_OFFSET = SMAC_OFFSET-VLAN_WIDTH-16
	DIP_OFFSET = tb.O_DATA_WIDTH-34*8
	IP_WIDTH = 32
	i = 0
	for payload in [payload_data(x) for x in payload_lengths()]:
		i = i+1
		eth = Ether(src='5A:51:52:53:54:55', dst='DA:D1:D2:D3:D4:D5')
		ip = IP(src='192.168.1.16', dst='192.168.1.17')
		udp = UDP(sport=1, dport=2)
		pkt_sent = eth / ip / udp / payload

		dmac_1 = (0xD0_D1_D2_D3_D4_D5 + (i << 40)) % (1 << 48)
		smac_1 = (0x50_51_52_53_54_55 + (i+1 << 40)) % (1 << 48)
		vlan_1 = 0xFFFF
		channel_1 = 0x1+i
		action_code_1 = libmat.f_get_action_code(d_mac=dmac_1, s_mac=smac_1, vl_data=vlan_1, fwd_id=channel_1,
		                          vl_op=0b01, fwd_en=True, cks_en=True, d_mac_en=True, s_mac_en=True)

		tb.dut.stream_in_tuser.value = tb.PT_IPV4+(action_code_1<<4)
		await tb.stream_in.send(pkt_sent.build())
		await RisingEdge(tb.dut.stream_out_valid)
		await RisingEdge(tb.dut.clk)

		pkt_recv = int(tb.dut.stream_out_data.value)
		dmac_2 = libmat.f_get(pkt_recv, DMAC_OFFSET, MAC_WIDTH)
		smac_2 = libmat.f_get(pkt_recv, SMAC_OFFSET, MAC_WIDTH)
		vlan_2 = libmat.f_get(pkt_recv, VLAN_OFFSET, VLAN_WIDTH)
		channel_2 = tb.dut.stream_out_channel.value

		tb.log.debug("assert: %X==%X" % (dmac_2, dmac_1))
		tb.log.debug("assert: %X==%X" % (smac_2, smac_1))
		tb.log.debug("assert: %X==%X" % (vlan_2, vlan_1))
		tb.log.debug("assert: %X==%X" % (channel_2, channel_1))
		try:
			assert dmac_2 == dmac_1
			assert smac_2 == smac_1
			assert vlan_2 == vlan_1
			assert channel_2 == channel_1
		except AssertionError:
			tb.log.debug("failed")


def size_list(min_1=7, max_1=8):
	len_min = 22 if min_1 > 22 else min_1
	len_max = 22 if max_1 > 22 else max_1
	return list(range(len_min, len_max+1))


def incrementing_payload(length):
	return bytes(itertools.islice(itertools.cycle(range(1, 256)), length))


if cocotb.SIM_NAME:
	factory = TestFactory(run_test)
	factory.add_option("payload_lengths", [size_list])
	factory.add_option("payload_data", [incrementing_payload])
	factory.add_option("config_coroutine", [None])
	factory.add_option("idle_inserter", [None])
	factory.add_option("backpressure_inserter", [None])
	factory.generate_tests()
