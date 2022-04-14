#
# Created on Mon Mar 07 2022
#
# Copyright (c) 2022 IOA UCAS
#
# @Filename:	 libmat.py
# @Author:		 Jiawei Lin
# @Last edit:	 09:41:38
#

def f_get(data_in=0x10, offset=0x0, width=0x1, byte_rvs=False):
	mask_1 = (1 << width)-1
	data_temp = (data_in >> offset)
	if (byte_rvs):
		data_out = 0
		size_1 = width//8
		for i in range(size_1):
			data_out += (data_temp >> ((size_1-i-1)*8) & 0xFF) << i*8
	else:
		data_out = data_temp & mask_1
	return data_out


def f_assign(data_in=0x10, data_set=0x1, offset=0x0, width=0x1, length=128):
	mask_1 = (((1 << width)-1) << offset) | (1 << length)
	# print("data_in \t= %x\nmask \t= %x" % (data_in, mask_1))
	data_in = data_in & (~mask_1)
	data_set = (data_set << offset) & mask_1
	data_out = data_in | data_set
	# print("data_set \t= %x\ndata_out \t= %x" % (data_set, data_out))
	return data_out


def f_print_action_code(int_1, str_1="", offset=0, width=0):
	if (width == 0):
		width = len(hex(int_1))-2
	mask = (1 << width)-1
	int_1 = (int_1 >> offset) & mask
	print("%s: %#x" % (str_1, int_1))


def f_get_action_code(fwd_id=0x1, fwd_en=True, vl_data=0x1, vl_op=0x0, cks_en=True, d_mac=0x01, d_mac_en=True, s_mac=0x01, s_mac_en=True):
	DMAC_OFFSET = 80
	SMAC_OFFSET = 32
	VLAN_OFFSET = 16
	FWD_OFFSET = 8
	OP_DMAC_OFFSET = 7
	OP_SMAC_OFFSET = 6
	OP_VLAN_OFFSET = 4
	OP_FWD_OFFSET = 3
	OP_CSUM_OFFSET = 2
	d_1 = 0
	d_1 = f_assign(d_1, d_mac, 		DMAC_OFFSET, 	48)
	d_1 = f_assign(d_1, s_mac, 		SMAC_OFFSET, 	48)
	d_1 = f_assign(d_1, vl_data, 	VLAN_OFFSET, 	16)
	d_1 = f_assign(d_1, fwd_id, 	FWD_OFFSET, 	8)
	d_1 = f_assign(d_1, d_mac_en, 	OP_DMAC_OFFSET, 1)
	d_1 = f_assign(d_1, s_mac_en, 	OP_SMAC_OFFSET, 1)
	d_1 = f_assign(d_1, vl_op, 		OP_VLAN_OFFSET, 2)
	d_1 = f_assign(d_1, fwd_en, 	OP_FWD_OFFSET, 	1)
	d_1 = f_assign(d_1, cks_en, 	OP_CSUM_OFFSET, 1)
	f_print_action_code(d_1, '	d_mac		', 	DMAC_OFFSET, 	48)
	f_print_action_code(d_1, '	s_mac		', 	SMAC_OFFSET, 	48)
	f_print_action_code(d_1, '	vl_data		', 	VLAN_OFFSET, 	16)
	f_print_action_code(d_1, '	fwd_id		', 	FWD_OFFSET, 	8)
	f_print_action_code(d_1, '	d_mac_en	', 	OP_DMAC_OFFSET, 1)
	f_print_action_code(d_1, '	s_mac_en	', 	OP_SMAC_OFFSET, 1)
	f_print_action_code(d_1, '	vl_op		', 	OP_VLAN_OFFSET, 2)
	f_print_action_code(d_1, '	fwd_en		', 	OP_FWD_OFFSET, 	1)
	f_print_action_code(d_1, '	cks_en		', 	OP_CSUM_OFFSET, 1)
	return d_1


def int2bytearray(int_1=0xDA_D1_D2_D3_D4_D5, size_1=6, reverse_1=False):
	if(size_1 * 8 < int_1.bit_length()):
		print("Cutting digit above %d" % (size_1 * 8))
	
	if reverse_1:
		list_1 = [(int_1 >> (i-1)*8) % 0x100 for i in range(size_1,0,-1)]
	else:
		list_1 = [(int_1 >> (i*8)) % 0x100 for i in range(size_1)]
		
	bytearray_1 = bytearray(list_1)
	# str_1 = bytearray_1.decode('utf-8')
	print("\tint to bytearray: \t%X = %s" % (int_1, bytearray_1))
	return bytearray_1


def bytearray2int(bytearray_1=b'\xDA\xD1\xD2\xD3\xD4\xD5', offset_1=0, size_1=6, reverse_1=False):
	int_1 = 0
	for i in range(size_1):
		if (reverse_1):
			int_1 = int_1 + (bytearray_1[offset_1+i] << (i*8))
		else:
			int_1 = int_1 + (bytearray_1[offset_1+i] << ((size_1-i-1)*8))
	print("%s, offset_1=%d, size_1=%d, int_1=%X" %
	      (bytearray_1, offset_1, size_1, int_1))
	return int_1


def f_gen_hdr_suf40(Valid=True, PT=0x1, PS=0x10, Var=0, Len=0x40):
	arr_1 = [0]*5
	arr_1[0] = Len
	arr_1[1] = Var & 0x00FF
	arr_1[2] = Var >> 8
	arr_1[3] = PS + ((PT & 0x3) << 6)
	arr_1[4] = Valid << 2 + (PT >> 2)
	return bytes(arr_1[-1::-1])


async def test(tb):
	dmac_dict = {}
	smac_dict = {}
	vlan_dict = {}
	chnl_dict = {}
	search_keys = [0xC0A80101+i for i in range(tb.TCAM_DEPTH)]
	for i in range(tb.TCAM_DEPTH):
		dmac_1 = (0xD1_D1_D2_D3_D4_D5 + (i << 40)) % (1 << 48)
		smac_1 = (0x51_51_52_53_54_55 + (i << 40)) % (1 << 48)
		vlan_1 = (0xF001+i) % 0x10000
		chnl_1 = (0x1+i) % 0x100
		dmac_dict[search_keys[i]] = dmac_1
		smac_dict[search_keys[i]] = smac_1
		vlan_dict[search_keys[i]] = vlan_1
		chnl_dict[search_keys[i]] = chnl_1
		action_code_1 = f_get_action_code(d_mac=dmac_1, s_mac=smac_1, vl_data=vlan_1, fwd_id=chnl_1,
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

	count = 64
	payloads = [bytes([(x+k) % 256 for x in range(1514)]) for k in range(count)]
	for k, payload in enumerate(payloads):
		eth = Ether(src='5A:51:52:53:54:55', dst='DA:D1:D2:D3:D4:D5')
		dip = '192.168.1.' + str(k % 256)
		ip = IP(src='192.168.1.16', dst=dip)
		udp = UDP(sport=1, dport=2)
		pkt_sent = eth / ip / udp / payload
		await tb.send()
		# await tb.driver.interfaces[0].start_xmit(pkt_sent, k % len(tb.driver.interfaces[0].ports))

	for k in range(count):
		pkt_recv = await tb.recv()
		# pkt_recv = await tb.driver.interfaces[0].recv()
		pkt_recv = pkt_recv.data
		dmac_2 = 	bytearray2int(pkt_recv, DMAC_OFFSET//8, MAC_WIDTH//8)
		smac_2 = 	bytearray2int(pkt_recv, SMAC_OFFSET//8, MAC_WIDTH//8)
		vlan_2 = 	bytearray2int(pkt_recv, VLAN_OFFSET//8, VLAN_WIDTH//8)
		et_2 = 		bytearray2int(pkt_recv, ET_OFFSET//8, ET_WIDTH//8)
		dip_2_v4 = 	bytearray2int(pkt_recv, DIP_OFFSET_v4//8, IP_WIDTH//8)
		dip_2_vl = 	bytearray2int(pkt_recv, DIP_OFFSET_VL//8, IP_WIDTH//8)
		sk = dip_2_v4 if (et_2 == 0x0800) else dip_2_vl

		dmac_1 = dmac_dict.get(sk, 0xDA_D1_D2_D3_D4_D5)
		smac_1 = smac_dict.get(sk, 0x5A_51_52_53_54_55)
		vlan_1 = vlan_dict.get(sk, 0x4500)
		chnl_1 = chnl_dict.get(sk, 0x0)
		chnl_2 = 0

		tb.log.debug("search key: %X" % (sk))
		tb.log.debug("assert inq==recv: %X==%X" % (dmac_1, dmac_2))
		tb.log.debug("assert inq==recv: %X==%X" % (smac_1, smac_2))
		tb.log.debug("assert inq==recv: %X==%X" % (vlan_1, vlan_2))
		tb.log.debug("assert inq==recv: %X==%X" % (chnl_1, chnl_2))
		try:
			assert dmac_2 == dmac_1
			assert smac_2 == smac_1
			assert vlan_2 == vlan_1
			# assert chnl_2 == chnl_1
		except AssertionError:
			tb.log.debug("\n failed! \n")
			input("push any key...")
