SHELL := bash

.PHONY: test webui-check package build clean

SOURCE_REF ?= main

test:
	bash ./scripts/test.sh

webui-check:
	bash ./scripts/check-webui.sh

package:
	@test -n "$(SOURCE_DIR)" || (echo "SOURCE_DIR wajib diisi" >&2; exit 2)
	bash ./scripts/package-module.sh "$(SOURCE_DIR)" "$(SOURCE_REF)" dist

build:
	@test -n "$(SOURCE_DIR)" || (echo "SOURCE_DIR wajib diisi" >&2; exit 2)
	bash ./scripts/build-fork.sh "$(SOURCE_DIR)" "$(SOURCE_REF)" dist

clean:
	rm -rf -- dist
