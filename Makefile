.PHONY: build check lint test verify

YARN ?= corepack yarn
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

lint:
	cd $(ROOT) && sh scripts/check-baseline.sh
	cd $(ROOT) && $(YARN) lint
	cd $(ROOT) && $(YARN) format:check

test:
	cd $(ROOT) && $(YARN) test

build:
	cd $(ROOT) && $(YARN) build

verify: lint test build

check: verify
