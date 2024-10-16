#!/usr/bin/make --no-print-directory --jobs=1 --environment-overrides -f

SHELL := /bin/bash

CORELIB_NAME := $(shell basename "${CORELIB_PKG}")

VERSION_TAGS        += CORELIBS
CORELIBS_MK_SUMMARY := Go-CoreLibs.mk
CORELIBS_MK_VERSION := v0.2.0

GOPKG_KEYS          ?=
GOPKG_AUTO_CORELIBS ?= true
LOCAL_CORELIBS_PATH ?= ..

DEFAULT_CLEAN_FILES ?= coverage.{out,html} go_*.test *.pprof *.test
ifeq (${OVERRIDE_CLEAN_FILES},true)
CLEAN_FILES ?= ${DEFAULT_CLEAN_FILES}
else
CLEAN_FILES += ${DEFAULT_CLEAN_FILES}
endif
CLEAN_FILES += ${BUILD_COMMANDS}

GOTESTS_SKIP ?=
_GOTEST_SKIP := $(shell \
	echo "${GOTESTS_SKIP}" \
		| perl -e '@s=();while(<>){s/^\s*(.+?)\s*$$/$$1/;chomp;push(@s,$$_);};print join("/",@s);' \
)
GOTESTS_ARGV ?= .
GOTESTS_TAGS ?= all

_GOTEST_OPTS := -v -race -failfast
_GOTEST_TAGS := $(shell \
	echo "${GOTESTS_TAGS}" \
		| perl -pe 's/^\s+//ms;s/\s+$$//ms;s/\s+/\n/msg;' \
		| perl -pe 's/\n/,/' \
)

COVER_PROFILE ?= coverage.out
COVER_MODE    ?= atomic
COVER_PKG     ?= ${GOTESTS_ARGV}

CONVEY_HOST    ?= 0.0.0.0
CONVEY_PORT    ?= 8080
CONVEY_POLL    ?= 500ms
CONVEY_DEPTH   ?= -1
CONVEY_TIMEOUT ?= 1s
CONVEY_BROWSER ?= false
CONVEY_EXCLUDE ?=
_CONVEY_EXCLUDED := $(shell \
	echo "${CONVEY_EXCLUDE}" \
		| perl -e '@s=();while(<>){s/^\s*(.+?)\s*$$/$$1/;chomp;push(@s,$$_);};print join(",",@s);' \
)

PPROF_PORT  ?= 8081
PPROF_CPU   ?= cpu.pprof
PPROF_MEM   ?= mem.pprof

BENCH       ?= ^Benchmark
BENCH_COUNT ?= 1
BENCH_CPU   ?= 1
BENCH_CMD   ?= go test -run='^$$' -bench='${BENCH}' -count=${BENCH_COUNT} -cpu=${BENCH_CPU}

DEPS += github.com/smartystreets/goconvey
DEPS += golang.org/x/vuln/cmd/govulncheck
DEPS += github.com/fzipp/gocyclo/cmd/gocyclo
DEPS += github.com/gordonklaus/ineffassign
DEPS += github.com/client9/misspell/cmd/misspell

.PHONY: help version
.PHONY: local unlocal be-update tidy
.PHONE: corelibs packages
.PHONY: deps build clean fmt
.PHONY: test coverage goconvey reportcard
.PHONE: bench bench.mem bench.cpu

#
#: Custom functions
#

define __list_gopkgs
$(if ${GOPKG_KEYS},$(foreach key,${GOPKG_KEYS},$(shell \
		PKG="$($(key)_GO_PACKAGE)"; \
		VER="$($(key)_LATEST_VER)"; \
		if [ -n "$${PKG}" -a "$${PKG}" != "nil" ]; then \
			if [ -n "$${VER}" -a -n "$(1)" ]; then \
				echo "$${PKG}@$${VER}"; \
			else \
				echo "$${PKG}$(1)"; \
			fi; \
		fi; \
	)))
endef

define __list_gopkgs_latest
$(call __list_gopkgs,@latest)
endef

define __list_corelibs
$(shell find * \
		-name "*.go" -exec grep '"github.com/go-corelibs/' \{\} \; \
		| perl -pe 's!^[^"]*!!;s![\s"]!!g;s!github\.com/go-corelibs/!!;s!$$!\n!;' \
		| sort -u -V \
		| grep -v "${CORELIB_NAME}" \
		| while read NAME; do \
			if [ -d "${LOCAL_CORELIBS_PATH}/$${NAME}" ]; then \
				echo "github.com/go-corelibs/$${NAME}$(1)"; \
			fi; \
	done)
endef

define __list_corelibs_latest
$(call __list_corelibs,@latest)
endef

define __go_test
$(shell \
	if [ -n "${_GOTEST_SKIP}" ]; then \
		if [ -n "${_GOTEST_TAGS}" ]; then \
			echo "${CMD} go test ${_GOTEST_OPTS} -timeout ${CONVEY_TIMEOUT} -tags \"${_GOTEST_TAGS}\" -skip \"${_GOTEST_SKIP}\""; \
		else \
			echo "${CMD} go test ${_GOTEST_OPTS} -timeout ${CONVEY_TIMEOUT} -skip \"${_GOTEST_SKIP}\""; \
		fi; \
	elif [ -n "${_GOTEST_TAGS}" ]; then \
		echo "${CMD} go test ${_GOTEST_OPTS} -timeout ${CONVEY_TIMEOUT} -tags \"${_GOTEST_TAGS}\""; \
	else \
		echo "${CMD} go test ${_GOTEST_OPTS} -timeout ${CONVEY_TIMEOUT}"; \
	fi \
)
endef

#
#: Actual targets
#

help: export FOUND_PKGS=$(call __list_gopkgs)
help: export FOUND_LIBS=$(call __list_corelibs)
help:
	@echo "# usage: make <help|version>"
	@echo "#        make <local|unlocal|be-update|tidy>"
	@echo "#        make <corelibs|packages>"
	@echo "#        make <deps|build|clean|fmt>"
	@echo "#        make <test|coverage|goconvey|reportcard>"
	@echo "#"
	@echo "# targets:"
	@echo "#"
	@echo "#  help           - this help screen"
	@echo "#  version        - build system versions"
	@echo "#"
	@echo "#  local          - go mod edit -replace"
	@echo "#  unlocal        - go mod edit -dropreplace"
	@echo "#  be-update      - go get @latest"
	@echo "#  tidy           - go mod tidy"
	@echo "#"
	@echo "#  corelibs       - list detected go-corelibs"
	@echo "#  packages       - list configured GOPKGS"
	@echo "#"
	@echo "#  deps           - install dependencies"
	@echo "#  build          - go build -v ./..."
	@echo "#  clean          - cleanup artifacts"
	@echo "#  fmt            - gofmt -s, goimports"
	@echo "#"
	@echo "#  test           - go test -race -v ./..."
	@echo "#  coverage       - go test cover -v ./..."
	@echo "#  goconvey       - goconvey -host=0.0.0.0"
	@echo "#  reportcard     - code sanity and style report"
	@if [ -n "$${FOUND_PKGS}" -o -n "$${FOUND_LIBS}" ]; then \
		if [ -n "$${FOUND_PKGS}" ]; then \
			echo "#"; \
			echo "# configured packages:"; \
			echo "#"; \
			for pkg in $${FOUND_PKGS}; do \
				echo "#  - $${pkg}"; \
			done; \
		fi; \
		if [ -n "$${FOUND_LIBS}" ]; then \
			echo "#"; \
			echo "# detected go-corelibs:"; \
			echo "#"; \
			for pkg in $${FOUND_LIBS}; do \
				echo "#  - $${pkg}"; \
			done; \
		fi; \
	fi

corelibs: export FOUND_LIBS=$(call __list_corelibs)
corelibs:
	@if [ -n "$${FOUND_LIBS}" ]; then \
		for FOUND in $${FOUND_LIBS}; do \
			echo "# $${FOUND}"; \
		done; \
	else \
		echo "# no go-corelibs detected"; \
	fi

packages: export FOUND_PKGS=$(call __list_gopkgs)
packages:
	@if [ -n "$${FOUND_PKGS}" ]; then \
		for FOUND in $${FOUND_PKGS}; do \
			echo "# $${FOUND}"; \
		done; \
	else \
		echo "# no GOPKGS configured"; \
	fi

version: LIST=$(foreach key,${VERSION_TAGS},\\n# $($(key)_MK_SUMMARY) $($(key)_MK_VERSION))
version:
	@echo -e -n "${LIST}" | column -t -N '#,SYSTEM,VERSION'

local: export FOUND_PKGS=$(call __list_gopkgs)
local: export FOUND_LIBS=$(call __list_corelibs)
local:
	@if [ -n "$${FOUND_PKGS}" -o -n "$${FOUND_LIBS}" ]; then \
		for found in $${FOUND_LIBS}; do \
			name=`echo "$${found}" | perl -pe "s~^github.com/go-corelibs/~~;"`; \
			echo "# go mod local go-corelibs/$${name}"; \
			go mod edit -replace=$${found}=${LOCAL_CORELIBS_PATH}/$${name}; \
		done; \
		$(foreach key,${GOPKG_KEYS},\
			if [ -n "$($(key)_LOCAL_PATH)" ]; then \
				if [ -d "$($(key)_LOCAL_PATH)" ]; then \
					echo "# go mod local $($(key)_GO_PACKAGE)"; \
					go mod edit -replace=$($(key)_GO_PACKAGE)=$($(key)_LOCAL_PATH); \
				else \
					echo "# error: $($(key)_GO_PACKAGE) not found"; \
				fi; \
			fi; \
		) \
	else \
		echo "# nothing to do"; \
	fi

unlocal: export FOUND_PKGS=$(call __list_gopkgs)
unlocal: export FOUND_LIBS=$(call __list_corelibs)
unlocal:
	@if [ -n "$${FOUND_PKGS}" -o -n "$${FOUND_LIBS}" ]; then \
		for found in $${FOUND_LIBS}; do \
			name=`echo "$${found}" | perl -pe "s~^github.com/go-corelibs/~~;"`; \
			echo "# go mod unlocal go-corelibs/$${name}"; \
			go mod edit -dropreplace=$${found}; \
		done; \
		$(foreach key,${GOPKG_KEYS},\
			if [ -n "$($(key)_LOCAL_PATH)" ]; then \
				echo "# go mod unlocal $($(key)_GO_PACKAGE)"; \
				go mod edit -dropreplace=$($(key)_GO_PACKAGE); \
			fi; \
		) \
	else \
		echo "# nothing to do"; \
	fi

be-update: export GOPROXY=direct
be-update: export FOUND_PKGS=$(call __list_gopkgs_latest)
be-update: export FOUND_LIBS=$(call __list_corelibs_latest)
be-update:
	@if [ "${GOPKG_AUTO_CORELIBS}" == "true" -a -n "$${FOUND_LIBS}" ]; then \
		if [ -n "$${FOUND_PKGS}" ]; then \
			echo "# go get $${FOUND_PKGS} $${FOUND_LIBS}"; \
			go get $${FOUND_PKGS} $${FOUND_LIBS}; \
		else \
			echo "# go get $${FOUND_LIBS}"; \
			go get $${FOUND_LIBS}; \
		fi; \
	elif [ -n "$${FOUND_PKGS}" ]; then \
		echo "# go get $${FOUND_PKGS}"; \
		go get $${FOUND_PKGS}; \
	else \
		echo "# nothing to do"; \
	fi

tidy:
	@${CMD} go mod tidy

deps:
	@for REPO in ${DEPS}; do \
		echo "# go install $${REPO}"; \
		${CMD} go install "$${REPO}@latest"; \
	done
	@echo "# go get ./..."
	@${CMD} go get ./...

build:
	@if [ -n "${BUILD_COMMANDS}" ]; then \
		for NAME in ${BUILD_COMMANDS}; do \
			if [ -d "./cmd/$${NAME}" ]; then \
				go build -v -o "$${NAME}" "./cmd/$${NAME}"; \
			else \
				echo "# package not found: ./cmd/$${NAME}"; \
				false; \
			fi; \
		done; \
	else \
		go build -v ./...; \
	fi

clean:
	@if [ -n "${CLEAN_FILES}" ]; then rm -fv ${CLEAN_FILES}; fi

fmt:
	@echo "# gofmt -s..."
	@gofmt -w -s `find * -name "*.go"`
	@echo "# goimports..."
	@goimports -w \
		-local "github.com/go-corelibs" \
		`find * -name "*.go"`

test:
	@${CMD} $(call __go_test) ${GOTESTS_ARGV}

coverage:
	@${CMD} $(call __go_test) \
		-coverprofile=${COVER_PROFILE} \
		-covermode=${COVER_MODE} \
		-coverpkg="${COVER_PKG}" \
		-v ${GOTESTS_ARGV}
	@${CMD} go tool cover -html=${COVER_PROFILE} -o=coverage.html
	@${CMD} go tool cover -func=${COVER_PROFILE}

goconvey:
	@echo "# running goconvey (${CONVEY_HOST}:${CONVEY_PORT};@${CONVEY_POLL})"
	@echo "# (press <CTRL+c> to stop)"
	@if [ -n "${_CONVEY_EXCLUDED}" ]; then \
		${CMD} goconvey \
			-timeout=${CONVEY_TIMEOUT} \
			-host=${CONVEY_HOST} \
			-port=${CONVEY_PORT} \
			-poll=${CONVEY_POLL} \
			-depth=${CONVEY_DEPTH} \
			-launchBrowser=${CONVEY_BROWSER} \
			-excludedDirs=${_CONVEY_EXCLUDED}; \
	else \
		${CMD} goconvey \
			-timeout=${CONVEY_TIMEOUT} \
			-host=${CONVEY_HOST} \
			-port=${CONVEY_PORT} \
			-poll=${CONVEY_POLL} \
			-depth=${CONVEY_DEPTH} \
			-launchBrowser=${CONVEY_BROWSER}; \
	fi

reportcard:
	@echo "# code sanity and style report"
	@echo "#: go vet"
	@${CMD} go vet ./...
	@echo "#: gocyclo"
	@${CMD} gocyclo -over 15 `find * -name "*.go"` || true
	@echo "#: ineffassign"
	@${CMD} ineffassign ./...
	@echo "#: misspell"
	@${CMD} misspell ./...
	@echo "#: gofmt -s"
	@echo -e -n `find * -name "*.go" | while read SRC; do \
		gofmt -s "$${SRC}" > "$${SRC}.fmts"; \
		if ! cmp "$${SRC}" "$${SRC}.fmts" 2> /dev/null; then \
			echo "can simplify: $${SRC}\\n"; \
		fi; \
		rm -f "$${SRC}.fmts"; \
	done`
	@echo "#: govulncheck"
	@echo -e -n `govulncheck ./... \
		| egrep '^Vulnerability #' \
		| sort -u -V \
		| while read LINE; do \
			echo "$${LINE}\n"; \
		done`

bench:
	@echo "# ${BENCH_CMD}" 1>&2
	@${CMD} ${BENCH_CMD}

bench.cpu:
	@echo "# ${BENCH_CMD} -cpuprofile ${PPROF_CPU}" 1>&2
	@if [ -f "${PPROF_CPU}" ]; then rm -fv "${PPROF_CPU}" || true; fi
	@${CMD} ${BENCH_CMD} -cpuprofile "${PPROF_CPU}"; \
		if [ -f "${PPROF_CPU}" ]; then \
			read -n 1 -p "# press <Enter> to start pprof on :${PPROF_PORT} " JUNK; \
			echo "# starting go tool ${PPROF_CPU} http://localhost:${PPROF_PORT}/"; \
			echo "# press <CTRL+c> to stop"; \
			go tool pprof -http=:${PPROF_PORT} "${PPROF_CPU}" 2> /dev/null; \
		else \
			echo "# ${PPROF_CPU} not found"; \
		fi

bench.mem:
	@echo "# ${BENCH_CMD} -memprofile ${PPROF_MEM}" 1>&2
	@if [ -f "${PPROF_MEM}" ]; then rm -fv "${PPROF_MEM}" || true; fi
	@${CMD} ${BENCH_CMD} -memprofile "${PPROF_MEM}"; \
		if [ -f "${PPROF_MEM}" ]; then \
			read -n 1 -p "# press <Enter> to start pprof on :${PPROF_PORT} " JUNK; \
			echo "# starting go tool ${PPROF_MEM} http://localhost:${PPROF_PORT}/"; \
			echo "# press <CTRL+c> to stop"; \
			go tool pprof -http=:${PPROF_PORT} "${PPROF_MEM}" 2> /dev/null; \
		else \
			echo "# ${PPROF_MEM} not found"; \
		fi
