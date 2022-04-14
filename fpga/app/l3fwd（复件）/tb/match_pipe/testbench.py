#
# Created on Wed Jan 05 2022
#
# Copyright (c) 2022 IOA UCAS
#
# @Filename:	 testbench.py
# @Author:		 Jiawei Lin
# @Last edit:	 09:45:47
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

from cocotb.utils import hexdump
from cocotb.result import TestFailure

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

class MatchPipeTB(object):
	def __init__(self, dut, debug=True):
		# Set verbosity on our various interfaces
		level = logging.DEBUG if debug else logging.WARNING
		self.log = logging.getLogger("cocotb.tb")
		self.log.setLevel(level)

		self.dut = dut	# TODO: Control Status Register. 
		self.stream_in = AvalonSTDriver(dut, "stream_in", dut.clk)
		self.stream_out = AvalonSTMonitor(dut, "stream_out", dut.clk)
		self.backpressure = BitDriver(self.dut.stream_out_ready, self.dut.clk)
		self.stream_in.log.setLevel(level)
		self.stream_out.log.setLevel(level)

		self.TCAM_DEPTH = self.dut.TCAM_DEPTH.value
		self.TCAM_WIDTH = self.dut.TCAM_DATA_WIDTH.value
		self.TCAM_WR_WIDTH = self.dut.TCAM_WR_WIDTH.value
		self.ACTN_ADDR_WIDTH = self.dut.ACTN_ADDR_WIDTH.value
		self.log.debug("TCAM_DEPTH = %d" % self.TCAM_DEPTH)
		self.log.debug("TCAM_WIDTH = %d" % self.TCAM_WIDTH)
		self.log.debug("TCAM_WR_WIDTH = %d" % self.TCAM_WR_WIDTH)
		
		self.wr_addr_ptr = 0
		self.tcam_dict = {}
		self.tcam_list = [set()]*self.TCAM_DEPTH
		self.act_table = [0]*self.TCAM_DEPTH

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
		self.dut.stream_in_channel.value = 0
		self.dut.stream_in_error.value = 0
		self.dut.stream_in_tuser.value = 0
		self.dut.tcam_wr_data.value = 0
		self.dut.tcam_wr_keep.value = 0
		self.dut.tcam_wr_valid.value = 0
		self.dut.pkt_type.value = 0
		self.dut.action_wr_addr.value = 0
		self.dut.action_wr_data.value = 0
		self.dut.action_wr_strb.value = (1 << self.dut.ACTN_STRB_WIDTH.value)-1
		self.dut.action_wr_valid.value = 0
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

	def model_wr(self, wr_data=0, wr_keep=0, idx=0):
		while(wr_keep & (1 << idx)):
			idx = idx+1
		if(idx == self.TCAM_WR_WIDTH):
			set_1 = self.tcam_dict.get(wr_data, set())
			set_1.add(self.wr_addr_ptr)
			self.tcam_dict[wr_data] = set_1
			set_2 = self.tcam_list[self.wr_addr_ptr]
			set_2.add(wr_data)
			self.tcam_list[self.wr_addr_ptr] = set_2
		else:
			self.model_wr(wr_data, wr_keep, idx+1)
			self.model_wr(wr_data ^ (1 << idx), wr_keep, idx+1)

	async def write(self, wr_data=range(8), wr_keep=range(8)):
		wr_data_1 = 0
		wr_keep_1 = 0
		for i in range(8):
			wr_data_1 += wr_data[i] << (i*self.TCAM_WR_WIDTH)
			wr_keep_1 += wr_keep[i] << (i*self.TCAM_WR_WIDTH)
			set_2 = self.tcam_list[self.wr_addr_ptr]
			for sk in set_2:
				set_1 = self.tcam_dict[sk].discard(self.wr_addr_ptr)
			self.tcam_list[self.wr_addr_ptr] = set()
			self.model_wr(wr_data[i], wr_keep[i])
			self.wr_addr_ptr = (self.wr_addr_ptr+1) % (int(self.TCAM_DEPTH/8) << 3)

		self.dut.tcam_wr_valid.value = 1
		self.dut.tcam_wr_addr.value = (
			self.wr_addr_ptr-1) % int(self.TCAM_DEPTH)
		self.dut.tcam_wr_data.value = wr_data_1
		self.dut.tcam_wr_keep.value = wr_keep_1
		await RisingEdge(self.dut.clk)
		self.dut.tcam_wr_valid.value = 0
		for _ in range(32*9):
			await RisingEdge(self.dut.clk)
		await RisingEdge(self.dut.clk)

	async def act_write(self, wr_addr=0, wr_data=0):
		self.act_table[wr_addr] = wr_data
		self.dut.action_wr_addr.value = wr_addr
		self.dut.action_wr_data.value = wr_data
		self.dut.action_wr_valid.value = 1
		await RisingEdge(self.dut.action_wr_done)
		self.dut.action_wr_valid.value = 0
		await RisingEdge(self.dut.clk)


async def run_test(dut, payload_lengths=None, payload_data=None, config_coroutine=None, idle_inserter=None, backpressure_inserter=None):
	PKT_TYPE_IPv4 = 1
	PKT_TYPE_IPv4_VLAN = 2
	PKT_TYPE_IPv6 = 3
	PKT_TYPE_IPv6_VLAN = 4

	tb = MatchPipeTB(dut)
	await tb.reset()

	for wr_data in incr_ipv4(int(tb.TCAM_DEPTH/8), 8, 0xC0A80100):
		tb.log.debug("write tcam")
		wr_keep = [(1 << tb.TCAM_WR_WIDTH)-1]*8
		await tb.write(wr_data, wr_keep)
		await RisingEdge(tb.dut.clk)
	tb.log.debug(str(tb.tcam_dict))
	tb.log.debug(str(tb.tcam_list))

	for wr_addr in range(1<<tb.ACTN_ADDR_WIDTH):
		await tb.act_write(wr_addr, wr_addr)

	dut.stream_out_ready.value = 1

	# Start off any optional coroutines
	# if config_coroutine is not None:	# TODO: config match rules
		# cocotb.fork(config_coroutine(tb.csr))
	if idle_inserter is not None:
		tb.stream_in.set_valid_generator(idle_inserter())
	if backpressure_inserter is not None:
		tb.backpressure.start(backpressure_inserter())
	# ip_pkt_sent = []
	for payload in [payload_data(x) for x in payload_lengths()]:
		eth = Ether(src='5A:51:52:53:54:55', dst='DA:D1:D2:D3:D4:D5')# 0xC0A80110 0xC0A880111
		dst_ip_l = random.randint(0, 0x1F)
		dst_ip = '192.168.1.'+str(dst_ip_l)
		ip = IP(src='192.168.1.16', dst=dst_ip)
		# ip_pkt_sent.append(dst_ip)
		udp = UDP(sport=1, dport=2)
		pkt_sent = eth / ip / udp / payload
		
		tb.dut.stream_in_tuser.value = PKT_TYPE_IPv4
		await tb.stream_in.send(pkt_sent.build())
		await RisingEdge(tb.dut.stream_out_valid)
		await RisingEdge(tb.dut.clk)

		user_recv = int(tb.dut.stream_out_tuser.value)
		action_code = libmat.f_get(user_recv, 4, 128)
		match_addr_s = tb.tcam_dict.get(0xC0A80100+dst_ip_l, {0})
		try:
			for i in match_addr_s:
				action_code_exp = tb.act_table[i]
				assert action_code == action_code_exp
				tb.log.debug("%d = %d" % (action_code, action_code_exp))
		except AssertionError:
			tb.log.debug("%d != %d" % (action_code, action_code_exp))

	if 1 == 2:
		raise TestFailure("DUT recorded %d packets but tb counted %d" % (1, 2))

	# Wait at least 2 cycles where output ready is low before ending the test
	for i in range(2):
		await RisingEdge(dut.clk)
		while not dut.stream_out_ready.value:
			await RisingEdge(dut.clk)


# def random_size_packet(min_size=8, max_size=8, npackets=1):
# 	"""random string data of a random length"""
# 	for i in range(npackets):
# 		await bytearray([x % 256 for x in range(min_size, max_size+1)])


def size_list():
	len_min = 10
	len_max = 22
	return list(range(len_min, len_max+1))


def incrementing_payload(length):
	return bytes(itertools.islice(itertools.cycle(range(1, 256)), length))


def test_ipv4(times=4, length=8, ip_base=0xC0A80100):
	set = range(0xFF)
	for i in range(times):
		rand_set = random.sample(set, length)
		yield [i+ip_base for i in rand_set]


def incr_ipv4(times=4, length=8, ip_base=0xC0A80100):
	for i in range(times):
		set = range(i*length, (i+1)*length)
		yield [i+ip_base for i in set]


if cocotb.SIM_NAME:
	factory = TestFactory(run_test)
	factory.add_option("payload_lengths", [size_list])
	factory.add_option("payload_data", [incrementing_payload])
	factory.add_option("config_coroutine", [None])
	factory.add_option("idle_inserter", [None])
	factory.add_option("backpressure_inserter", [None])
	factory.generate_tests()

