SHELL := bash

.PHONY: test package build clean

test:
	bash ./scripts/test.sh

package:
	@test -n "$(SOURCE_DIR)" || (echo "SOURCE_DIR wajib diisi" >&2; exit 2)
	@test -n "$(UPSTREAM_TAG)" || (echo "UPSTREAM_TAG wajib diisi" >&2; exit 2)
	bash ./scripts/package-module.sh "$(SOURCE_DIR)" "$(UPSTREAM_TAG)" dist

build:
	@test -n "$(SOURCE_DIR)" || (echo "SOURCE_DIR wajib diisi" >&2; exit 2)
	@test -n "$(UPSTREAM_TAG)" || (echo "UPSTREAM_TAG wajib diisi" >&2; exit 2)
	bash ./scripts/build-upstream.sh "$(SOURCE_DIR)" "$(UPSTREAM_TAG)" dist

clean:
	rm -rf -- dist

