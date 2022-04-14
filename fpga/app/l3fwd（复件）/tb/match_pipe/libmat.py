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


def int2bytearray(int_1=0xDA_D1_D2_D3_D4_D5, size_1=6):
	if(size_1 * 8 < int_1.bit_length()):
		print("Cutting digit above %d" % (size_1 * 8))
	list_1 = [(int_1 >> (i-1)*8) % 0x100 for i in range(size_1,0,-1)]
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
