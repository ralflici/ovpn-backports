#ifndef _NET_OVPN_TRACE_EVENTS_SOCK_H_
#define _NET_OVPN_TRACE_EVENTS_SOCK_H_

#include <linux/version.h>
#include_next <trace/events/sock.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 3, 0)

#define trace_sk_data_ready(sock) do {} while (0)

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 3, 0) */

#endif /* _NET_OVPN_TRACE_EVENTS_SOCK_H_ */
