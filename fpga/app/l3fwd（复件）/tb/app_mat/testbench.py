#
# Created on Tue Mar 01 2022
#
# Copyright (c) 2022 IOA UCAS
#
# @Filename:	 testbench.py
# @Author:		 Jiawei Lin
# @Last edit:	 09:28:03
#

from cocotb_bus.monitors.avalon import AvalonSTPkts as AvalonSTMonitor
from cocotb_bus.drivers.avalon import AvalonSTPkts as AvalonSTDriver
from cocotb_bus.drivers.avalon import AvalonMaster
from cocotb_bus.drivers import BitDriver
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.clock import Clock
import cocotb
from scapy.layers.inet import IP, UDP
from scapy.layers.l2 import Ether
import scapy.utils
import itertools
import logging
import random
import warnings
try:
    import libmat
except ImportError:
    # attempt import from current directory
    sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
    try:
        import libmat
    finally:
        del sys.path[0]
warnings.filterwarnings("ignore")


class AppMAT_TB(object):
	def __init__(self, dut, debug=True):
		level = logging.DEBUG if debug else logging.WARNING
		self.log = logging.getLogger("TB")
		self.log.setLevel(level)

		self.dut = dut
		self.rx_in = AvalonSTDriver(dut, "avst_rx_in", dut.clk)
		self.rx_out = AvalonSTMonitor(dut, "avst_rx_out", dut.clk)
		# self.tx_in = AvalonSTDriver(dut, "avst_tx_in", dut.clk)
		# self.tx_out = AvalonSTMonitor(dut, "avst_tx_out", dut.clk)
		self.csr = AvalonMaster(dut, "csr_agent", dut.clk)
		self.rx_in.log.setLevel(level)
		self.rx_out.log.setLevel(level)
		# self.tx_in.log.setLevel(level)
		# self.tx_out.log.setLevel(level)
		self.backpressure = BitDriver(self.dut.avst_rx_out_ready, self.dut.clk)
		# self.backpressure = BitDriver(self.dut.avst_tx_out_ready, self.dut.clk)

		self.AVST_DATA_WIDTH	= self.dut.AVST_DATA_WIDTH.value
		self.AVST_EMPTY_WIDTH	= self.dut.AVST_EMPTY_WIDTH.value
		self.AVST_CHANNEL_WIDTH	= self.dut.AVST_CHANNEL_WIDTH.value
		self.AVST_ERROR_WIDTH	= self.dut.AVST_ERROR_WIDTH.value
		self.AVMM_DATA_WIDTH	= self.dut.AVMM_DATA_WIDTH.value
		self.AVMM_STRB_WIDTH	= self.dut.AVMM_STRB_WIDTH.value
		self.AVMM_ADDR_WIDTH	= self.dut.AVMM_ADDR_WIDTH.value
		self.log.debug("AVST_DATA_WIDTH		= %d" % self.AVST_DATA_WIDTH)
		self.log.debug("AVST_EMPTY_WIDTH	= %d" % self.AVST_EMPTY_WIDTH)
		self.log.debug("AVST_CHANNEL_WIDTH	= %d" % self.AVST_CHANNEL_WIDTH)
		self.log.debug("AVST_ERROR_WIDTH	= %d" % self.AVST_ERROR_WIDTH)
		self.log.debug("AVMM_DATA_WIDTH		= %d" % self.AVMM_DATA_WIDTH)
		self.log.debug("AVMM_STRB_WIDTH		= %d" % self.AVMM_STRB_WIDTH)
		self.log.debug("AVMM_ADDR_WIDTH		= %d" % self.AVMM_ADDR_WIDTH)
		self.BAR_TCAM_DATA	 = self.dut.BAR_TCAM_DATA.value
		self.BAR_TCAM_KEEP	 = self.dut.BAR_TCAM_KEEP.value
		self.BAR_ACTN_DATA	 = self.dut.BAR_ACTN_DATA.value
		self.BAR_CSR		 = self.dut.BAR_CSR.value
		self.CSR_TCAM_OFFSET = self.dut.CSR_TCAM_OFFSET.value
		self.CSR_TCAM_WR = self.dut.CSR_TCAM_WR.value
		self.CSR_ACTN_OFFSET = self.dut.CSR_ACTN_OFFSET.value
		self.CSR_ACTN_WR = self.dut.CSR_ACTN_WR.value
		self.TCAM_DEPTH = self.dut.TCAM_DEPTH.value
		self.TCAM_WR_WIDTH = self.dut.TCAM_WR_WIDTH.value

		self.tcam_dict = {}
		self.tcam_list = [set()]*self.TCAM_DEPTH
		self.act_table = [0]*self.TCAM_DEPTH

		cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())

	async def reset(self):
		await RisingEdge(self.dut.clk)
		await RisingEdge(self.dut.clk)

		self.dut.avst_rx_in_data.value = 0
		self.dut.avst_rx_in_empty.value = 0
		self.dut.avst_rx_in_valid.value = 0
		self.dut.avst_rx_out_ready.value = 0
		self.dut.avst_rx_in_startofpacket.value = 0
		self.dut.avst_rx_in_endofpacket.value = 0
		self.dut.avst_rx_in_channel.value = 0
		self.dut.avst_rx_in_error.value = 0

		# self.dut.avst_tx_in_data.value = 0
		# self.dut.avst_tx_in_empty.value = 0
		# self.dut.avst_tx_in_valid.value = 0
		# self.dut.avst_tx_out_ready.value = 1
		# self.dut.avst_tx_in_startofpacket.value = 0
		# self.dut.avst_tx_in_endofpacket.value = 0
		# self.dut.avst_tx_in_channel.value = 0
		# self.dut.avst_tx_in_error.value = 0

		# self.dut.ctrl_reg_wr_addr.value = 0
		# self.dut.ctrl_reg_wr_data.value = 0
		# self.dut.ctrl_reg_wr_strb.value = 0
		# self.dut.ctrl_reg_wr_en.value = 0
		# self.dut.ctrl_reg_rd_addr.value = 0
		# self.dut.ctrl_reg_rd_en.value = 0

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
		self.dut.avst_rx_out_ready.value = 1

	def model_wr(self, wr_data=0, wr_keep=0, wr_addr=0, idx=0):
		while(wr_keep & (1 << idx)):
			idx = idx+1
		if(idx == self.TCAM_WR_WIDTH):
			set_1 = self.tcam_dict.get(wr_data, set())
			set_1.add(wr_addr)
			self.tcam_dict[wr_data] = set_1
			set_2 = self.tcam_list[wr_addr]
			set_2.add(wr_data)
			self.tcam_list[wr_addr] = set_2
		else:
			self.model_wr(wr_data, wr_keep, wr_addr, idx+1)
			self.model_wr(wr_data ^ (1 << idx), wr_keep, wr_addr, idx+1)

	async def cfg_tcam(self, tcam_data=([0]*8), tcam_keep=([(1 << 32)-1]*8), tcam_addr=0x0001):
		for i in range(8):
			set_2 = self.tcam_list[tcam_addr+i]
			for sk in set_2:
				set_1 = self.tcam_dict[sk].discard(tcam_addr+i)
			self.tcam_list[tcam_addr+i] = set()
			self.model_wr(tcam_data[i], tcam_keep[i], tcam_addr+i)
			self.log.debug("addr = %d; data = %X|%X" %
			               (tcam_addr+i, tcam_data[i], tcam_keep[i]))
			await self.csr.write(self.BAR_TCAM_DATA+i*0x4, tcam_data[i] % (1 << self.AVMM_DATA_WIDTH))
			await self.csr.write(self.BAR_TCAM_KEEP+i*0x4, tcam_keep[i] % (1 << self.AVMM_DATA_WIDTH))

		# TODO: mask
		csr_op_code = (1 << self.CSR_TCAM_WR) | (
		    tcam_addr << self.CSR_TCAM_OFFSET % 0x10000)
		await self.csr.write(self.BAR_CSR, csr_op_code)


	async def cfg_action(self, action_data=0x0001, action_addr=0x0001):
		for i in range(4):
			wr_data = (action_data >> 32*i) % (1 << self.AVMM_DATA_WIDTH)
			await self.csr.write(self.BAR_ACTN_DATA+i*0x4, wr_data)
		# await self.csr.write(self.BAR_ACTN_DATA+0x0000, (action_data)		 % (1 << self.AVMM_DATA_WIDTH))
		# await self.csr.write(self.BAR_ACTN_DATA+0x0004, (action_data >> 32) % (1 << self.AVMM_DATA_WIDTH))
		# await self.csr.write(self.BAR_ACTN_DATA+0x0008, (action_data >> 64) % (1 << self.AVMM_DATA_WIDTH))
		# await self.csr.write(self.BAR_ACTN_DATA+0x000C, (action_data >> 96) % (1 << self.AVMM_DATA_WIDTH))

		# TODO: mask
		csr_op_code = (1 << self.CSR_ACTN_WR) | (
		    action_addr << self.CSR_ACTN_OFFSET % 0x10000)
		await self.csr.write(self.BAR_CSR, csr_op_code)


async def run_test(dut, payload_lengths=None, payload_data=None, idle_inserter=None, backpressure_inserter=None):
	tb = AppMAT_TB(dut)
	await tb.reset()
	
	if idle_inserter is not None:
		tb.rx_in.set_valid_generator(idle_inserter())
	if backpressure_inserter is not None:
		tb.backpressure.start(backpressure_inserter())

	dmac_dict = {}
	smac_dict = {}
	vlan_dict = {}
	channel_dict = {}
	search_keys = [0xC0A80101+i for i in range(tb.TCAM_DEPTH)]
	for i in range(tb.TCAM_DEPTH):
		dmac_1 = (0xD1_D1_D2_D3_D4_D5 + (i << 40)) % (1 << 48)
		smac_1 = (0x51_51_52_53_54_55 + (i << 40)) % (1 << 48)
		vlan_1 = (0xF001+i) % 0x10000
		channel_1 = (0x1+i) % 0x100
		dmac_dict[search_keys[i]] = dmac_1
		smac_dict[search_keys[i]] = smac_1
		vlan_dict[search_keys[i]] = vlan_1
		channel_dict[search_keys[i]] = channel_1
		action_code_1 = libmat.f_get_action_code(d_mac=dmac_1, s_mac=smac_1, vl_data=vlan_1, fwd_id=channel_1,
                                           vl_op=0b01, fwd_en=True, cks_en=True, d_mac_en=True, s_mac_en=True)
		await tb.cfg_action(action_code_1, i)

	for i in range(tb.TCAM_DEPTH//8):
		tcam_data = search_keys[8*i:8*i+8]
		tcam_addr = i*8
		await tb.cfg_tcam(tcam_data=tcam_data, tcam_addr=tcam_addr)

	MAC_WIDTH = 48
	DMAC_OFFSET = tb.AVST_DATA_WIDTH-MAC_WIDTH
	SMAC_OFFSET = DMAC_OFFSET-MAC_WIDTH
	ET_WIDTH = 16
	ET_OFFSET = SMAC_OFFSET-ET_WIDTH
	VLAN_WIDTH = 16
	VLAN_OFFSET = SMAC_OFFSET-VLAN_WIDTH-16
	DIP_OFFSET_v4 = tb.AVST_DATA_WIDTH-34*8
	DIP_OFFSET_VL = tb.AVST_DATA_WIDTH-34*8-2*16
	IP_WIDTH = 32
	min_1 = 22
	step_1 = 16
	max_1 = (tb.TCAM_DEPTH+2)*step_1
	i = -1
	for payload in [payload_data(x) for x in payload_lengths(min_1, max_1, step_1)]:
		i = i+1
		eth = Ether(src='5A:51:52:53:54:55', dst='DA:D1:D2:D3:D4:D5')
		dip = '192.168.1.' + str(i % 256)
		ip = IP(src='192.168.1.16', dst=dip)
		udp = UDP(sport=1, dport=2)
		pkt_sent = eth / ip / udp / payload

		await tb.rx_in.send(pkt_sent.build())
		await RisingEdge(tb.dut.avst_rx_out_valid)
		if not (int(tb.dut.avst_rx_out_startofpacket.value) == 1):
			await RisingEdge(tb.dut.avst_rx_out_startofpacket)
		await RisingEdge(tb.dut.clk)
		# valid = int(tb.dut.avst_rx_out_valid.value)
		# sop = int(tb.dut.avst_rx_out_startofpacket.value)
		# input("valid = %d \nsop = %d" % (valid, sop))

		pkt_recv = int(tb.dut.avst_rx_out_data.value)
		dmac_2 = libmat.f_get(pkt_recv, DMAC_OFFSET, MAC_WIDTH)
		smac_2 = libmat.f_get(pkt_recv, SMAC_OFFSET, MAC_WIDTH)
		vlan_2 = libmat.f_get(pkt_recv, VLAN_OFFSET, VLAN_WIDTH)
		channel_2 = tb.dut.avst_rx_out_channel.value
		et_2	 = libmat.f_get(pkt_recv, ET_OFFSET, ET_WIDTH)
		dip_2_vl = libmat.f_get(pkt_recv, DIP_OFFSET_VL, IP_WIDTH)
		dip_2_v4 = libmat.f_get(pkt_recv, DIP_OFFSET_v4, IP_WIDTH)
		sk = dip_2_v4 if (et_2 == 0x0800) else dip_2_vl
		
		dmac_1 = dmac_dict.get(sk, 0xDA_D1_D2_D3_D4_D5)
		smac_1 = smac_dict.get(sk, 0x5A_51_52_53_54_55)
		vlan_1 = vlan_dict.get(sk, 0x4500)
		channel_1 = channel_dict.get(sk, 0x0)

		tb.log.debug("search key: %X" % (sk))
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
			tb.log.debug("\n failed! \n")
			input("push any key...")


def cycle_pause():
	return itertools.cycle([1, 1, 1, 0])


def size_list(min_1=8, max_1=8, step_1=1):
	return list(range(min_1, max_1+1, step_1))


def incrementing_payload(length):
	return bytes(itertools.islice(itertools.cycle(range(1, 256)), length))


if cocotb.SIM_NAME:
	factory = TestFactory(run_test)
	factory.add_option("payload_lengths", [size_list])
	factory.add_option("payload_data", [incrementing_payload])
	factory.add_option("idle_inserter", [None])
	factory.add_option("backpressure_inserter", [None])
	# factory.add_option("idle_inserter", [None, cycle_pause])
	# factory.add_option("backpressure_inserter", [None, cycle_pause])
	factory.generate_tests()
