#ifndef _NET_OVPN_NET_GSO_H_
#define _NET_OVPN_NET_GSO_H_

#include <linux/version.h>

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 4, 10) ||     \
	SUSE_PRODUCT_CODE >= SUSE_PRODUCT(1, 15, 6, 0) || \
	RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(9, 4)
#include_next <net/gso.h>
#else
#include <linux/netdevice.h>
#endif /* LINUX_VERSION_CODE >= KERNEL_VERSION(6, 4, 10) || SUSE_PRODUCT_CODE >= SUSE_PRODUCT(1, 15, 6, 0) || RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(9, 4) */

#endif /* _NET_OVPN_NET_GSO_H_ */
