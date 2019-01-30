TARGETS = $(patsubst %/,%,$(wildcard */))

$(TARGETS):
	make -C $@ all

.PHONY: $(TARGETS)
