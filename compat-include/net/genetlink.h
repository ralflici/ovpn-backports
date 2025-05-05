#ifndef _NET_OVPN_NET_GENETLINK_H_
#define _NET_OVPN_NET_GENETLINK_H_

#include <linux/version.h>
#include_next <net/genetlink.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 10, 0) && \
	RHEL_RELEASE_CODE < RHEL_RELEASE_VERSION(8, 0)

#define genl_small_ops genl_ops
#define small_ops ops
#define n_small_ops n_ops

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(5, 10, 0) && RHEL_RELEASE_CODE < RHEL_RELEASE_VERSION(8, 0) */

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 2, 0) && \
	RHEL_RELEASE_CODE < RHEL_RELEASE_VERSION(9, 3)

#define genl_split_ops genl_ops
#define split_ops ops
#define n_split_ops n_ops

#ifndef container_of_const
#define container_of_const(ptr, type, member) \
	container_of_safe((ptr), (type), (member))
#endif /* container_of_const */

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 2, 0) && RHEL_RELEASE_CODE < RHEL_RELEASE_VERSION(9, 3) */

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 1, 0)

#ifndef GENL_REQ_ATTR_CHECK
#define GENL_REQ_ATTR_CHECK(info, attr) ({				\
	struct genl_info *__info = (info);				\
									\
	NL_REQ_ATTR_CHECK(__info->extack, NULL, __info->attrs, (attr));	\
})
#endif /* GENL_REQ_ATTR_CHECK */

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 1, 0) */

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 6, 0)

static inline struct net *ovpn_genl_info_net(const struct genl_info *info)
{
	return read_pnet(&((struct genl_info *)(info))->_net);
}

#define genl_info_net ovpn_genl_info_net

#endif /* LINUX_VERSION_CODE < KERNEL_VERSION(6, 6, 0) */

#endif /* _NET_OVPN_NET_GENETLINK_H_ */
