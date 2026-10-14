# SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
# SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
# SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
# SPDX-License-Identifier: Apache-2.0

# Makefile — sentin8-flutter (Flutter package repo, RS §4.5)
#
# Self-contained dev controls for THIS Flutter package. Sources the root .env for
# fleet env, guarantees the dev infra, and uses an ABSOLUTE
# SENTIN8_CAPTAIN_BINARY_PREFIX (cwd-independent — RS §4.5.1-1).
SHELL := /bin/bash

.PHONY: help build test lint format format-check pub-get clean

help: ## Show this help
	@echo "sentin8-flutter (Flutter package)"
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

build: ## Package — built by consuming apps (make build there)
	@echo "Flutter package — build via a consuming app (make build there)"

test: ## Flutter tests
	@flutter test

lint: ## flutter analyze
	@flutter analyze

pub-get: ## flutter pub get
	@flutter pub get

format: ## dart format
	@dart format lib/ test/ 2>/dev/null || dart format lib/

format-check: ## dart format --set-exit-if-changed
	@dart format --set-exit-if-changed lib/ test/ 2>/dev/null || dart format --set-exit-if-changed lib/

clean: ## flutter clean
	@flutter clean
