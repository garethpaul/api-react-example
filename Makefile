.PHONY: build check lint test verify

YARN ?= corepack yarn

lint:
	sh scripts/check-baseline.sh
	$(YARN) lint
	$(YARN) format:check

test:
	$(YARN) test

build:
	$(YARN) build

verify: lint test build

check: verify
