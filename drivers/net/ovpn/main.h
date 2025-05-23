/* SPDX-License-Identifier: GPL-2.0-only */
/*  OpenVPN data channel offload
 *
 *  Copyright (C) 2020-2025 OpenVPN, Inc.
 *
 *  Author:	Antonio Quartulli <antonio@openvpn.net>
 */

#ifndef _NET_OVPN_MAIN_H_
#define _NET_OVPN_MAIN_H_

bool ovpn_dev_is_valid(const struct net_device *dev);

#include <linux/kprobes.h>

typedef unsigned long (*kallsyms_lookup_name_t)(const char *name);
static kallsyms_lookup_name_t kallsyms_lookup_name_p;

static inline unsigned long get_kallsyms_lookup_name(void)
{
	struct kprobe kp = { .symbol_name = "kallsyms_lookup_name" };
	unsigned long addr;

	if (register_kprobe(&kp) < 0)
		return 0;

	addr = (unsigned long)kp.addr;
	unregister_kprobe(&kp);

	return addr;
}

static inline unsigned long ovpn_kallsyms_lookup_name(const char *name)
{
	if (!kallsyms_lookup_name_p)
		kallsyms_lookup_name_p =
			(kallsyms_lookup_name_t)get_kallsyms_lookup_name();

	if (kallsyms_lookup_name_p)
		return kallsyms_lookup_name_p(name);
	else
		return 0;
}

#define kallsyms_lookup_name(_name) ovpn_kallsyms_lookup_name((_name))

#endif /* _NET_OVPN_MAIN_H_ */
