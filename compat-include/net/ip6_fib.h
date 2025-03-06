#ifndef _NET_OVPN_NET_IP6_FIB_H_
#define _NET_OVPN_NET_IP6_FIB_H_

#include <linux/version.h>
#include_next <net/ip6_fib.h>

#if (LINUX_VERSION_CODE < KERNEL_VERSION(6, 2, 0) && \
	RHEL_RELEASE_CODE == 0) || \
	(RHEL_RELEASE_CODE < RHEL_RELEASE_VERSION(9, 3) && \
	RHEL_RELEASE_CODE > RHEL_RELEASE_VERSION(8, 10))

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 16, 0)
#include <linux/container_of.h>
#endif /* LINUX_VERSION_CODE >= KERNEL_VERSION(5, 16, 0) */

#define dst_rt6_info(_ptr) container_of_safe(_ptr, struct rt6_info, dst)

#elif LINUX_VERSION_CODE < KERNEL_VERSION(6, 10, 0)

#include <linux/container_of.h>

#define dst_rt6_info(_ptr) container_of_const(_ptr, struct rt6_info, dst)

#endif /* (LINUX_VERSION_CODE < KERNEL_VERSION(6, 2, 0) && RH_RELEASE_CODE == 0) || (RH_RELEASE_CODE < RH_RELEASE_VERSION(9, 3) && RH_RELEASE_CODE > RH_RELEASE_VERSION(8, 10)) */

#endif /* _NET_OVPN_NET_IP6_FIB_H_ */
