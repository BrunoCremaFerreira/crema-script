BATS := tests/bats/bats-core/bin/bats
TESTS := tests/

.PHONY: test shellcheck setup

test: ## Run all bats tests
	$(BATS) --recursive $(TESTS)

shellcheck: ## Lint shell scripts with shellcheck
	shellcheck -x python/devtools/bin/devstart python/devtools/lib/lib.sh

setup: ## Add bats submodules (run once after cloning)
	git submodule add https://github.com/bats-core/bats-core     tests/bats/bats-core  || true
	git submodule add https://github.com/bats-core/bats-support  tests/bats/bats-support || true
	git submodule add https://github.com/bats-core/bats-assert   tests/bats/bats-assert  || true
	git submodule update --init --recursive

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
