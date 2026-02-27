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

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 17, 6)

static inline bool ovpn_poll_connection_based(struct sock *sk)
{
	return sk->sk_type == SOCK_SEQPACKET || sk->sk_type == SOCK_STREAM;
}

static inline __poll_t ovpn_datagram_poll_queue(struct file *file,
						 struct socket *sock,
						 poll_table *wait,
						 struct sk_buff_head *rcv_queue)
{
	struct sock *sk = sock->sk;
	__poll_t mask;
	u8 shutdown;

	sock_poll_wait(file, sock, wait);
	mask = 0;

	/* exceptional events? */
	if (READ_ONCE(sk->sk_err) ||
	    !skb_queue_empty_lockless(&sk->sk_error_queue))
		mask |= EPOLLERR |
			(sock_flag(sk, SOCK_SELECT_ERR_QUEUE) ? EPOLLPRI : 0);

	shutdown = READ_ONCE(sk->sk_shutdown);
	if (shutdown & RCV_SHUTDOWN)
		mask |= EPOLLRDHUP | EPOLLIN | EPOLLRDNORM;
	if (shutdown == SHUTDOWN_MASK)
		mask |= EPOLLHUP;

	/* readable? */
	if (!skb_queue_empty_lockless(rcv_queue))
		mask |= EPOLLIN | EPOLLRDNORM;

	/* Connection-based need to check for termination and startup. */
	if (ovpn_poll_connection_based(sk)) {
		int state = READ_ONCE(sk->sk_state);

		if (state == TCP_CLOSE)
			mask |= EPOLLHUP;
		/* connection hasn't started yet? */
		if (state == TCP_SYN_SENT)
			return mask;
	}

	/* writable? */
	if (sock_writeable(sk))
		mask |= EPOLLOUT | EPOLLWRNORM | EPOLLWRBAND;
	else
		sk_set_bit(SOCKWQ_ASYNC_NOSPACE, sk);

	return mask;
}

#define datagram_poll_queue ovpn_datagram_poll_queue

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 17, 6) */

#endif /* _NET_OVPN_NET_INET_COMMON_H_ */
