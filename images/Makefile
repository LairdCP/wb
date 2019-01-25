TARGETS = \
	bdimx6 backports firmware linux-docs \
	msd-x86 msd50n reg50n \
	wb50n_rdvk wb50n_legacy \
	reglwb reglwb5 \
	mfg60n-arm-eabi mfg60n-x86 mfg60n-arm-eabihf mfg60n-arm-eabiaarch64 \
	som60 som60sd som60sd_mfg ig60 \
	sterling_supplicant-x86 sterling_supplicant-arm sterling_supplicant-src \
	summit_supplicant-arm-eabi summit_supplicant-x86 summit_supplicant-arm-eabihf \
	lrd-network-manager-src

$(TARGETS):
	make -C $@ all

.PHONY: $(TARGETS)
