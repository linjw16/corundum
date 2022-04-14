/*
 * Created on Mon Mar 21 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 l3fwd_cfg.c
 * @Author:		 Jiawei Lin
 * @Last edit:	 21:20:27
 *
 * cd ../modules/mqnic/ && rmmod mqnic.ko && clear && make clean && mk && insmod mqnic.ko && cd ../../utils
 * clear && make clean && mk && ./l3fwd_cfg -d l3fwd
 */

/*

source /home/linjw/vivado_setup.sh
xsdb
connect
fpga -f /home/linjw/prj_f1000/.backup/f1000_0408.bit

rmmod mqnic.ko
sh /home/linjw/rec_f1000/pcie_hot_reset.sh af:00.0
insmod /home/linjw/prj/f1000_25g/modules/mqnic/mqnic.ko
dmesg -T | grep mqnic

IF=p4p1

# filename: replay.sh
  tcpreplay -i $IF -M '1' -l 100 ./pkt_send_v4.pcap
  tcpreplay -i $IF -M '1' -l 100 ./pkt_send_300.pcap
  tcpreplay -i $IF -M '1' -l 100 ./pkt_send_301.pcap

# filename: dump.sh
tcpdump -c 1000 -i p4p1 -w p4p1.pcap &
tcpdump -c 1000 -i enp175s0d1 -w p4p2.pcap &
tcpdump -c 1000 -i enp175s0d2 -w p4p3.pcap &
tcpdump -c 1000 -i enp175s0d3 -w p4p4.pcap &

*/

#include "l3fwd.h"

#include <dirent.h>
#include <fcntl.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>

static int l3fwd_try_open(struct l3fwd *dev, const char *fmt, ...)
{
	va_list ap;
	char path[PATH_MAX + 32];
	struct stat st;
	char *ptr = NULL;

	va_start(ap, fmt);
	vsnprintf(dev->device_path, sizeof(dev->device_path), fmt, ap);
	va_end(ap);
	fprintf(stderr, "\t linjw: device_path: %s \n", (dev->device_path));

	dev->pci_device_path[0] = 0;

	if (access(dev->device_path, W_OK))
		return -1;

	if (stat(dev->device_path, &st))
		return -1;

	if (S_ISDIR(st.st_mode))
		return -1;

	dev->fd = open(dev->device_path, O_RDWR);

	if (dev->fd < 0)
	{
		perror("open device failed");
		goto fail_open;
	}

	if (fstat(dev->fd, &st))
	{
		perror("fstat failed");
		goto fail_fstat;
	}

	dev->regs_size = st.st_size;
	fprintf(stderr, "\t linjw: st_size: %zu \n", (dev->regs_size));

	if (dev->regs_size == 0)
	{
		struct l3fwd_ioctl_info info;
		if (ioctl(dev->fd, L3FWD_IOCTL_INFO, &info) != 0)
		{
			perror("MQNIC_IOCTL_INFO ioctl failed");
			goto fail_ioctl;
		}

		dev->regs_size = info.regs_size;
		fprintf(stderr, "\t linjw: fw_id: %08X \n", (info.fw_id));
		fprintf(stderr, "\t linjw: fw_ver: %08X \n", (info.fw_ver));
		fprintf(stderr, "\t linjw: board_id: %08X \n", (info.board_id));
		fprintf(stderr, "\t linjw: board_ver: %08X \n", (info.board_ver));
		fprintf(stderr, "\t linjw: regs_size: %zu \n", (info.regs_size));
	}

	// determine sysfs path of PCIe device
	// first, try to find via miscdevice
	ptr = strrchr(dev->device_path, '/');
	ptr = ptr ? ptr + 1 : dev->device_path;

	snprintf(path, sizeof(path), "/sys/class/misc/%s/device", ptr);

	if (!realpath(path, dev->pci_device_path))
	{
		// that failed, perhaps it was a PCIe resource
		snprintf(path, sizeof(path), "%s", dev->device_path);
		ptr = strrchr(path, '/');
		if (ptr)
			*ptr = 0;

		if (!realpath(path, dev->pci_device_path))
			dev->pci_device_path[0] = 0;
	}

	// PCIe device will have a config space, so check for that
	if (dev->pci_device_path[0])
	{
		snprintf(path, sizeof(path), "%s/config", dev->pci_device_path);

		if (access(path, F_OK))
			dev->pci_device_path[0] = 0;
	}

	// map registers
	dev->regs = (volatile uint8_t *)mmap(NULL, dev->regs_size, PROT_READ | PROT_WRITE, MAP_SHARED, dev->fd, 0);
	if (dev->regs == MAP_FAILED)
	{
		perror("mmap regs failed");
		goto fail_mmap_regs;
	}

	if (dev->pci_device_path[0] && l3fwd_reg_read32(dev->regs, 4) == 0xffffffff)
	{
		// if we were given a PCIe resource, then we may need to enable the device
		snprintf(path, sizeof(path), "%s/enable", dev->pci_device_path);

		if (access(path, W_OK) == 0)
		{
			FILE *fp = fopen(path, "w");

			if (fp)
			{
				fputc('1', fp);
				fclose(fp);
			}
		}
	}

	if (l3fwd_reg_read32(dev->regs, 4) == 0xffffffff)
	{
		fprintf(stderr, "Error: device needs to be reset\n");
		goto fail_reset;
	}
	
	dev->rb_list = enumerate_reg_block_list(dev->regs, 0, dev->regs_size);

	if (!dev->rb_list)
	{
		fprintf(stderr, "Error: filed to enumerate blocks\n");
		goto fail_enum;
	}

	for (int i = 0; i < 0x10; i = i + 4)
	{
		fprintf(stdout, "\t reg[%04X] = %08X,", i, l3fwd_reg_read32(dev->regs, i));
		if (i % 0x10 == 0xC)
		{
			fprintf(stdout, "\n");
		}
	}

	// Read ID registers
	dev->app_mat_rb = find_reg_block(dev->rb_list, MQNIC_RB_APP_MAT_TYPE, MQNIC_RB_APP_MAT_VER, 0);

	if (!dev->app_mat_rb)
	{
		fprintf(stderr, "Error: APP_MAT block not found\n");
		goto fail_enum;
	}

	return 0;

fail_enum:
	if (dev->rb_list)
		free_reg_block_list(dev->rb_list);
fail_reset:
	munmap((void *)dev->regs, dev->regs_size);
fail_mmap_regs:
fail_ioctl:
fail_fstat:
	close(dev->fd);
fail_open:
	return -1;
}

static int l3fwd_try_open_if_name(struct l3fwd *dev, const char *if_name)
{
	DIR *folder;
	struct dirent *entry;
	char path[PATH_MAX];

	snprintf(path, sizeof(path), "/sys/class/net/%s/device/misc/", if_name);

	folder = opendir(path);
	if (!folder)
		return -1;

	while ((entry = readdir(folder)))
	{
		if (entry->d_name[0] != '.')
			break;
	}

	if (!entry)
	{
		closedir(folder);
		return -1;
	}

	snprintf(path, sizeof(path), "/dev/%s", entry->d_name);

	closedir(folder);

	return l3fwd_try_open(dev, "%s", path);
}

struct l3fwd *l3fwd_open(const char *dev_name)
{
	struct l3fwd *dev = calloc(1, sizeof(struct l3fwd));

	if (!dev)
	{
		perror("memory allocation failed");
		goto fail_alloc;
	}

	// absolute path
	if (l3fwd_try_open(dev, "/dev/%s", dev_name) == 0)
		goto open;

	if (l3fwd_try_open(dev, "%s", dev_name) == 0)
		goto open;

	// network interface
	if (l3fwd_try_open_if_name(dev, dev_name) == 0)
		goto open;

	// PCIe sysfs path
	if (l3fwd_try_open(dev, "%s/resource0", dev_name) == 0)
		goto open;

	// PCIe BDF (dddd:xx:yy.z)
	if (l3fwd_try_open(dev, "/sys/bus/pci/devices/%s/resource0", dev_name) == 0)
		goto open;

	// PCIe BDF (xx:yy.z)
	if (l3fwd_try_open(dev, "/sys/bus/pci/devices/0000:%s/resource0", dev_name) == 0)
		goto open;

	goto fail_open;

open:
	return dev;

fail_open:
	free(dev);
fail_alloc:
	return NULL;
}

void l3fwd_close(struct l3fwd *dev)
{
	if (!dev)
		return;

	if (dev->rb_list)
		free_reg_block_list(dev->rb_list);

	munmap((void *)dev->regs, dev->regs_size);
	close(dev->fd);
	free(dev);
}

static void usage(char *name)
{
	fprintf(stderr,
			"usage: %s [options]\n"
			" -d name    device to open (/dev/l3fwd)\n"
			" -i         initial table entries\n"
			" -r file    read entries to file\n"
			" -w file    write entries from file\n",
			name);
}

#define TCAM_WIDTH 32
// #define DEBUG

#define FILE_TYPE_BIN 0
#define FILE_TYPE_HEX 1
#define FILE_TYPE_BIT 2

int l3fwd_tcam_wr(struct reg_block *rb, uint32_t data[8], uint32_t keep[8], uint16_t addr)
{
	if (rb->type != MQNIC_RB_APP_MAT_TYPE || rb->version != MQNIC_RB_APP_MAT_VER)
	{
		fprintf(stderr, "TYPE/VER check failed. \n");
		return -1;
	}

	for (int i = 0; i < 8; i++)
	{
		l3fwd_reg_write32(rb->base, APP_MAT_BAR_TCAM_DATA + i * 4, data[i]);
		l3fwd_reg_write32(rb->base, APP_MAT_BAR_TCAM_KEEP + i * 4, keep[i]);
		uint16_t addr_1 = APP_MAT_BAR_TCAM_DATA + i * 4;
		uint16_t addr_2 = APP_MAT_BAR_TCAM_KEEP + i * 4;
		fprintf(stdout, "\t tcam_data[%04X] = %08X\n", addr_1, data[i]);
		fprintf(stdout, "\t tcam_keep[%04X] = %08X\n", addr_2, keep[i]);
	}

	uint32_t csr = 0x8000 | (addr & 0x7FFF);
	l3fwd_reg_write32(rb->base, APP_MAT_BAR_CSR, csr);
	fprintf(stdout, "\t csr[%04X] = %08X\n", APP_MAT_BAR_CSR, csr);

	if (csr == l3fwd_reg_read32(rb->base, APP_MAT_BAR_CSR)){
		return 0;
	} else {
		fprintf(stderr, "l3fwd_tcam_wr failed. \n");
		return -1;
	}
}

int l3fwd_actn_wr(struct reg_block *rb, struct actn_entry e, uint16_t addr)
{
	if (rb->type != MQNIC_RB_APP_MAT_TYPE || rb->version != MQNIC_RB_APP_MAT_VER)
	{
		fprintf(stderr, "TYPE/VER check failed. \n");
		return -1;
	}
	uint32_t mask = 0xFFFFFFFF;
	uint32_t val = (e.dmac >> 16) & mask;
	uint16_t addr_1 = APP_MAT_BAR_ACTN_DATA + 0x0;
	fprintf(stdout, "\t actn_data[%04X] = %08X\n", addr_1, val);
	l3fwd_reg_write32(rb->base, addr_1, val);
	val = (((e.dmac << 16) | (e.smac >> 32)) & mask);
	addr_1 = addr_1 + 4;
	fprintf(stdout, "\t actn_data[%04X] = %08X\n", addr_1, val);
	l3fwd_reg_write32(rb->base, addr_1, val);
	val = (e.smac & mask);
	addr_1 = addr_1 + 4;
	fprintf(stdout, "\t actn_data[%04X] = %08X\n", addr_1, val);
	l3fwd_reg_write32(rb->base, addr_1, val);
	val = (((e.vlan << 16) | (e.channel << 8) | e.op_code) & mask);
	addr_1 = addr_1 + 4;
	fprintf(stdout, "\t actn_data[%04X] = %08X\n", addr_1, val);
	l3fwd_reg_write32(rb->base, addr_1, val);

	uint32_t csr = (0x8000 | (addr & 0x7FFF)) << 16;
	l3fwd_reg_write32(rb->base, APP_MAT_BAR_CSR, csr);
	fprintf(stdout, "\t csr[%04X] = %08X\n", APP_MAT_BAR_CSR, csr);

	if (csr == l3fwd_reg_read32(rb->base, APP_MAT_BAR_CSR))
	{
		return 0;
	}
	else
	{
		fprintf(stderr, "l3fwd_actn_wr failed. \n");
		return -1;
	}
}

int main(int argc, char *argv[])
{

	char *name;
	int opt;
	int rtn = 0;

	char *device = NULL;
	char *read_file_name = NULL;
	char *write_file_name = NULL;
	// FILE *read_file = NULL;
	// FILE *write_file = NULL;

	char path[PATH_MAX + 32];

	char arg_read = 0;
	char arg_write = 0;
	char arg_init = 0;

	struct l3fwd *dev = NULL;

	name = strrchr(argv[0], '/');
	name = name ? 1 + name : argv[0];

	while ((opt = getopt(argc, argv, "d:r:w:h?i")) != EOF)
	{
		switch (opt)
		{
		case 'd':
			device = optarg;
			break;
		case 'i':
			arg_init = 1;
			break;
		case 'r':
			arg_read = 1;
			read_file_name = optarg;
			break;
		case 'w':
			arg_write = 1;
			write_file_name = optarg;
			break;
		case 'h':
		case '?':
			usage(name);
			return 0;
		default:
			usage(name);
			return -1;
		}
	}
	if (!device)
	{
		fprintf(stderr, "Device not specified\n");
		usage(name);
		device = "l3fwd";
	}

#ifndef DEBUG

	dev = l3fwd_open(device);

	if (!dev)
	{
		fprintf(stderr, "Failed to open device\n");
		return -1;
	}

	if (!dev->pci_device_path[0])
	{
		fprintf(stderr, "Failed to determine PCIe device path\n");
		rtn = -1;
		goto err;
	}

#else

	struct l3fwd t;
	dev = &t;
	volatile uint8_t rb_regs[0x200] = {};
	struct reg_block rb = 
	{
		MQNIC_RB_APP_MAT_TYPE,
		MQNIC_RB_APP_MAT_VER,
		rb_regs,
		rb_regs
	};
	dev->app_mat_rb = &rb;

#endif

	fprintf(stderr, "\t(r,w,i) = (%d,%d,%d)\n", arg_read, arg_write, arg_init);
	fprintf(stderr, "\tread filename: %s\n", read_file_name);
	fprintf(stderr, "\twrite filename: %s\n", write_file_name);
	fprintf(stderr, "path: %s\n", path);

	if (arg_init)
	{
		uint32_t data[8] = {
			0xC0A80101,
			0xC0A80102,
			0xC0A80103,
			0xC0A80104,
			0xC0A80105,
			0xC0A80106,
			0xC0A80107,
			0xC0A80108
		};
		uint32_t keep[8] = {
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF
		};
		uint16_t addr = 0x0000;
		l3fwd_tcam_wr(dev->app_mat_rb, data, keep, addr);
		sleep(0.1);

		for (int i = 0; i < 0x8; i++)
		{
			struct actn_entry entry = {
				0xDAD1D2D3D4D0+i, 
				0x5A5152535450+i, 
				0xFF00+i, 
				(0x01+i)%0x8, 
				0b11011100
			};
			l3fwd_actn_wr(dev->app_mat_rb, entry, addr+i);
		}
	}

	if (arg_read)
	{
		for (int i = 0; i < 0x200; i = i + 4)
		{
			fprintf(stdout, "\t reg[%04X] = %08X,", i, l3fwd_reg_read32(dev->regs, i));
			if (i % 0x10 == 0xC){
				fprintf(stdout, "\n");
			}
		}
	}

#ifndef DEBUG
err:
	l3fwd_close(dev);
#endif
	return rtn;
}
