
#
# Created on Fri Mar 04 2022
#
# Copyright (c) 2022 IOA UCAS
#
# @Filename:	 testbench.py
# @Author:		 Jiawei Lin
# @Last edit:	 16:21:41
#
from cocotbext.axi import AxiLiteBus, AxiLiteMaster
from cocotbext.axi import AxiStreamBus, AxiStreamFrame
from cocotbext.axi import AxiStreamSource, AxiStreamSink
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

## TODO list: 
## 3. test the correct of tid, tdest, tuser

class AppTopTB(object):
	def __init__(self, dut, debug=True):
		level = logging.DEBUG if debug else logging.WARNING
		self.log = logging.getLogger("TB")
		self.log.setLevel(level)

		self.dut = dut
		self.source = AxiStreamSource(
			AxiStreamBus.from_prefix(dut, "s_axis_rx"), dut.clk, dut.rst)
		self.sink = AxiStreamSink(
			AxiStreamBus.from_prefix(dut, "m_axis_rx"), dut.clk, dut.rst)
		self.axil_master = AxiLiteMaster(
			AxiLiteBus.from_prefix(dut, "s_axil"), dut.clk, dut.rst)
		self.source.log.setLevel(level)
		self.sink.log.setLevel(level)
		
		self.AXIS_DATA_WIDTH = self.dut.AXIS_DATA_WIDTH
		self.TCAM_DEPTH = self.dut.app_mat_inst.TCAM_DEPTH.value
		self.TCAM_WR_WIDTH = self.dut.app_mat_inst.TCAM_WR_WIDTH.value

		self.BAR_TCAM_DATA	 = self.dut.app_mat_inst.BAR_TCAM_DATA.value
		self.BAR_TCAM_KEEP	 = self.dut.app_mat_inst.BAR_TCAM_KEEP.value
		self.BAR_ACTN_DATA	 = self.dut.app_mat_inst.BAR_ACTN_DATA.value
		self.BAR_CSR		 = self.dut.app_mat_inst.BAR_CSR.value
		self.CSR_TCAM_OFFSET = self.dut.app_mat_inst.CSR_TCAM_OFFSET.value
		self.CSR_TCAM_WR = self.dut.app_mat_inst.CSR_TCAM_WR.value
		self.CSR_ACTN_OFFSET = self.dut.app_mat_inst.CSR_ACTN_OFFSET.value
		self.CSR_ACTN_WR = self.dut.app_mat_inst.CSR_ACTN_WR.value

		self.tcam_dict = {}
		self.tcam_list = [set()]*self.TCAM_DEPTH
		self.act_table = [0]*self.TCAM_DEPTH
		
		cocotb.start_soon(Clock(dut.clk, 4, units="ns").start())

	async def reset(self):
		await RisingEdge(self.dut.clk)
		await RisingEdge(self.dut.clk)
		self.dut.s_axis_rx_tdata.value = 0
		self.dut.s_axis_rx_tkeep.value = 0
		self.dut.s_axis_rx_tvalid.value = 0
		self.dut.m_axis_rx_tready.value = 0
		self.dut.s_axis_rx_tlast.value = 0
		self.dut.s_axis_rx_tid.value = 0
		self.dut.s_axis_rx_tdest.value = 0
		self.dut.s_axis_rx_tuser.value = 0

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
		self.dut.m_axis_rx_tready.value = 1

	def set_idle_generator_axil(self, generator=None):
		if generator:
			self.axil_master.write_if.aw_channel.set_pause_generator(generator())
			self.axil_master.write_if.w_channel.set_pause_generator(generator())
			self.axil_master.read_if.ar_channel.set_pause_generator(generator())

	def set_backpressure_generator_axil(self, generator=None):
		if generator:
			self.axil_master.write_if.b_channel.set_pause_generator(generator())
			self.axil_master.read_if.r_channel.set_pause_generator(generator())

	def _model_wr(self, wr_data=0, wr_keep=0, wr_addr=0, idx=0):
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
			self._model_wr(wr_data, wr_keep, wr_addr, idx+1)
			self._model_wr(wr_data ^ (1 << idx), wr_keep, wr_addr, idx+1)

	async def cfg_tcam(self, tcam_data=([0]*8), tcam_keep=([(1 << 32)-1]*8), tcam_addr=0x0001):
		for i in range(8):
			set_2 = self.tcam_list[tcam_addr+i]
			for sk in set_2:
				set_1 = self.tcam_dict[sk].discard(tcam_addr+i)
			self.tcam_list[tcam_addr+i] = set()
			self._model_wr(tcam_data[i], tcam_keep[i], tcam_addr+i)
			self.log.debug("addr = %d; data = %X|%X" %
			               (tcam_addr+i, tcam_data[i], tcam_keep[i]))
			wr_data = libmat.int2bytearray(tcam_data[i], 4)
			await self.axil_master.write(self.BAR_TCAM_DATA+i*0x4, wr_data)
			wr_keep = libmat.int2bytearray(tcam_keep[i], 4)
			await self.axil_master.write(self.BAR_TCAM_KEEP+i*0x4, wr_keep)

		# TODO: mask
		csr_op_code = (1 << self.CSR_TCAM_WR) | (tcam_addr << self.CSR_TCAM_OFFSET % 0x10000)
		csr_op_code = libmat.int2bytearray(csr_op_code, 4)
		await self.axil_master.write(self.BAR_CSR, csr_op_code)

	async def cfg_action(self, action_data=0x0001, action_addr=0x0001):
		for i in range(4):
			wr_data = libmat.int2bytearray(action_data >> i*32, 4)
			await self.axil_master.write(self.BAR_ACTN_DATA+i*0x4, wr_data)

		# TODO: mask
		csr_op_code = (1 << self.CSR_ACTN_WR) | (action_addr << self.CSR_ACTN_OFFSET % 0x10000)
		csr_op_code = libmat.int2bytearray(csr_op_code, 4)
		await self.axil_master.write(self.BAR_CSR, csr_op_code)

	async def pkt_test(self, mtu=22, count=64):
		payloads = [bytearray([(x+k) % 256 for x in range(mtu)]) for k in range(count)]
		eth = Ether(src='5A:51:52:53:54:55', dst='DA:D1:D2:D3:D4:D5')
		ip = IP(src='192.168.1.100', dst='192.168.1.101')
		udp = UDP(sport=1, dport=2)

		tid_i = 0
		tdest_i = 0
		tx_frames = []
		for p in payloads:
			tid_i = (tid_i+1) % 0xFF
			tdest_i = (tdest_i+1) % 8
			test_pkt = eth / ip / udp / bytes(p)
			tx_frame = AxiStreamFrame(test_pkt.build())
			tx_frame.tid = tid_i
			tx_frame.tdest = tdest_i
			tx_frames.append(tx_frame)
			await self.source.send(tx_frame)
		
		for tx_frame in tx_frames:
			rx_frame = await self.sink.recv()
			try: 
				assert rx_frame.tdata == tx_frame.tdata
				# assert rx_frame.tid == tx_frame.tid
				assert rx_frame.tdest == tx_frame.tdest
			except AssertionError: input("\n\n pkt_test failed! \n")

		try: assert self.sink.empty()
		except AssertionError: input("\n\n pkt_test not empty! \n")

		return (~scapy.utils.checksum(bytes(tx_frames[0].tdata[14:])) & 0xffff)

async def run_test(dut, payload_lengths=None, payload_data=None, idle_inserter=None, backpressure_inserter=None):
	tb = AppTopTB(dut, True)
	await tb.reset()

	if idle_inserter is not None:
		tb.source.set_pause_generator(idle_inserter())
		tb.set_idle_generator_axil(idle_inserter)
	if backpressure_inserter is not None:
		tb.sink.set_pause_generator(backpressure_inserter())
		tb.set_backpressure_generator_axil(backpressure_inserter)

	## 3. Run tests.
	## TODO: 3.1 Checksum compare
	# tb.log.info("RX and TX checksum tests")
	# input("\nType any key to begin...")
	# chksum = await tb.pkt_test(mtu=60, count=4)
	# tb.log.debug("%X" % chksum)

	## 3.2 64B packet
	tb.log.info("Multiple small packets")
	# input("\nType any key to begin...")
	await tb.pkt_test(mtu=60, count=8)

	## 3.3 1400B packet
	tb.log.info("Multiple large packets")
	# input("\nType any key to begin...")
	await tb.pkt_test(mtu=1514, count=8)

	## 3.4 9400B packet
	tb.log.info("Jumbo frames")
	# input("\nType any key to begin...")
	await tb.pkt_test(mtu=9014, count=8)

	try:
		assert 1
		tb.log.debug("%d = %d" % (1, 2))
	except AssertionError:
		tb.log.debug("%d = %d" % (1, 2))
	return

async def run_test_cfg(dut, payload_lengths=None, payload_data=None, idle_inserter=None, backpressure_inserter=None):
	tb = AppTopTB(dut)
	await tb.reset()

	if idle_inserter is not None:
		tb.source.set_pause_generator(idle_inserter())
		tb.set_idle_generator_axil(idle_inserter)
	if backpressure_inserter is not None:
		tb.sink.set_pause_generator(backpressure_inserter())
		tb.set_backpressure_generator_axil(backpressure_inserter)
	
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
	DMAC_OFFSET = 0
	SMAC_OFFSET = DMAC_OFFSET+MAC_WIDTH
	ET_OFFSET = SMAC_OFFSET+MAC_WIDTH
	ET_WIDTH = 16
	VLAN_WIDTH = 16
	VLAN_OFFSET = ET_OFFSET+VLAN_WIDTH
	DIP_OFFSET_v4 = ET_OFFSET+ET_WIDTH+16*8
	DIP_OFFSET_VL = ET_OFFSET+ET_WIDTH+VLAN_WIDTH*2+16*8
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

		tx_frame = AxiStreamFrame(pkt_sent.build())
		await tb.source.send(tx_frame)

		pkt_recv = await tb.sink.recv()
		pkt_recv = pkt_recv.tdata
		dmac_2 = libmat.bytearray2int(pkt_recv, DMAC_OFFSET//8, MAC_WIDTH//8)
		smac_2 = libmat.bytearray2int(pkt_recv, SMAC_OFFSET//8, MAC_WIDTH//8)
		vlan_2 = libmat.bytearray2int(pkt_recv, VLAN_OFFSET//8, VLAN_WIDTH//8)
		channel_2 = tb.dut.m_axis_rx_tdest.value
		et_2 = libmat.bytearray2int(pkt_recv, ET_OFFSET//8, ET_WIDTH//8)
		dip_2_v4 = libmat.bytearray2int(pkt_recv, DIP_OFFSET_v4//8, IP_WIDTH//8)
		dip_2_vl = libmat.bytearray2int(pkt_recv, DIP_OFFSET_VL//8, IP_WIDTH//8)
		sk = dip_2_v4 if (et_2 == 0x0800) else dip_2_vl

		dmac_1 = dmac_dict.get(sk, 0xDA_D1_D2_D3_D4_D5)
		smac_1 = smac_dict.get(sk, 0x5A_51_52_53_54_55)
		vlan_1 = vlan_dict.get(sk, 0x4500)
		channel_1 = channel_dict.get(sk, 0x0)

		tb.log.debug("search key: %X" % (sk))
		tb.log.debug("assert inq==recv: %X==%X" % (dmac_1, dmac_2))
		tb.log.debug("assert inq==recv: %X==%X" % (smac_1, smac_2))
		tb.log.debug("assert inq==recv: %X==%X" % (vlan_1, vlan_2))
		tb.log.debug("assert inq==recv: %X==%X" % (channel_1, channel_2))
		try:
			assert dmac_2 == dmac_1
			assert smac_2 == smac_1
			assert vlan_2 == vlan_1
			assert channel_2 == channel_1
		except AssertionError:
			tb.log.debug("\n failed! \n")
			input("push any key...")
	return


def cycle_pause():
	return itertools.cycle([1, 1, 1, 0])


def size_list(min_1=8, max_1=8, step_1=1):
	return list(range(min_1, max_1+1, step_1))


def incrementing_payload(length):
	return bytes(itertools.islice(itertools.cycle(range(1, 256)), length))


if cocotb.SIM_NAME:
	factory = TestFactory(run_test_cfg)
	factory.add_option("payload_lengths", [size_list])
	factory.add_option("payload_data", [incrementing_payload])
	factory.add_option("idle_inserter", [None, cycle_pause])
	factory.add_option("backpressure_inserter", [None, cycle_pause])
	factory.generate_tests()
