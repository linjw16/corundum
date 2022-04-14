// SPDX-License-Identifier: BSD-2-Clause-Views
/*
 * Copyright 2019-2021, The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *    1. Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation
 * are those of the authors and should not be interpreted as representing
 * official policies, either expressed or implied, of The Regents of the
 * University of California.
 */

/*
 * Created on Mon Mar 28 2022
 *
 * Copyright (c) 2022 IOA UCAS
 *
 * @Filename:	 l3fwd_dev.c
 * @Author:		 Jiawei Lin
 * @Last edit:	 22:13:58
 */

#include "mqnic.h"
#include "l3fwd_ioctl.h"

#include <linux/uaccess.h>

static int l3fwd_open(struct inode *inode, struct file *file)
{
	// struct miscdevice *miscdev = file->private_data;
	// struct mqnic_dev *mqnic = container_of(miscdev, struct mqnic_dev, misc_dev);

	return 0;
}

static int l3fwd_release(struct inode *inode, struct file *file)
{
	// struct miscdevice *miscdev = file->private_data;
	// struct mqnic_dev *mqnic = container_of(miscdev, struct mqnic_dev, misc_dev);

	return 0;
}

static int l3fwd_map_registers(struct mqnic_dev *mqnic, struct vm_area_struct *vma)
{
	size_t map_size = vma->vm_end - vma->vm_start;
	int ret;

	if (map_size > mqnic->app_hw_regs_size) {
		dev_err(mqnic->dev, "%s: Tried to map registers region with wrong size %lu (expected <= %llu)",
				__func__, vma->vm_end - vma->vm_start, mqnic->app_hw_regs_size);
		return -EINVAL;
	}

	ret = remap_pfn_range(vma, vma->vm_start, mqnic->app_hw_regs_phys >> PAGE_SHIFT,
			map_size, pgprot_noncached(vma->vm_page_prot));

	printk("linjw: %s: &app_hw_regs_phys = 0x%pap, virt: 0x%p", __func__, &mqnic->app_hw_regs_phys, (void *)vma->vm_start);

	if (ret)
		dev_err(mqnic->dev, "%s: remap_pfn_range failed for registers region", __func__);
	else
		dev_dbg(mqnic->dev, "%s: Mapped registers region at phys: 0x%pap, virt: 0x%p",
				__func__, &mqnic->app_hw_regs_phys, (void *)vma->vm_start);

	return ret;
}

static int l3fwd_mmap(struct file *file, struct vm_area_struct *vma)
{
	struct miscdevice *miscdev = file->private_data;
	struct mqnic_dev *mqnic = container_of(miscdev, struct mqnic_dev, misc_dev_app);

	if (vma->vm_pgoff == 0)
		return l3fwd_map_registers(mqnic, vma);

	dev_err(mqnic->dev, "%s: Tried to map an unknown region at page offset %lu",
			__func__, vma->vm_pgoff);
	return -EINVAL;
}

static long l3fwd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
	struct miscdevice *miscdev = file->private_data;
	struct mqnic_dev *mqnic = container_of(miscdev, struct mqnic_dev, misc_dev_app);

	if (_IOC_TYPE(cmd) != L3FWD_IOCTL_TYPE)
		return -ENOTTY;
	printk("mqnic->fw_id: %08X", mqnic->fw_id);
	printk("mqnic->fw_ver: %08X", mqnic->fw_ver);
	printk("mqnic->board_id: %08X", mqnic->board_id);
	printk("mqnic->board_ver: %08X", mqnic->board_ver);
	printk("mqnic->app_hw_regs_size: %llu", mqnic->app_hw_regs_size);
	switch (cmd) {
	case L3FWD_IOCTL_INFO:
		{
			struct l3fwd_ioctl_info ctl;

			ctl.fw_id = mqnic->fw_id;
			ctl.fw_ver = mqnic->fw_ver;
			ctl.board_id = mqnic->board_id;
			ctl.board_ver = mqnic->board_ver;
			ctl.regs_size = mqnic->app_hw_regs_size;

			if (copy_to_user((void __user *)arg, &ctl, sizeof(ctl)) != 0)
				return -EFAULT;

			return 0;
		}
	default:
		return -ENOTTY;
	}
}

const struct file_operations l3fwd_fops = {
	.owner = THIS_MODULE,
	.open = l3fwd_open,
	.release = l3fwd_release,
	.mmap = l3fwd_mmap,
	.unlocked_ioctl = l3fwd_ioctl,
};
