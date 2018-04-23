
legal-info-wb45n_legacy legal-info-wb50n_legacy legal-info-som60 legal-info-bdimx6:
	make -C $(subst legal-info-,,$@) legal-info

msd45n msd-x86 msd50n wb50n_rdvk reg45n reg50n reglwb reglwb5 mfg60n wb45n_legacy wb50n_legacy som60 bdimx6 backports sterling_supplicant-x86 sterling_supplicant-arm sterling_supplicant-src lrd-network-manager-src:
	make -C $@ all

.PHONY: msd45n msd-x86 sterling_supplicant-x86 sterling_supplicant-arm lrd-network-manager-src \
	sterling_supplicant-src wb50n_rdvk reg45n reg50n reglwb reglwb5 mfg60n \
	wb45n_legacy wb50n_legacy msd50n legal-info-wb50n_legacy legal-info-wb45n_legacy \
	som60 legal-info-som60 bdimx6 legal-info-bdimx6 backports
