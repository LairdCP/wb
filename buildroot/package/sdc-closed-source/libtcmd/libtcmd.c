/*
* Copyright (c) 2011-2012 Qualcomm Atheros Inc.
*
* Permission to use, copy, modify, and/or distribute this software for any
* purpose with or without fee is hereby granted, provided that the above
* copyright notice and this permission notice appear in all copies.
*
* THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
* WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
* MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
* ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
* WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
* ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
* OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

#include "string.h"
#include "libtcmd.h"
#include "os.h"

int tcmd_tx(void *buf, int len, bool resp)
{
	int err = 0;

	/* XXX: just call nl80211 directly for now */
#ifdef WLAN_API_NL80211
	if ((err = nl80211_tcmd_tx(&tcmd_cfg, buf, len)))
		goto err_out;
#endif
	if (resp)
#ifdef WLAN_API_NL80211
		err = nl80211_tcmd_rx(&tcmd_cfg);
#endif

	return err;
err_out:
	A_DBG("tcmd_tx failed: %s\n", strerror(-err));
	return err;
}

static void tcmd_expire(union sigval sig)
{
	/* tcmd expired, do something */
	A_DBG("timer expired\n");
	tcmd_cfg.timeout = true;
}

/* get driver ep from tcmd ep */
static int tcmd_set_ep(uint32_t *driv_ep, enum tcmd_ep ep)
{
#ifdef WLAN_API_NL80211
	return nl80211_set_ep(driv_ep, ep);
#endif
}
int tcmd_init(char *iface, void (*rx_cb)(void *buf, int len), ...)
{
	int err;
	enum tcmd_ep ep;
	va_list ap;
	va_start(ap, rx_cb);
	ep = va_arg(ap, enum tcmd_ep);
	va_end(ap);

	strcpy(tcmd_cfg.iface, iface);
	tcmd_cfg.rx_cb = rx_cb;
	if ((err = tcmd_set_ep(&tcmd_cfg.ep, ep)))
		return err;

	tcmd_cfg.sev.sigev_notify = SIGEV_THREAD;
	tcmd_cfg.sev.sigev_notify_function = tcmd_expire;
	timer_create(CLOCK_REALTIME, &tcmd_cfg.sev, &tcmd_cfg.timer);

#ifdef WLAN_API_NL80211
	if ((err = nl80211_init(&tcmd_cfg))) {
                A_DBG("couldn't init nl80211!: %s\n", strerror(-err));
		return err;
	}
#endif

	return 0;
}

int tcmd_tx_init(char *iface, void (*rx_cb)(void *buf, int len))
{
	return tcmd_init(iface, rx_cb, TCMD_EP_TCMD);
}
