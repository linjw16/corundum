/*
 * Created on Thu Mar 31 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 l3fwd.h
 * @Author:		 Jiawei Lin
 * @Last edit:	 11:16:27
 */

#ifndef L3FWD_H
#define L3FWD_H

#include <limits.h>
#include <stdint.h>
#include <unistd.h>

// #include "mqnic_hw.h"
#include "l3fwd_ioctl.h"
#include "reg_block.h"

#define l3fwd_reg_read32(base, reg) (((volatile uint32_t *)(base))[(reg) / 4])
#define l3fwd_reg_write32(base, reg, val) (((volatile uint32_t *)(base))[(reg) / 4]) = val

/* filename: tb/fpga_core/mqnic.py, modules/mqnic_hw.h */
#define MQNIC_RB_APP_MAT_TYPE 0x01020304
#define MQNIC_RB_APP_MAT_VER 0x00000100
#define APP_MAT_BAR_TCAM_DATA 0x0100
#define APP_MAT_BAR_TCAM_KEEP 0x0180
#define APP_MAT_BAR_ACTN_DATA 0x0010
#define APP_MAT_BAR_CSR 0x0020
#define MQNIC_BOARD_ID_F1000 0x10ee9013

struct l3fwd {
	int fd;

	size_t regs_size;
	volatile uint8_t *regs;

	struct reg_block *rb_list;
	struct reg_block *app_mat_rb;

	char build_date_str[32];

	char device_path[PATH_MAX];
	char pci_device_path[PATH_MAX];

};

struct l3fwd *l3fwd_open(const char *dev_name);
void l3fwd_close(struct l3fwd *dev);

// int l3fwd_tcam_wr(uint32_t[8], uint32_t[8], uint32_t);
// int l3fwd_actn_wr(uint64_t dmac, uint64_t smac, uint16_t vlan, uint8_t channel, uint8_t op_code, uint32_t addr);

struct actn_entry
{
	uint64_t dmac;
	uint64_t smac;
	uint16_t vlan;
	uint8_t channel;
	uint8_t op_code;
};

#endif