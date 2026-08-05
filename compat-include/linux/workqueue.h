#ifndef _NET_OVPN_LINUX_WORKQUEUE_H_
#define _NET_OVPN_LINUX_WORKQUEUE_H_

#include <linux/version.h>
#include_next <linux/workqueue.h>

#ifndef WORK_OFFQ_DISABLE_MASK
/* ovpn uses this while unregistering the netdevice, when no new keepalive
 * work can be queued after the synchronous cancellation has drained it.
 */
#define disable_delayed_work_sync cancel_delayed_work_sync
#endif /* WORK_OFFQ_DISABLE_MASK */

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 17, 0)

#define system_percpu_wq system_wq

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 17, 0) */

#endif /* _NET_OVPN_LINUX_WORKQUEUE_H_ */
