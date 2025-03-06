#ifndef _NET_OVPN_CRYPTO_AEAD_H_
#define _NET_OVPN_CRYPTO_AEAD_H_

#include <linux/version.h>
#include_next <crypto/aead.h>

#if LINUX_VERSION_CODE <= KERNEL_VERSION(6, 2, 0)

typedef void (*ovpn_crypto_completion_t)(void *, int);

static inline void
ovpn_aead_request_set_callback(struct aead_request *req, u32 flags,
			       ovpn_crypto_completion_t compl, void *data)
{
	crypto_completion_t c = (crypto_completion_t) compl;
	req->base.complete = c;
	req->base.data = data;
	req->base.flags = flags;
}

#define aead_request_set_callback ovpn_aead_request_set_callback

#endif /* LINUX_VERSION_CODE <= KERNEL_VERSION(6, 2, 0) */

#endif /* _NET_OVPN_CRYPTO_AEAD_H_ */
