.PHONY: build
build:
	@bash -c "$(CURDIR)/build.bash"

.PHONY: clean
clean:
	@rm -f "*.box"
