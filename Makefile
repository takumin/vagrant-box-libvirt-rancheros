.PHONY: build
build: clean
	@bash -c "$(CURDIR)/scripts/build.bash"

.PHONY: clean
clean:
	@rm -fr packer_output
	@rm -f *.box

.PHONY: distclean
distclean: clean
	@rm -fr vendor

.PHONY: direnv
direnv:
	@if [ ! -f "$(CURDIR)/.envrc" ]; then \
		{ \
			echo '#!/bin/sh'; \
			echo ''; \
			echo 'export VAGRANT_CLOUD_USER="takumin"'; \
			echo 'export VAGRANT_CLOUD_REPO="rancheros"'; \
			echo 'export VAGRANT_CLOUD_TOKEN=""'; \
			echo 'export VAGRANT_BOX_PROVIDER="libvirt"'; \
			echo 'export VAGRANT_BOX_VERSION=""'; \
			echo 'export VAGRANT_BOX_FILENAME="vagrant-box-$${VAGRANT_BOX_PROVIDER}-rancheros-$${VAGRANT_BOX_VERSION}.box"'; \
		} > "$(CURDIR)/.envrc"; \
	fi
	@direnv allow
