DATE = $(shell date "+%Y%m%d")
ifndef LAIRD_RELEASE_STRING
LAIRD_RELEASE_STRING := $(DATE)
endif
GITDIR=../../linux_docs

all:
	mkdir -p $(DATE)
	cp $(GITDIR)/60_series . -fr
	cp $(GITDIR)/LWB . -fr
	cp $(GITDIR)/latex_templates . -fr
	make -C 60_series/
	tar -cjf $(DATE)/laird-sterling-60-docs.tar.bz2  -C 60_series app_note_60_wow.pdf \
		sig_60_series_radio.pdf user_guide_60_dvk_su60_sipt.pdf
	rm 60_series -fr
	make -C LWB/
	tar -cjf $(DATE)/laird-sterling-lwb-docs.tar.bz2 -C LWB imx6_integration_howto.pdf
	rm LWB -fr
	rm latex_templates -fr
	rm -f latest
	ln -s "$(DATE)" latest
ifeq ($(BR2_DL_DIR),)
	cp latest/* ../../archive/ -fr
else
	cp latest/* $(BR2_DL_DIR)/ -fr
endif
