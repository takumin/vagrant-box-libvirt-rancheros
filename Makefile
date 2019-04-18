.PHONY: build
build:
	@bash -c "$(CURDIR)/scripts/build.bash"

.PHONY: clean
clean:
	@rm -f *.box
