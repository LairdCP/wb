CC = gcc
CFLAGS = -Wall -g

NLLIBNAME = libnl-3.0
WLAN_API = WLAN_API_NL80211
WLAN_API_SRCS = nl80211.c

SRCS = os.c $(WLAN_API_SRCS) libtcmd.c
OBJS = $(SRCS:.c=.o)
PKGCONFIG = pkg-config

LDLIBS += $(shell $(PKGCONFIG) --libs $(NLLIBNAME)) -lrt
CFLAGS += $(shell $(PKGCONFIG) --cflags $(NLLIBNAME)) -D$(WLAN_API) -DLIBNL_2

libtcmd.a: $(SRCS) $(OBJS)
	$(AR) rcs $@ $(OBJS)

$(OBJS): $(SRCS)
	$(CC) $(CFLAGS) -c $(@:.o=.c) -o $@ $(LDLIBS)

clean:
	rm -f *.a *.o
