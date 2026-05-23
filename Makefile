.PHONY: help version bump-patch bump-minor bump-major project build test archive release clean

SHELL := /bin/bash
PROJECT := Clacky.xcodeproj
SCHEME := Clacky
RELEASE_DIR := release

help:
	@echo "Clacky make targets"
	@echo "  version       Show current version"
	@echo "  bump-patch    Bump patch (0.1.0 -> 0.1.1) and regenerate project"
	@echo "  bump-minor    Bump minor and regenerate project"
	@echo "  bump-major    Bump major and regenerate project"
	@echo "  project       Regenerate Clacky.xcodeproj from project.yml"
	@echo "  build         Debug build (xcodebuild)"
	@echo "  test          Run unit tests"
	@echo "  archive       Release archive (ad-hoc signed if no identity set)"
	@echo "  release       Sign + notarize + DMG + ZIP into release/ (needs APPLE_* env)"
	@echo "  clean         Remove build outputs"

version:
	@grep -E '^\s*MARKETING_VERSION:' project.yml | head -1 | sed 's/.*"\(.*\)".*/Version: \1/'
	@grep -E '^\s*CURRENT_PROJECT_VERSION:' project.yml | head -1 | sed 's/.*"\(.*\)".*/Build:   \1/'

bump-patch:
	@python3 scripts/bump_version.py patch
	@$(MAKE) project

bump-minor:
	@python3 scripts/bump_version.py minor
	@$(MAKE) project

bump-major:
	@python3 scripts/bump_version.py major
	@$(MAKE) project

project:
	@command -v xcodegen >/dev/null || { echo "xcodegen not installed (brew install xcodegen)"; exit 1; }
	@xcodegen generate

build: project
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build

test: project
	@xcodebuild test -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO -enableCodeCoverage NO

archive: project
	@bash scripts/make_release.sh --archive-only

release: project
	@bash scripts/make_release.sh

clean:
	@rm -rf $(RELEASE_DIR) build DerivedData
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean >/dev/null 2>&1 || true
	@echo "Cleaned."
