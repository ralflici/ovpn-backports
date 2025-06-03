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

	rcu_assign_sk_user_data(sk, NULL);
	udp_tunnel_encap_disable(sk);
}

#define cleanup_udp_tunnel_sock ovpn_cleanup_udp_tunnel_sock

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 16, 0) */

#endif /* _NET_OVPN_NET_UDP_TUNNEL_H_ */
