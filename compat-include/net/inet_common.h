#ifndef _NET_OVPN_NET_INET_COMMON_H_
#define _NET_OVPN_NET_INET_COMMON_H_

#include <linux/version.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 0, 0) && \
	RHEL_RELEASE_CODE < RHEL_RELEASE_VERSION(9, 4)

#include <net/sock.h>
#include_next <net/inet_common.h>

#else

#include_next <net/inet_common.h>

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 0, 0) && RHEL_RELEASE_CODE < RHEL_RELEASE_VERSION(9, 4) */

#endif /* _NET_OVPN_NET_INET_COMMON_H_ */

