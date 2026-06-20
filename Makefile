.PHONY: build check dependency-policy lint test verify workflow-policy

YARN ?= corepack yarn
override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

dependency-policy:
	cd $(ROOT) && node scripts/check-dependency-policy.mjs
	cd $(ROOT) && sh scripts/test-dependency-policy.sh

workflow-policy:
	cd $(ROOT) && node scripts/check-workflow-policy.mjs
	cd $(ROOT) && sh scripts/test-workflow-policy.sh

lint: workflow-policy dependency-policy
	cd $(ROOT) && sh scripts/check-baseline.sh
	cd $(ROOT) && $(YARN) lint
	cd $(ROOT) && $(YARN) format:check

test:
	cd $(ROOT) && $(YARN) test

build:
	cd $(ROOT) && $(YARN) build

verify: lint test build

check: verify
