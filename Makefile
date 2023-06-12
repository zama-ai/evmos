#!/usr/bin/make -f

include .env

PACKAGES_NOSIMULATION=$(shell go list ./... | grep -v '/simulation')
PACKAGES_SIMTEST=$(shell go list ./... | grep '/simulation')
DIFF_TAG=$(shell git rev-list --tags="v*" --max-count=1 --not $(shell git rev-list --tags="v*" "HEAD..origin"))
DEFAULT_TAG=$(shell git rev-list --tags="v*" --max-count=1)
VERSION ?= $(shell echo $(shell git describe --tags $(or $(DIFF_TAG), $(DEFAULT_TAG))) | sed 's/^v//')
TMVERSION := $(shell go list -m github.com/tendermint/tendermint | sed 's:.* ::')
COMMIT := $(shell git log -1 --format='%H')
LEDGER_ENABLED ?= true
BINDIR ?= $(GOPATH)/bin
EVMOS_BINARY = evmosd
EVMOS_DIR = evmos
BUILDDIR ?= $(CURDIR)/build
SIMAPP = ./app
HTTPS_GIT := https://github.com/evmos/evmos.git
DOCKER := $(shell which docker)
SUDO := $(shell which sudo)
ifneq ($(shell grep docker /proc/1/cgroup -qa),)
	SUDO :=
endif

DOCKER_BUF := $(DOCKER) run --rm -v $(CURDIR):/workspace --workdir /workspace bufbuild/buf
NAMESPACE := tharsishq
PROJECT := evmos
DOCKER_IMAGE := $(NAMESPACE)/$(PROJECT)
COMMIT_HASH := $(shell git rev-parse --short=7 HEAD)
DOCKER_TAG := $(COMMIT_HASH)
WORKDIR ?= $(CURDIR)/work_dir
# Needed as long as go-ethereum and ethermint are private repositories
GOPRIVATE = github.com/zama-ai/*

TFHE_RS_PATH ?= $(WORKDIR)/tfhe-rs
TFHE_RS_EXISTS := $(shell test -d $(TFHE_RS_PATH)/.git && echo "true" || echo "false")
TFHE_RS_VERSION ?= 0.2.4

ZBC_DEVELOPMENT_PATH ?= $(WORKDIR)/zbc-development
ZBC_DEVELOPMENT_PATH_EXISTS := $(shell test -d $(ZBC_DEVELOPMENT_PATH)/.git && echo "true" || echo "false")
ZBC_DEVELOPMENT_VERSION ?= feature/delete-zkpok

ZBC_FHE_TOOL_PATH ?= $(WORKDIR)/zbc-fhe-tool
ZBC_FHE_TOOL_PATH_EXISTS := $(shell test -d $(ZBC_FHE_TOOL_PATH)/.git && echo "true" || echo "false")
ZBC_FHE_TOOL_VERSION ?= main

ZBC_SOLIDITY_PATH ?= $(WORKDIR)/zbc-solidity
ZBC_SOLIDITY_PATH_EXISTS := $(shell test -d $(ZBC_SOLIDITY_PATH)/.git && echo "true" || echo "false")
ZBC_SOLIDITY_VERSION ?= feature/new-output-mechanism

ETHERMINT_VERSION := $(shell ./scripts/get_module_version.sh go.mod zama.ai/ethermint)
GO_ETHEREUM_VERSION := $(shell ./scripts/get_module_version.sh go.mod zama.ai/go-ethereum)
UPDATE_GO_MOD = go.mod.updated

export GO111MODULE = on

# Default target executed when no arguments are given to make.
default_target: all

.PHONY: default_target

# process build tags

build_tags = netgo
ifeq ($(LEDGER_ENABLED),true)
  ifeq ($(OS),Windows_NT)
    GCCEXE = $(shell where gcc.exe 2> NUL)
    ifeq ($(GCCEXE),)
      $(error gcc.exe not installed for ledger support, please install or set LEDGER_ENABLED=false)
    else
      build_tags += ledger
    endif
  else
    UNAME_S = $(shell uname -s)
    ifeq ($(UNAME_S),OpenBSD)
      $(warning OpenBSD detected, disabling ledger support (https://github.com/cosmos/cosmos-sdk/issues/1988))
    else
      GCC = $(shell command -v gcc 2> /dev/null)
      ifeq ($(GCC),)
        $(error gcc not installed for ledger support, please install or set LEDGER_ENABLED=false)
      else
        build_tags += ledger
      endif
    endif
  endif
endif

ifeq (cleveldb,$(findstring cleveldb,$(COSMOS_BUILD_OPTIONS)))
  build_tags += gcc
endif
build_tags += $(BUILD_TAGS)
build_tags := $(strip $(build_tags))

whitespace :=
whitespace += $(whitespace)
comma := ,
build_tags_comma_sep := $(subst $(whitespace),$(comma),$(build_tags))

# process linker flags

ldflags = -X github.com/cosmos/cosmos-sdk/version.Name=evmos \
          -X github.com/cosmos/cosmos-sdk/version.AppName=$(EVMOS_BINARY) \
          -X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
          -X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT) \
          -X "github.com/cosmos/cosmos-sdk/version.BuildTags=$(build_tags_comma_sep)" \
          -X github.com/tendermint/tendermint/version.TMCoreSemVer=$(TMVERSION)

# DB backend selection
ifeq (cleveldb,$(findstring cleveldb,$(COSMOS_BUILD_OPTIONS)))
  ldflags += -X github.com/cosmos/cosmos-sdk/types.DBBackend=cleveldb
endif
ifeq (badgerdb,$(findstring badgerdb,$(COSMOS_BUILD_OPTIONS)))
  ldflags += -X github.com/cosmos/cosmos-sdk/types.DBBackend=badgerdb
endif
# handle rocksdb
ifeq (rocksdb,$(findstring rocksdb,$(COSMOS_BUILD_OPTIONS)))
  CGO_ENABLED=1
  BUILD_TAGS += rocksdb
  ldflags += -X github.com/cosmos/cosmos-sdk/types.DBBackend=rocksdb
endif
# handle boltdb
ifeq (boltdb,$(findstring boltdb,$(COSMOS_BUILD_OPTIONS)))
  BUILD_TAGS += boltdb
  ldflags += -X github.com/cosmos/cosmos-sdk/types.DBBackend=boltdb
endif

ifeq (,$(findstring nostrip,$(COSMOS_BUILD_OPTIONS)))
  ldflags += -w -s
endif
ldflags += $(LDFLAGS)
ldflags := $(strip $(ldflags))

BUILD_FLAGS := -tags "$(build_tags)" -ldflags '$(ldflags)'
# check for nostrip option
ifeq (,$(findstring nostrip,$(COSMOS_BUILD_OPTIONS)))
  BUILD_FLAGS += -trimpath
endif

# # The below include contains the tools and runsim targets.
# include contrib/devtools/Makefile

###############################################################################
###                                  Build                                  ###
###############################################################################

BUILD_TARGETS := build install

print-info:
	@echo 'GO_ETHEREUM_TAG: $(GO_ETHEREUM_VERSION) ---extracted from go.mod'
	@echo 'ETHERMINT_TAG: $(ETHERMINT_VERSION) ---extracted from go.mod'
	@bash scripts/get_repository_info.sh evmos ${CURDIR}
	@bash scripts/get_repository_info.sh tfhe-rs $(TFHE_RS_PATH)
	@bash scripts/get_repository_info.sh zbc-development $(ZBC_DEVELOPMENT_PATH)
	@bash scripts/get_repository_info.sh zbc-fhe-tool $(ZBC_FHE_TOOL_PATH)
	@bash scripts/get_repository_info.sh zbc-solidity $(ZBC_SOLIDITY_PATH)

build_c_api_tfhe:
	$(info build tfhe-rs C API)
	mkdir -p $(WORKDIR)/
	$(info tfhe-rs path $(TFHE_RS_PATH))
	$(info sudo_bin $(SUDO_BIN))
	cd $(TFHE_RS_PATH) && RUSTFLAGS="" make build_c_api
	ls $(TFHE_RS_PATH)/target/release
# In tfhe.go the library path is specified as following : #cgo LDFLAGS: -L/usr/lib/tfhe -ltfhe
# Magic to make this command work locally and in a docker where sudo is not defined
	$(SUDO) cp $(TFHE_RS_PATH)/target/release/tfhe.h /usr/include/
	$(SUDO) mkdir -p /usr/lib/tfhe
	$(SUDO) cp $(TFHE_RS_PATH)/target/release/libtfhe.* /usr/lib/tfhe/

build: 
	BUILD_ARGS=-o $(BUILDDIR)
	$(info build)
	
build-linux:
	$(info build-linux)
	GOOS=linux GOARCH=amd64 LEDGER_ENABLED=false $(MAKE) build

build-local: check-tfhe-rs go.sum build_c_api_tfhe $(BUILDDIR)/
	$(info build-local)
	go build $(BUILD_FLAGS) -o build $(BUILD_ARGS) ./...
	@echo 'evmosd binary is ready in build folder'


# $(BUILD_TARGETS): go.sum $(BUILDDIR)/
$(BUILD_TARGETS): go.sum build_c_api_tfhe $(BUILDDIR)/
	$(info BUILD_TARGETS)
	go $@ $(BUILD_FLAGS) -o build $(BUILD_ARGS) ./...

check-tfhe-rs: $(WORKDIR)/
	$(info check-tfhe-rs)
ifeq ($(TFHE_RS_EXISTS), true)
	@echo "Tfhe-rs exists in $(TFHE_RS_PATH)"
	@if [ ! -d $(WORKDIR)/tfhe-rs ]; then \
        echo 'tfhe-rs is not available in $(WORKDIR)'; \
        echo "TFHE_RS_PATH is set to a custom value"; \
        echo 'Copy local version located in $(TFHE_RS_PATH) into  $(WORKDIR)'; \
        cp -r $(TFHE_RS_PATH) $(WORKDIR)/; \
    else \
        echo 'tfhe-rs is already available in $(WORKDIR)'; \
    fi
else
	@echo "Tfhe-rs does not exist"
	echo "We clone it for you!"
	echo "If you want your own version please update TFHE_RS_PATH pointing to your tfhe-rs folder!"
	$(MAKE) clone_tfhe_rs
endif

check-zbc-solidity: $(WORKDIR)/
	$(info check-zbc-solidity)
ifeq ($(ZBC_SOLIDITY_PATH), true)
	@echo "zbc-solidity exists in $(ZBC_SOLIDITY_PATH)"
	@if [ ! -d $(WORKDIR)/zbc-solidity ]; then \
        echo 'zbc-solidity is not available in $(WORKDIR)'; \
        echo "ZBC_SOLIDITY_PATH is set to a custom value"; \
        echo 'Copy local version located in $(ZBC_SOLIDITY_PATH) into  $(WORKDIR)'; \
        cp -r $(ZBC_SOLIDITY_PATH) $(WORKDIR)/; \
    else \
        echo 'zbc-solidity is already available in $(WORKDIR)'; \
    fi
else
	@echo "zbc-solidity does not exist"
	echo "We clone it for you!"
	echo "If you want your own version please update ZBC_SOLIDITY_PATH pointing to your zbc-solidity folder!"
	$(MAKE) clone_zbc_solidty
endif

check-zbc-development: $(WORKDIR)/
	$(info check-zbc-development)
ifeq ($(ZBC_DEVELOPMENT_PATH), true)
	@echo "zbc-development exists in $(ZBC_DEVELOPMENT_PATH)"
	@if [ ! -d $(WORKDIR)/zbc-development ]; then \
        echo 'zbc-development is not available in $(WORKDIR)'; \
        echo "ZBC_DEVELOPMENT_PATH is set to a custom value"; \
        echo 'Copy local version located in $(ZBC_DEVELOPMENT_PATH) into  $(WORKDIR)'; \
        cp -r $(ZBC_DEVELOPMENT_PATH) $(WORKDIR)/; \
    else \
        echo 'zbc-development is already available in $(WORKDIR)'; \
    fi
else
	@echo "zbc-development does not exist"
	echo "We clone it for you!"
	echo "If you want your own version please update ZBC_DEVELOPMENT_PATH pointing to your zbc-development folder!"
	$(MAKE) clone_zbc_development
endif

check-zbc-fhe-tool: $(WORKDIR)/
	$(info check-zbc-fhe-tool)
ifeq ($(ZBC_FHE_TOOL_PATH), true)
	@echo "zbc-fhe-tool exists in $(ZBC_FHE_TOOL_PATH)"
	@if [ ! -d $(WORKDIR)/zbc-fhe_tool ]; then \
        echo 'zbc-fhe-tool is not available in $(WORKDIR)'; \
        echo "ZBC_FHE_TOOL_PATH is set to a custom value"; \
        echo 'Copy local version located in $(ZBC_FHE_TOOL_PATH) into  $(WORKDIR)'; \
        cp -r $(ZBC_FHE_TOOL_PATH) $(WORKDIR)/; \
    else \
        echo 'zbc-fhe-tool is already available in $(WORKDIR)'; \
    fi
else
	@echo "zbc-fhe-tool does not exist"
	echo "We clone it for you!"
	echo "If you want your own version please update ZBC_FHE_TOOL_PATH pointing to your zbc-fhe-tool folder!"
	$(MAKE) clone_zbc_fhe_tool
	$(MAKE) build_zbc_fhe_tool
endif



install-tfhe-rs: clone_tfhe_rs

build_zbc_fhe_tool:
	@ARCH_TO_BUIL_ZBC_FHE_TOOL=$$(cd work_dir/zbc-fhe-tool && ./scripts/get_arch.sh) && echo "Arch is $${ARCH_TO_BUIL_ZBC_FHE_TOOL}"
	@ARCH_TO_BUIL_ZBC_FHE_TOOL=$$(cd work_dir/zbc-fhe-tool && ./scripts/get_arch.sh) && cd work_dir/zbc-fhe-tool && cargo build --release --features tfhe/$${ARCH_TO_BUIL_ZBC_FHE_TOOL}

clone_zbc_development: $(WORKDIR)/
	$(info Cloning zbc-development version $(ZBC_DEVELOPMENT_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/zbc-development.git
	cd $(WORKDIR)/zbc-development && git checkout $(ZBC_DEVELOPMENT_VERSION)

clone_zbc_fhe_tool: $(WORKDIR)/
	$(info Cloning zbc-fhe-tool version $(ZBC_FHE_TOOL_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/zbc-fhe-tool.git
	cd $(WORKDIR)/zbc-fhe-tool && git checkout $(ZBC_FHE_TOOL_VERSION)
	
clone_zbc_solidty: $(WORKDIR)/
	$(info Cloning zbc-solidity version $(ZBC_SOLIDITY_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/zbc-solidity.git
	cd $(WORKDIR)/zbc-solidity && git checkout $(ZBC_SOLIDITY_VERSION)

clone_tfhe_rs: $(WORKDIR)/
	$(info Cloning tfhe-rs version $(TFHE_RS_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/tfhe-rs.git
	cd $(WORKDIR)/tfhe-rs && git checkout $(TFHE_RS_VERSION)

clone_go_ethereum: $(WORKDIR)/
	$(info Cloning Go-ethereum version $(GO_ETHEREUM_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/go-ethereum.git
	cd $(WORKDIR)/go-ethereum && git checkout $(GO_ETHEREUM_VERSION)

clone_ethermint: $(WORKDIR)/
	$(info Cloning Ethermint version $(ETHERMINT_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/ethermint.git
	cd $(WORKDIR)/ethermint && git checkout $(ETHERMINT_VERSION)

$(WORKDIR)/:
	$(info WORKDIR)
	mkdir -p $(WORKDIR)

check-all-test-repo: check-zbc-fhe-tool check-zbc-solidity check-zbc-development

prepare-build-docker: $(WORKDIR)/ clone_go_ethereum clone_ethermint	update-go-mod check-tfhe-rs


update-go-mod:
	@cp go.mod $(UPDATE_GO_MOD)
	@bash scripts/replace_go_mod.sh $(UPDATE_GO_MOD) go-ethereum
	@bash scripts/replace_go_mod.sh $(UPDATE_GO_MOD) ethermint


$(BUILDDIR)/:
	$(info BUILDDIR)
	mkdir -p $(BUILDDIR)

build-base-image:
	@echo 'Build base image with go and rust tools'
	@docker build . -f docker/Dockerfile.zbc.build -t zama-zbc-build

build-local-docker: build-base-image prepare-build-docker
	@docker compose  -f docker-compose/docker-compose.local.yml build evmosnodelocal
	
init_evmos_node:
	@echo 'init_evmos_node'
	@docker compose -f docker-compose/docker-compose.local.yml run evmosnodelocal bash /config/setup.sh
	@$(SUDO) chown -R $(USER):$(USER) running_node/

generate_fhe_keys:
	@echo 'generate_fhe_keys'
	# Generate fhe global keys and copy into volumes
	@bash $(ZBC_DEVELOPMENT_PATH)/prepare_volumes_from_fhe_tool.sh $(ZBC_FHE_TOOL_PATH)/target/release
	@bash $(ZBC_DEVELOPMENT_PATH)/prepare_demo_local.sh

run_evmos:
	@docker compose  -f docker-compose/docker-compose.local.yml -f docker-compose/docker-compose.local.override.yml  up --detach
	@echo 'sleep a bit to let the docker starts...'
	sleep 10

stop_evmos:
	@docker compose  -f docker-compose/docker-compose.local.yml down

run_e2e_test:
	# TODO replace hard-coded path to evmos 
	@cd $(ZBC_SOLIDITY_PATH) && ./prepare_fhe_keys_from_fhe_tool.sh ../../volumes/network-public-fhe-keys
	@cd $(ZBC_SOLIDITY_PATH) && ./run_local_test_from_evmos.sh mykey1
	@sleep 5

e2e-test-local: check-all-test-repo  init_evmos_node generate_fhe_keys run_evmos run_e2e_test stop_evmos

build-reproducible: go.sum
	$(DOCKER) rm latest-build || true
	$(DOCKER) run --volume=$(CURDIR):/sources:ro \
        --env TARGET_PLATFORMS='linux/amd64' \
        --env APP=evmosd \
        --env VERSION=$(VERSION) \
        --env COMMIT=$(COMMIT) \
        --env CGO_ENABLED=1 \
        --env LEDGER_ENABLED=$(LEDGER_ENABLED) \
        --name latest-build tendermintdev/rbuilder:latest
	$(DOCKER) cp -a latest-build:/home/builder/artifacts/ $(CURDIR)/


build-docker:
	# TODO replace with kaniko
	$(DOCKER) build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
	$(DOCKER) tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
	# docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:${COMMIT_HASH}
	# update old container
	$(DOCKER) rm evmos || true
	# create a new container from the latest image
	$(DOCKER) create --name evmos -t -i ${DOCKER_IMAGE}:latest evmos
	# move the binaries to the ./build directory
	mkdir -p ./build/
	$(DOCKER) cp evmos:/usr/bin/evmosd ./build/

push-docker: build-docker
	$(DOCKER) push ${DOCKER_IMAGE}:${DOCKER_TAG}
	$(DOCKER) push ${DOCKER_IMAGE}:latest

$(MOCKS_DIR):
	mkdir -p $(MOCKS_DIR)

distclean: clean tools-clean

clean-node-storage:
	@echo 'clean node storage'
	sudo rm -rf running_node

clean: clean-node-storage
	rm -rf \
    $(BUILDDIR)/ \
    artifacts/ \
    tmp-swagger-gen/ \
	$(WORKDIR)/ \
	build
	rm -f $(UPDATE_GO_MOD)
	

all: build

build-all: tools build lint test

.PHONY: distclean clean build-all

###############################################################################
###                          Tools & Dependencies                           ###
###############################################################################

TOOLS_DESTDIR  ?= $(GOPATH)/bin
STATIK         = $(TOOLS_DESTDIR)/statik
RUNSIM         = $(TOOLS_DESTDIR)/runsim

# Install the runsim binary with a temporary workaround of entering an outside
# directory as the "go get" command ignores the -mod option and will polute the
# go.{mod, sum} files.
#
# ref: https://github.com/golang/go/issues/30515
runsim: $(RUNSIM)
$(RUNSIM):
	@echo "Installing runsim..."
	@(cd /tmp && ${GO_MOD} go install github.com/cosmos/tools/cmd/runsim@master)

statik: $(STATIK)
$(STATIK):
	@echo "Installing statik..."
	@(cd /tmp && go install github.com/rakyll/statik@v0.1.6)

contract-tools:
ifeq (, $(shell which stringer))
	@echo "Installing stringer..."
	@go install golang.org/x/tools/cmd/stringer@latest
else
	@echo "stringer already installed; skipping..."
endif

ifeq (, $(shell which go-bindata))
	@echo "Installing go-bindata..."
	@go install github.com/kevinburke/go-bindata/go-bindata@latest
else
	@echo "go-bindata already installed; skipping..."
endif

ifeq (, $(shell which gencodec))
	@echo "Installing gencodec..."
	@go install github.com/fjl/gencodec@latest
else
	@echo "gencodec already installed; skipping..."
endif

ifeq (, $(shell which protoc-gen-go))
	@echo "Installing protoc-gen-go..."
	@go install github.com/fjl/gencodec@latest
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
else
	@echo "protoc-gen-go already installed; skipping..."
endif

ifeq (, $(shell which protoc-gen-go-grpc))
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
else
	@echo "protoc-gen-go-grpc already installed; skipping..."
endif

ifeq (, $(shell which solcjs))
	@echo "Installing solcjs..."
	@npm install -g solc@0.5.11
else
	@echo "solcjs already installed; skipping..."
endif

docs-tools:
ifeq (, $(shell which yarn))
	@echo "Installing yarn..."
	@npm install -g yarn
else
	@echo "yarn already installed; skipping..."
endif

tools: tools-stamp
tools-stamp: contract-tools docs-tools proto-tools statik runsim
	# Create dummy file to satisfy dependency and avoid
	# rebuilding when this Makefile target is hit twice
	# in a row.
	touch $@

tools-clean:
	rm -f $(RUNSIM)
	rm -f tools-stamp

docs-tools-stamp: docs-tools
	# Create dummy file to satisfy dependency and avoid
	# rebuilding when this Makefile target is hit twice
	# in a row.
	touch $@

.PHONY: runsim statik tools contract-tools docs-tools proto-tools  tools-stamp tools-clean docs-tools-stamp

go.sum: go.mod
	echo "Ensure dependencies have not been modified ..." >&2
	go mod verify
	go mod tidy

###############################################################################
###                              Documentation                              ###
###############################################################################

update-swagger-docs: statik
	$(BINDIR)/statik -src=client/docs/swagger-ui -dest=client/docs -f -m
	@if [ -n "$(git status --porcelain)" ]; then \
        echo "\033[91mSwagger docs are out of sync!!!\033[0m";\
        exit 1;\
    else \
        echo "\033[92mSwagger docs are in sync\033[0m";\
    fi
.PHONY: update-swagger-docs

godocs:
	@echo "--> Wait a few seconds and visit http://localhost:6060/pkg/github.com/evmos/evmos/types"
	godoc -http=:6060

# Start docs site at localhost:8080
docs-serve:
	@cd docs && \
	yarn && \
	yarn run serve

# Build the site into docs/.vuepress/dist
build-docs:
	@$(MAKE) docs-tools-stamp && \
	cd docs && \
	yarn && \
	yarn run build

# This builds a docs site for each branch/tag in `./docs/versions`
# and copies each site to a version prefixed path. The last entry inside
# the `versions` file will be the default root index.html.
build-docs-versioned:
	@$(MAKE) docs-tools-stamp && \
	cd docs && \
	while read -r branch path_prefix; do \
		(git checkout $${branch} && npm install && VUEPRESS_BASE="/$${path_prefix}/" npm run build) ; \
		mkdir -p ~/output/$${path_prefix} ; \
		cp -r .vuepress/dist/* ~/output/$${path_prefix}/ ; \
		cp ~/output/$${path_prefix}/index.html ~/output ; \
	done < versions ;

.PHONY: docs-serve build-docs build-docs-versioned

###############################################################################
###                           Tests & Simulation                            ###
###############################################################################

test: test-unit
test-all: test-unit test-race
PACKAGES_UNIT=$(shell go list ./...)
TEST_PACKAGES=./...
TEST_TARGETS := test-unit test-unit-cover test-race

# Test runs-specific rules. To add a new test target, just add
# a new rule, customise ARGS or TEST_PACKAGES ad libitum, and
# append the new rule to the TEST_TARGETS list.
test-unit: ARGS=-timeout=10m -race
test-unit: TEST_PACKAGES=$(PACKAGES_UNIT)

test-race: ARGS=-race
test-race: TEST_PACKAGES=$(PACKAGES_NOSIMULATION)
$(TEST_TARGETS): run-tests

test-unit-cover: ARGS=-timeout=10m -race -coverprofile=coverage.txt -covermode=atomic
test-unit-cover: TEST_PACKAGES=$(PACKAGES_UNIT)

run-tests:
ifneq (,$(shell which tparse 2>/dev/null))
	go test -mod=readonly -json $(ARGS) $(EXTRA_ARGS) $(TEST_PACKAGES) | tparse
else
	go test -mod=readonly $(ARGS)  $(EXTRA_ARGS) $(TEST_PACKAGES)
endif

test-import:
	@go test ./tests/importer -v --vet=off --run=TestImportBlocks --datadir tmp \
	--blockchain blockchain
	rm -rf tests/importer/tmp

test-rpc:
	./scripts/integration-test-all.sh -t "rpc" -q 1 -z 1 -s 2 -m "rpc" -r "true"

test-rpc-pending:
	./scripts/integration-test-all.sh -t "pending" -q 1 -z 1 -s 2 -m "pending" -r "true"

.PHONY: run-tests test test-all test-import test-rpc $(TEST_TARGETS)

test-sim-nondeterminism:
	@echo "Running non-determinism test..."
	@go test -mod=readonly $(SIMAPP) -run TestAppStateDeterminism -Enabled=true \
		-NumBlocks=100 -BlockSize=200 -Commit=true -Period=0 -v -timeout 24h

test-sim-custom-genesis-fast:
	@echo "Running custom genesis simulation..."
	@echo "By default, ${HOME}/.$(EVMOS_DIR)/config/genesis.json will be used."
	@go test -mod=readonly $(SIMAPP) -run TestFullAppSimulation -Genesis=${HOME}/.$(EVMOS_DIR)/config/genesis.json \
		-Enabled=true -NumBlocks=100 -BlockSize=200 -Commit=true -Seed=99 -Period=5 -v -timeout 24h

test-sim-import-export: runsim
	@echo "Running application import/export simulation. This may take several minutes..."
	@$(BINDIR)/runsim -Jobs=4 -SimAppPkg=$(SIMAPP) -ExitOnFail 50 5 TestAppImportExport

test-sim-after-import: runsim
	@echo "Running application simulation-after-import. This may take several minutes..."
	@$(BINDIR)/runsim -Jobs=4 -SimAppPkg=$(SIMAPP) -ExitOnFail 50 5 TestAppSimulationAfterImport

test-sim-custom-genesis-multi-seed: runsim
	@echo "Running multi-seed custom genesis simulation..."
	@echo "By default, ${HOME}/.$(EVMOS_DIR)/config/genesis.json will be used."
	@$(BINDIR)/runsim -Genesis=${HOME}/.$(EVMOS_DIR)/config/genesis.json -SimAppPkg=$(SIMAPP) -ExitOnFail 400 5 TestFullAppSimulation

test-sim-multi-seed-long: runsim
	@echo "Running long multi-seed application simulation. This may take awhile!"
	@$(BINDIR)/runsim -Jobs=4 -SimAppPkg=$(SIMAPP) -ExitOnFail 500 50 TestFullAppSimulation

test-sim-multi-seed-short: runsim
	@echo "Running short multi-seed application simulation. This may take awhile!"
	@$(BINDIR)/runsim -Jobs=4 -SimAppPkg=$(SIMAPP) -ExitOnFail 50 10 TestFullAppSimulation

test-sim-benchmark-invariants:
	@echo "Running simulation invariant benchmarks..."
	@go test -mod=readonly $(SIMAPP) -benchmem -bench=BenchmarkInvariants -run=^$ \
	-Enabled=true -NumBlocks=1000 -BlockSize=200 \
	-Period=1 -Commit=true -Seed=57 -v -timeout 24h

.PHONY: \
test-sim-nondeterminism \
test-sim-custom-genesis-fast \
test-sim-import-export \
test-sim-after-import \
test-sim-custom-genesis-multi-seed \
test-sim-multi-seed-short \
test-sim-multi-seed-long \
test-sim-benchmark-invariants

benchmark:
	@go test -mod=readonly -bench=. $(PACKAGES_NOSIMULATION)
.PHONY: benchmark

###############################################################################
###                                Linting                                  ###
###############################################################################

lint:
	golangci-lint run --out-format=tab
	solhint contracts/**/*.sol

lint-contracts:
	@cd contracts && \
	npm i && \
	npm run lint

lint-fix:
	golangci-lint run --fix --out-format=tab --issues-exit-code=0

lint-fix-contracts:
	@cd contracts && \
	npm i && \
	npm run lint-fix
	solhint --fix contracts/**/*.sol

.PHONY: lint lint-fix

format:
	find . -name '*.go' -type f -not -path "./vendor*" -not -path "*.git*" -not -path "./client/docs/statik/statik.go" -not -name '*.pb.go' | xargs gofmt -w -s
	find . -name '*.go' -type f -not -path "./vendor*" -not -path "*.git*" -not -path "./client/docs/statik/statik.go" -not -name '*.pb.go' | xargs misspell -w
	find . -name '*.go' -type f -not -path "./vendor*" -not -path "*.git*" -not -path "./client/docs/statik/statik.go" -not -name '*.pb.go' | xargs goimports -w -local github.com/evmos/evmos
.PHONY: format

###############################################################################
###                                Protobuf                                 ###
###############################################################################

containerProtoVer=v0.2
containerProtoImage=tendermintdev/sdk-proto-gen:$(containerProtoVer)
containerProtoGen=cosmos-sdk-proto-gen-$(containerProtoVer)
containerProtoGenSwagger=cosmos-sdk-proto-gen-swagger-$(containerProtoVer)
containerProtoFmt=cosmos-sdk-proto-fmt-$(containerProtoVer)

proto-all: proto-format proto-lint proto-gen

proto-gen:
	@echo "Generating Protobuf files"
	$(DOCKER) run --rm -v $(CURDIR):/workspace --workdir /workspace tendermintdev/sdk-proto-gen sh ./scripts/protocgen.sh

proto-format:
	@echo "Formatting Protobuf files"
	find ./ -not -path "./third_party/*" -name *.proto -exec clang-format -i {} \;

proto-lint:
	@$(DOCKER_BUF) lint --error-format=json

proto-check-breaking:
	@$(DOCKER_BUF) breaking --against $(HTTPS_GIT)#branch=main


TM_URL              = https://raw.githubusercontent.com/tendermint/tendermint/v0.34.15/proto/tendermint
GOGO_PROTO_URL      = https://raw.githubusercontent.com/regen-network/protobuf/cosmos
COSMOS_SDK_URL      = https://raw.githubusercontent.com/cosmos/cosmos-sdk/v0.45.1
ETHERMINT_URL      	= https://raw.githubusercontent.com/tharsis/ethermint/v0.10.0
IBC_GO_URL      		= https://raw.githubusercontent.com/cosmos/ibc-go/v3.0.0-rc0
COSMOS_PROTO_URL    = https://raw.githubusercontent.com/regen-network/cosmos-proto/master

TM_CRYPTO_TYPES     = third_party/proto/tendermint/crypto
TM_ABCI_TYPES       = third_party/proto/tendermint/abci
TM_TYPES            = third_party/proto/tendermint/types

GOGO_PROTO_TYPES    = third_party/proto/gogoproto

COSMOS_PROTO_TYPES  = third_party/proto/cosmos_proto

proto-update-deps:
	@mkdir -p $(GOGO_PROTO_TYPES)
	@curl -sSL $(GOGO_PROTO_URL)/gogoproto/gogo.proto > $(GOGO_PROTO_TYPES)/gogo.proto

	@mkdir -p $(COSMOS_PROTO_TYPES)
	@curl -sSL $(COSMOS_PROTO_URL)/cosmos.proto > $(COSMOS_PROTO_TYPES)/cosmos.proto

## Importing of tendermint protobuf definitions currently requires the
## use of `sed` in order to build properly with cosmos-sdk's proto file layout
## (which is the standard Buf.build FILE_LAYOUT)
## Issue link: https://github.com/tendermint/tendermint/issues/5021
	@mkdir -p $(TM_ABCI_TYPES)
	@curl -sSL $(TM_URL)/abci/types.proto > $(TM_ABCI_TYPES)/types.proto

	@mkdir -p $(TM_TYPES)
	@curl -sSL $(TM_URL)/types/types.proto > $(TM_TYPES)/types.proto

	@mkdir -p $(TM_CRYPTO_TYPES)
	@curl -sSL $(TM_URL)/crypto/proof.proto > $(TM_CRYPTO_TYPES)/proof.proto
	@curl -sSL $(TM_URL)/crypto/keys.proto > $(TM_CRYPTO_TYPES)/keys.proto



.PHONY: proto-all proto-gen proto-gen-any proto-swagger-gen proto-format proto-lint proto-check-breaking proto-update-deps

###############################################################################
###                                Localnet                                 ###
###############################################################################

# Build image for a local testnet
localnet-build:
	@$(MAKE) -C networks/local

# Start a 4-node testnet locally
localnet-start: localnet-stop localnet-build
	@if ! [ -f build/node0/$(EVMOS_BINARY)/config/genesis.json ]; then docker run --rm -v $(CURDIR)/build:/evmos:Z evmos/node "./evmosd testnet init-files --v 4 -o /evmos --keyring-backend=test --starting-ip-address 192.167.10.2"; fi
	docker-compose up -d

# Stop testnet
localnet-stop:
	docker-compose down

# Clean testnet
localnet-clean:
	docker-compose down
	sudo rm -rf build/*

 # Reset testnet
localnet-unsafe-reset:
	docker-compose down
ifeq ($(OS),Windows_NT)
	@docker run --rm -v $(CURDIR)\build\node0\evmosd:/evmos\Z evmos/node "./evmosd tendermint unsafe-reset-all --home=/evmos"
	@docker run --rm -v $(CURDIR)\build\node1\evmosd:/evmos\Z evmos/node "./evmosd tendermint unsafe-reset-all --home=/evmos"
	@docker run --rm -v $(CURDIR)\build\node2\evmosd:/evmos\Z evmos/node "./evmosd tendermint unsafe-reset-all --home=/evmos"
	@docker run --rm -v $(CURDIR)\build\node3\evmosd:/evmos\Z evmos/node "./evmosd tendermint unsafe-reset-all --home=/evmos"
else
	@docker run --rm -v $(CURDIR)/build/node0/evmosd:/evmos:Z evmos/node "./evmosd tendermint unsafe-reset-all --home=/evmos"
	@docker run --rm -v $(CURDIR)/build/node1/evmosd:/evmos:Z evmos/node "./evmosd tendermint unsafe-reset-all --home=/evmos"
	@docker run --rm -v $(CURDIR)/build/node2/evmosd:/evmos:Z evmos/node "./evmosd tendermint unsafe-reset-all --home=/evmos"
	@docker run --rm -v $(CURDIR)/build/node3/evmosd:/evmos:Z evmos/node "./evmosd tendermint unsafe-reset-all --home=/evmos"
endif

# Clean testnet
localnet-show-logstream:
	docker-compose logs --tail=1000 -f

.PHONY: localnet-build localnet-start localnet-stop

###############################################################################
###                                Releasing                                ###
###############################################################################

PACKAGE_NAME:=github.com/evmos/evmos
GOLANG_CROSS_VERSION  = v1.18
GOPATH ?= '$(HOME)/go'
release-dry-run:
	docker run \
		--rm \
		--privileged \
		-e CGO_ENABLED=1 \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v `pwd`:/go/src/$(PACKAGE_NAME) \
		-v ${GOPATH}/pkg:/go/pkg \
		-w /go/src/$(PACKAGE_NAME) \
		ghcr.io/goreleaser/goreleaser-cross:${GOLANG_CROSS_VERSION} \
		--rm-dist --skip-validate --skip-publish --snapshot

release:
	@if [ ! -f ".release-env" ]; then \
		echo "\033[91m.release-env is required for release\033[0m";\
		exit 1;\
	fi
	docker run \
		--rm \
		--privileged \
		-e CGO_ENABLED=1 \
		--env-file .release-env \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v `pwd`:/go/src/$(PACKAGE_NAME) \
		-w /go/src/$(PACKAGE_NAME) \
		ghcr.io/goreleaser/goreleaser-cross:${GOLANG_CROSS_VERSION} \
		release --rm-dist --skip-validate

.PHONY: release-dry-run release

###############################################################################
###                                Releasing                                ###
###############################################################################

PACKAGE_NAME:=github.com/evmos/evmos
GOLANG_CROSS_VERSION  = v1.18
GOPATH ?= '$(HOME)/go'
release-dry-run:
	docker run \
		--rm \
		--privileged \
		-e CGO_ENABLED=1 \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v `pwd`:/go/src/$(PACKAGE_NAME) \
		-v ${GOPATH}/pkg:/go/pkg \
		-w /go/src/$(PACKAGE_NAME) \
		ghcr.io/goreleaser/goreleaser-cross:${GOLANG_CROSS_VERSION} \
		--rm-dist --skip-validate --skip-publish --snapshot

release:
	@if [ ! -f ".release-env" ]; then \
		echo "\033[91m.release-env is required for release\033[0m";\
		exit 1;\
	fi
	docker run \
		--rm \
		--privileged \
		-e CGO_ENABLED=1 \
		--env-file .release-env \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v `pwd`:/go/src/$(PACKAGE_NAME) \
		-w /go/src/$(PACKAGE_NAME) \
		ghcr.io/goreleaser/goreleaser-cross:${GOLANG_CROSS_VERSION} \
		release --rm-dist --skip-validate

.PHONY: release-dry-run release

###############################################################################
###                        Compile Solidity Contracts                       ###
###############################################################################

CONTRACTS_DIR := contracts
COMPILED_DIR := contracts/compiled_contracts
TMP := tmp
TMP_CONTRACTS := $(TMP).contracts
TMP_COMPILED := $(TMP)/compiled.json
TMP_JSON := $(TMP)/tmp.json

# Compile and format solidity contracts for the erc20 module. Also install
# openzeppeling as the contracts are build on top of openzeppelin templates.
contracts-compile: contracts-clean openzeppelin create-contracts-json

# Install openzeppelin solidity contracts
openzeppelin:
	@echo "Importing openzeppelin contracts..."
	@cd $(CONTRACTS_DIR)
	@npm install
	@cd ../../../../
	@mv node_modules $(TMP)
	@mv package-lock.json $(TMP)
	@mv $(TMP)/@openzeppelin $(CONTRACTS_DIR)

# Clean tmp files
contracts-clean:
	@rm -rf tmp
	@rm -rf node_modules
	@rm -rf $(COMPILED_DIR)
	@rm -rf $(CONTRACTS_DIR)/@openzeppelin

# Compile, filter out and format contracts into the following format.
# {
# 	"abi": "[{\"inpu 			# JSON string
# 	"bin": "60806040
# 	"contractName": 			# filename without .sol
# }
create-contracts-json:
	@for c in $(shell ls $(CONTRACTS_DIR) | grep '\.sol' | sed 's/.sol//g'); do \
		command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed."; exit 1; } ;\
		command -v solc > /dev/null 2>&1 || { echo >&2 "solc not installed."; exit 1; } ;\
		mkdir -p $(COMPILED_DIR) ;\
		mkdir -p $(TMP) ;\
		echo "\nCompiling solidity contract $${c}..." ;\
		solc --combined-json abi,bin $(CONTRACTS_DIR)/$${c}.sol > $(TMP_COMPILED) ;\
		echo "Formatting JSON..." ;\
		get_contract=$$(jq '.contracts["$(CONTRACTS_DIR)/'$$c'.sol:'$$c'"]' $(TMP_COMPILED)) ;\
		add_contract_name=$$(echo $$get_contract | jq '. + { "contractName": "'$$c'" }') ;\
		echo $$add_contract_name | jq > $(TMP_JSON) ;\
		abi_string=$$(echo $$add_contract_name | jq -cr '.abi') ;\
		echo $$add_contract_name | jq --arg newval "$$abi_string" '.abi = $$newval' > $(TMP_JSON) ;\
		mv $(TMP_JSON) $(COMPILED_DIR)/$${c}.json ;\
	done
	@rm -rf tmp
