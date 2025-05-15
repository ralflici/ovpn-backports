#ifndef _NET_OVPN_NET_UDP_H_
#define _NET_OVPN_NET_UDP_H_

#include <linux/version.h>
#include_next <net/udp.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 16, 0)

#if IS_ENABLED(CONFIG_IPV6)
static inline void ovpn_udpv6_encap_disable(void)
{
	static_branch_dec(&udpv6_encap_needed_key);
}

#define udpv6_encap_disable ovpn_udpv6_encap_disable
#endif /* IS_ENABLED(CONFIG_IPV6) */

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 16, 0) */

#endif /* _NET_OVPN_NET_UDP_H_ */

