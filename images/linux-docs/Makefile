DATE = $(shell date "+%Y%m%d")
GITDIR=../../linux_docs

all:
	mkdir -p $(DATE)
	cp $(GITDIR)/60_series . -fr
	cp $(GITDIR)/LWB . -fr
	cp $(GITDIR)/latex_templates . -fr
	make -C 60_series/
	tar -cjf $(DATE)/laird-sterling-60-docs.tar.bz2  -C 60_series app_note_60_wow.pdf \
		sig_60_series_radio.pdf user_guide_60_dvk_su60_sipt.pdf app_note_60_vendor.pdf
	rm 60_series -fr
	make -C LWB/
	tar -cjf $(DATE)/laird-sterling-lwb-docs.tar.bz2 -C LWB imx6_integration_howto.pdf
	rm LWB -fr
	rm latex_templates -fr
	rm -f latest
	ln -s "$(DATE)" latest