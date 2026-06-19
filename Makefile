.PHONY: build check dependency-policy lint test verify

YARN ?= corepack yarn
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

dependency-policy:
	cd $(ROOT) && node scripts/check-dependency-policy.mjs
	cd $(ROOT) && sh scripts/test-dependency-policy.sh

lint: dependency-policy
	cd $(ROOT) && sh scripts/check-baseline.sh
	cd $(ROOT) && $(YARN) lint
	cd $(ROOT) && $(YARN) format:check

test:
	cd $(ROOT) && $(YARN) test

build:
	cd $(ROOT) && $(YARN) build

verify: lint test build

check: verify
