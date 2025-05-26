#ifndef _NET_OVPN_NET_UDP_TUNNEL_H_
#define _NET_OVPN_NET_UDP_TUNNEL_H_

#include <linux/version.h>
#include_next <net/udp_tunnel.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 16, 0)

static inline void ovpn_cleanup_udp_tunnel_sock(struct sock *sk)
{
	/* Re-enable multicast loopback */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 6, 0)
	inet_set_bit(MC_LOOP, sk);
#else
	inet_sk(sk)->mc_loop = 1;
#endif

	/* Disable CHECKSUM_UNNECESSARY to CHECKSUM_COMPLETE conversion */
	inet_dec_convert_csum(sk);

	rcu_assign_sk_user_data(sk, NULL);

	udp_sk(sk)->encap_type = 0;
	udp_sk(sk)->encap_rcv = NULL;
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 0, 0)
	udp_sk(sk)->encap_err_rcv = NULL;
#endif
	udp_sk(sk)->encap_err_lookup = NULL;
	udp_sk(sk)->encap_destroy = NULL;
	udp_sk(sk)->gro_receive = NULL;
	udp_sk(sk)->gro_complete = NULL;

	/* udp_destroy_sock() will first set the SOCK_DEAD flag
	 * and then decrease the udp_encap_key *WITHOUT*
	 * unsetting the UDP ENCAP_ENABLED bit.
	 * To avoid a double decrease, bail out if SOCK_DEAD
	 * is set.
	 */
	if (sock_flags(sk, SOCK_DEAD))
		return;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 7, 0)
	udp_clear_bit(ENCAP_ENABLED, sk);
#else
	udp_sk(sk)->encap_enabled = 0;
#endif
#if IS_ENABLED(CONFIG_IPV6)
	if (READ_ONCE(sk->sk_family) == PF_INET6)
		udpv6_encap_disable();
#endif
	udp_encap_disable();
}

#define cleanup_udp_tunnel_sock ovpn_cleanup_udp_tunnel_sock

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 16, 0) */

#endif /* _NET_OVPN_NET_UDP_TUNNEL_H_ */
