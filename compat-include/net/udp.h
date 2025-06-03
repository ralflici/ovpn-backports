#ifndef _NET_OVPN_NET_UDP_H_
#define _NET_OVPN_NET_UDP_H_

#include <linux/version.h>
#include_next <net/udp.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 16, 0)

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 7, 0)

#ifndef udp_test_and_clear_bit
#define udp_test_and_clear_bit(nr, sk)		\
	test_and_clear_bit(UDP_FLAGS_##nr, &udp_sk(sk)->udp_flags)
#endif /* udp_test_and_clear_bit */

#endif /* LINUX_VERSION_CODE >= KERNEL_VERSION(6, 7, 0) */

#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 12, 0)
static inline void ovpn_udp_encap_disable(void)
{
	struct static_key_false *udpv_encap_needed_key = (struct static_key_false *)kallsyms_lookup_name("udpv_encap_needed_key");

	if (!udpv_encap_needed_key) {
		pr_err("udpv_encap_needed_key symbol not found\n");
		return;
	}
	static_branch_dec(&udp_encap_needed_key);
}

#define udp_encap_disable ovpn_udp_encap_disable
#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(5, 12, 0) */

#if IS_ENABLED(CONFIG_IPV6)
static inline void ovpn_udpv6_encap_disable(void)
{
#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 9, 0)
	struct static_key_false *udpv6_encap_needed_key = (struct static_key_false *)kallsyms_lookup_name("udpv6_encap_needed_key");

	if (!udpv6_encap_needed_key) {
		pr_err("udpv6_encap_needed_key symbol not found\n");
		return;
	}
	static_branch_dec(udpv6_encap_needed_key);
#else
	static_branch_dec(&udpv6_encap_needed_key);
#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 9, 0) */
}

#define udpv6_encap_disable ovpn_udpv6_encap_disable
#endif /* IS_ENABLED(CONFIG_IPV6) */

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 7, 0)
static DEFINE_SPINLOCK(udp_encap_enabled_lock);
#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 7, 0) */

static inline void ovpn_udp_tunnel_encap_disable(struct sock *sk)
{
#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 7, 0)
	unsigned long irq_flags;
	int old_encap_enabled;

	spin_lock_irqsave(&udp_encap_enabled_lock, irq_flags);
	old_encap_enabled = udp_sk(sk)->encap_enabled;
	udp_sk(sk)->encap_enabled = 0;
	spin_unlock_irqrestore(&udp_encap_enabled_lock, irq_flags);
#else
	if (!udp_test_and_clear_bit(ENCAP_ENABLED, sk))
		return;
#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 7, 0) */

#if IS_ENABLED(CONFIG_IPV6)
	if (READ_ONCE(sk->sk_family) == PF_INET6)
		udpv6_encap_disable();
#endif
	udp_encap_disable();
}

#define udp_tunnel_encap_disable ovpn_udp_tunnel_encap_disable

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 16, 0) */

#endif /* _NET_OVPN_NET_UDP_H_ */

