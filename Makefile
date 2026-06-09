.PHONY: build check lint test verify

YARN ?= corepack yarn

lint:
	sh scripts/check-baseline.sh
	$(YARN) lint

test:
	CI=true $(YARN) test --watchAll=false

build:
	$(YARN) build

verify: lint test build

check: verify
