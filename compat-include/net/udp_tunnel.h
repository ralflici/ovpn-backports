#ifndef _NET_OVPN_NET_UDP_TUNNEL_H_
#define _NET_OVPN_NET_UDP_TUNNEL_H_

#include <linux/version.h>
#include_next <net/udp_tunnel.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 16, 0)

static inline void ovpn_cleanup_udp_tunnel_sock(struct sock *sk)
{
	/* Re-enable multicast loopback */
	inet_set_bit(MC_LOOP, sk);

	/* Disable CHECKSUM_UNNECESSARY to CHECKSUM_COMPLETE conversion */
	inet_dec_convert_csum(sk);

	rcu_assign_sk_user_data(sk, NULL);

	udp_sk(sk)->encap_type = 0;
	udp_sk(sk)->encap_rcv = NULL;
	udp_sk(sk)->encap_err_rcv = NULL;
	udp_sk(sk)->encap_err_lookup = NULL;
	udp_sk(sk)->encap_destroy = NULL;
	udp_sk(sk)->gro_receive = NULL;
	udp_sk(sk)->gro_complete = NULL;

	udp_clear_bit(ENCAP_ENABLED, sk);
#if IS_ENABLED(CONFIG_IPV6)
	if (READ_ONCE(sk->sk_family) == PF_INET6)
		udpv6_encap_disable();
#endif
	udp_encap_disable();
}

#define cleanup_udp_tunnel_sock ovpn_cleanup_udp_tunnel_sock

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 16, 0) */

#endif /* _NET_OVPN_NET_UDP_TUNNEL_H_ */
