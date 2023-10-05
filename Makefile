#!/usr/bin/make -f

include .env

PACKAGES_NOSIMULATION=$(shell go list ./... | grep -v '/simulation')
PACKAGES_SIMTEST=$(shell go list ./... | grep '/simulation')
DIFF_TAG=$(shell git rev-list --tags="v*" --max-count=1 --not $(shell git rev-list --tags="v*" "HEAD..origin"))
DEFAULT_TAG=$(shell git rev-list --tags="v*" --max-count=1)
VERSION ?= $(shell echo $(shell git describe --tags $(or $(DIFF_TAG), $(DEFAULT_TAG))) | sed 's/^v//')
TMVERSION := $(shell go list -m github.com/tendermint/tendermint | sed 's:.* ::')
COMMIT := $(shell git log -1 --format='%H')
HOST_ARCH := $(shell uname -m)
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
TFHE_RS_VERSION ?= 0.3.1

# If false, fhevm-tfhe-cli is cloned, built (version is FHEVM_TFHE_CLI_VERSION)
USE_DOCKER_FOR_FHE_KEYS ?= true
FHEVM_TFHE_CLI_PATH ?= $(WORKDIR)/fhevm-tfhe-cli
FHEVM_TFHE_CLI_PATH_EXISTS := $(shell test -d $(FHEVM_TFHE_CLI_PATH)/.git && echo "true" || echo "false")
FHEVM_TFHE_CLI_VERSION ?= v0.2.1

FHEVM_DECRYPTIONS_DB_PATH ?= $(WORKDIR)/fhevm-decryptions-db
FHEVM_DECRYPTIONS_DB_PATH_EXISTS := $(shell test -d $(FHEVM_DECRYPTIONS_DB_PATH)/.git && echo "true" || echo "false")
FHEVM_DECRYPTIONS_DB_VERSION ?= v0.2.0

FHEVM_SOLIDITY_PATH ?= $(WORKDIR)/fhevm-solidity
FHEVM_SOLIDITY_PATH_EXISTS := $(shell test -d $(FHEVM_SOLIDITY_PATH)/.git && echo "true" || echo "false")
FHEVM_SOLIDITY_VERSION ?= v0.1.14
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
	@echo 'TFHE_RS_VERSION: $(TFHE_RS_VERSION) ---extracted from Makefile'
	@echo 'FHEVM_TFHE_CLI_VERSION: $(FHEVM_TFHE_CLI_VERSION) ---extracted from Makefile'
	@echo 'FHEVM_DECRYPTIONS_DB_VERSION: $(FHEVM_DECRYPTIONS_DB_VERSION) ---extracted from Makefile'
	@echo 'FHEVM_SOLIDITY_VERSION: $(FHEVM_SOLIDITY_VERSION) ---extracted from Makefile'
	@bash scripts/get_repository_info.sh evmos ${CURDIR}
	@bash scripts/get_repository_info.sh tfhe-rs $(TFHE_RS_PATH)
	@bash scripts/get_repository_info.sh fhevm-tfhe-cli $(FHEVM_TFHE_CLI_PATH)
	@bash scripts/get_repository_info.sh fhevm-solidity $(FHEVM_SOLIDITY_PATH)

copy_c_api_to_system_path:
# In tfhe.go the library path is specified as following : #cgo LDFLAGS: -L/usr/lib/ -ltfhe
	$(SUDO) cp $(TFHE_RS_PATH)/target/release/tfhe.h /usr/include/
	$(SUDO) cp $(TFHE_RS_PATH)/target/release/libtfhe.* /usr/lib/

build_c_api_tfhe: check-tfhe-rs
	$(info build tfhe-rs C API)
	mkdir -p $(WORKDIR)/
	$(info tfhe-rs path $(TFHE_RS_PATH))
	$(info sudo_bin $(SUDO_BIN))
	cd $(TFHE_RS_PATH) && RUSTFLAGS="" make build_c_api_experimental_deterministic_fft
	ls $(TFHE_RS_PATH)/target/release


build-linux:
	$(info build-linux)
	GOOS=linux GOARCH=amd64 LEDGER_ENABLED=false $(MAKE) build

$(BUILD_TARGETS): go.sum $(BUILDDIR)/
	$(info build)
	go install $(BUILD_FLAGS) $(BUILD_ARGS) ./...
	@echo 'evmosd binary is ready in $(HOME)/go/bin'

build-local:   go.sum build_c_api_tfhe copy_c_api_to_system_path $(BUILDDIR)/
	$(info build-local for docker build)
	go build $(BUILD_FLAGS) -o build $(BUILD_ARGS) ./...
	@echo 'evmosd binary is ready in build folder'



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

check-fhevm-solidity: $(WORKDIR)/
	$(info check-fhevm-solidity)
ifeq ($(FHEVM_SOLIDITY_PATH_EXISTS), true)
	@echo "fhevm-solidity exists in $(FHEVM_SOLIDITY_PATH)"
	@if [ ! -d $(WORKDIR)/fhevm-solidity ]; then \
        echo 'fhevm-solidity is not available in $(WORKDIR)'; \
        echo "FHEVM_SOLIDITY_PATH is set to a custom value"; \
    else \
        echo 'fhevm-solidity is already available in $(WORKDIR)'; \
    fi
else
	@echo "fhevm-solidity does not exist"
	echo "We clone it for you!"
	echo "If you want your own version please update FHEVM_SOLIDITY_PATH pointing to your fhevm-solidity folder!"
	$(MAKE) clone_fhevm_solidity
endif

check-fhevm-decryptions-db: $(WORKDIR)/
	$(info check-fhevm-decryptions-db)
ifeq ($(FHEVM_DECRYPTIONS_DB_PATH_EXISTS), true)
	@echo "fhevm-decryptions-db exists in $(FHEVM_DECRYPTIONS_DB_PATH)"
	@if [ ! -d $(WORKDIR)/fhevm-decryptions-db ]; then \
        echo 'fhevm-decryptions-db is not available in $(WORKDIR)'; \
        echo "FHEVM_DECRYPTIONS_DB_PATH is set to a custom value"; \
    else \
        echo 'fhevm-decryptions-db is already available in $(WORKDIR)'; \
    fi
else
	@echo "fhevm-decryptions-db does not exist"
	echo "We clone it for you!"
	echo "If you want your own version please update FHEVM_DECRYPTIONS_DB_PATH pointing to your fhevm-decryptions-db folder!"
	$(MAKE) clone_fhevm_decryptions_db
endif


check-fhevm-tfhe-cli: $(WORKDIR)/
	$(info check-fhevm-tfhe-cli)
	@echo "FHEVM_TFHE_CLI_PATH_EXISTS  $(FHEVM_TFHE_CLI_PATH_EXISTS)"
ifeq ($(FHEVM_TFHE_CLI_PATH_EXISTS), true)
	@echo "fhevm-tfhe-cli exists in $(FHEVM_TFHE_CLI_PATH)"
	@if [ ! -d $(WORKDIR)/fhevm-tfhe-cli ]; then \
        echo 'fhevm-tfhe-cli is not available in $(WORKDIR)'; \
        echo "FHEVM_TFHE_CLI_PATH is set to a custom value"; \
    else \
        echo 'fhevm-tfhe-cli is already available in $(WORKDIR)'; \
    fi
else
	@echo "fhevm-tfhe-cli does not exist in $(FHEVM_TFHE_CLI_PATH)"
	echo "We clone it for you!"
	echo "If you want your own version please update FHEVM_TFHE_CLI_PATH pointing to your fhevm-tfhe-cli folder!"
	$(MAKE) clone_fhevm_tfhe_cli
endif
	echo 'Call build zbc fhe'
	$(MAKE) build_fhevm_tfhe_cli



install-tfhe-rs: clone_tfhe_rs

build_fhevm_tfhe_cli:
ifeq ($(HOST_ARCH), x86_64)
	@echo 'Arch is x86'
	@ARCH_TO_BUIL_FHEVM_TFHE_CLI=$$(cd $(FHEVM_TFHE_CLI_PATH) && ./scripts/get_arch.sh) && cd $(FHEVM_TFHE_CLI_PATH) && cargo build --release --features tfhe/$${ARCH_TO_BUIL_FHEVM_TFHE_CLI}
else
	@echo 'Arch is not x86'
	@ARCH_TO_BUIL_FHEVM_TFHE_CLI=$$(cd $(FHEVM_TFHE_CLI_PATH) && ./scripts/get_arch.sh) && cd $(FHEVM_TFHE_CLI_PATH) && cargo +nightly build --release --features tfhe/$${ARCH_TO_BUIL_FHEVM_TFHE_CLI}
endif	

clone_fhevm_tfhe_cli: $(WORKDIR)/
	$(info Cloning fhevm-tfhe-cli version $(FHEVM_TFHE_CLI_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/fhevm-tfhe-cli.git
	cd $(WORKDIR)/fhevm-tfhe-cli && git checkout $(FHEVM_TFHE_CLI_VERSION)
	
clone_fhevm_solidity: $(WORKDIR)/
	$(info Cloning fhevm-solidity version $(FHEVM_SOLIDITY_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/fhevm-solidity.git
	cd $(WORKDIR)/fhevm-solidity && git checkout $(FHEVM_SOLIDITY_VERSION)

clone_tfhe_rs: $(WORKDIR)/
	$(info Cloning tfhe-rs version $(TFHE_RS_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/tfhe-rs.git
	cd $(WORKDIR)/tfhe-rs && git checkout $(TFHE_RS_VERSION)

clone_fhevm_decryptions_db: $(WORKDIR)/
	$(info Cloning fhevm-decryptions-db version $(FHEVM_DECRYPTIONS_DB_VERSION))
	cd $(WORKDIR) && git clone git@github.com:zama-ai/fhevm-decryptions-db.git
	cd $(WORKDIR)/fhevm-decryptions-db && git checkout $(FHEVM_DECRYPTIONS_DB_VERSION)

clone_go_ethereum: $(WORKDIR)/
	$(info Cloning Go-ethereum version $(GO_ETHEREUM_VERSION))
	@if [ -d "$(WORKDIR)/go-ethereum" ] && [ "$(ls -A $(WORKDIR)/go-ethereum)" ]; then \
    	echo "$(WORKDIR)/go-ethereum already exists and is not empty. Skipping git clone."; \
	else \
		cd $(WORKDIR) && git clone git@github.com:zama-ai/go-ethereum.git; \
		cd $(WORKDIR)/go-ethereum && git checkout $(GO_ETHEREUM_VERSION); \
	fi
	

clone_ethermint: $(WORKDIR)/
	$(info Cloning Ethermint version $(ETHERMINT_VERSION))
	@if [ -d "$(WORKDIR)/ethermint" ] && [ "$(ls -A $(WORKDIR)/ethermint)" ]; then \
	echo "$(WORKDIR)/ethermint already exists and is not empty. Skipping git clone."; \
	else \
		cd $(WORKDIR) && git clone git@github.com:zama-ai/ethermint.git; \
		cd $(WORKDIR)/ethermint && git checkout $(ETHERMINT_VERSION); \
	fi

$(WORKDIR)/:
	$(info WORKDIR)
	mkdir -p $(WORKDIR)

check-all-test-repo: check-fhevm-solidity

update-go-mod:
	@cp go.mod $(UPDATE_GO_MOD)
	@bash scripts/replace_go_mod.sh $(UPDATE_GO_MOD) go-ethereum
	@bash scripts/replace_go_mod.sh $(UPDATE_GO_MOD) ethermint


$(BUILDDIR)/:
	$(info BUILDDIR)
	mkdir -p $(BUILDDIR)

build-base-image:
	@echo 'Build base image with go and rust tools'
	@docker build . -f docker/Dockerfile.zbc.build -t zama-zbc-build:latest


build-local-docker:
ifeq ($(GITHUB_ACTIONS),true)
	$(info Running in a GitHub Actions workflow)
else
	$(info Not running in a GitHub Actions workflow)
	@$(MAKE) clone_go_ethereum
	@$(MAKE) clone_ethermint
endif
	$(MAKE) update-go-mod
	$(MAKE) check-tfhe-rs
	@docker compose  -f docker-compose/docker-compose.local.yml build evmosnodelocal
	
# Specific build for publish_evmos_node workflow	
prepare-docker-publish:
	$(MAKE) update-go-mod
	$(MAKE) check-tfhe-rs

build-docker:
ifeq ($(LOCAL_BUILD),true)
	$(info LOCAL_BUILD is set, build from sources)
	@$(MAKE) build-local-docker
else
	$(info LOCAL_BUILD is not set, use docker registry for docker images)
	@$(MAKE) build-from-registry
endif

	

build-from-registry:
	echo 'Nothing to do'
	

generate_fhe_keys:
ifeq ($(USE_DOCKER_FOR_FHE_KEYS),true)
	$(info USE_DOCKER_FOR_FHE_KEYS is set, use docker)
	@bash ./scripts/prepare_volumes_from_fhe_tool_docker.sh $(FHEVM_TFHE_CLI_VERSION)
else
	$(info USE_DOCKER_FOR_FHE_KEYS is not set, build from sources)
	@$(MAKE) check-fhevm-tfhe-cli
	@bash ./scripts/prepare_volumes_from_fhe_tool.sh $(FHEVM_TFHE_CLI_PATH)/target/release
endif


run_evmos:
ifeq ($(LOCAL_BUILD),true)
	$(info LOCAL_BUILD is set, run locally built docker images)
	@docker compose  -f docker-compose/docker-compose.local.yml -f docker-compose/docker-compose.local.override.yml  up --detach
else
	$(info LOCAL_BUILD is not set, run docker images from docker registry)
	@docker compose  -f docker-compose/docker-compose.validator.yml -f docker-compose/docker-compose.validator.override.yml  up --detach
endif
	@echo 'sleep a little to let the docker start up'
	sleep 10

stop_evmos:
ifeq ($(LOCAL_BUILD),true)
	$(info LOCAL_BUILD is set, run locally built docker images)
	@docker compose  -f docker-compose/docker-compose.local.yml down
else
	$(info LOCAL_BUILD is not set, run docker images from docker registry)
	@docker compose  -f docker-compose/docker-compose.validator.yml down
endif

run_e2e_test:
	@cd $(FHEVM_SOLIDITY_PATH) && ci/scripts/prepare_fhe_keys_for_e2e_test.sh $(CURDIR)/volumes/network-public-fhe-keys
	@cd $(FHEVM_SOLIDITY_PATH) && npm ci
## Copy the run_tests.sh script directly in fhevm-solidity for the nxt version
	@cp ./scripts/run_tests.sh $(FHEVM_SOLIDITY_PATH)/ci/scripts/
	@cd $(FHEVM_SOLIDITY_PATH) && ci/scripts/run_tests.sh
	@sleep 5


change_running_node_owner:
ifeq ($(GITHUB_ACTIONS),true)
	$(info Running e2e-test-local in a GitHub Actions workflow)
	sudo chown -R runner:docker running_node/
else
	$(info Not running e2e-test-local in a GitHub Actions workflow)
	@$(SUDO) chown -R $(USER): running_node/
endif


e2e-test-local: 
	$(MAKE) init-evmos-node-local
	$(MAKE) run_evmos
	$(MAKE) run_e2e_test
	$(MAKE) stop_evmos


e2e-test-from-registry:
	$(MAKE) init-evmos-node-from-registry
	$(MAKE) run_evmos
	$(MAKE) run_e2e_test
	$(MAKE) stop_evmos


e2e-test:
	@$(MAKE) check-all-test-repo
ifeq ($(LOCAL_BUILD),true)
	$(info LOCAL_BUILD is set, run e2e test from locally built docker images)
	@$(MAKE) e2e-test-local
else
	$(info LOCAL_BUILD is not set, use docker registry for docker images)
	@$(MAKE) e2e-test-from-registry
endif

init-evmos-node-local:
	@docker compose -f docker-compose/docker-compose.local.yml run evmosnodelocal bash /config/setup.sh
	$(MAKE) change_running_node_owner
	$(MAKE) generate_fhe_keys
	@bash ./scripts/prepare_demo_local.sh

init-evmos-node-from-registry:
	mkdir -p node/evmos
	cp private.ed25519 node/evmos
	cp public.ed25519 node/evmos
	@docker compose -f docker-compose/docker-compose.validator.yml run validator bash /config/setup.sh
	$(MAKE) change_running_node_owner
	$(MAKE) generate_fhe_keys
	bash ./scripts/prepare_validator_ci.sh

init-evmos-node:
	@$(MAKE) check-all-test-repo
ifeq ($(LOCAL_BUILD),true)
	$(info LOCAL_BUILD is set, run e2e test from locally built docker images)
	@$(MAKE) init-evmos-node-local
else
	$(info LOCAL_BUILD is not set, use docker registry for docker images)
	@$(MAKE) init-evmos-node-from-registry
endif

clean-node-storage:
	@echo 'clean node storage'
	sudo rm -rf running_node

clean: clean-node-storage
	$(MAKE) stop_evmos
	rm -rf \
    $(BUILDDIR)/ \
    artifacts/ \
    tmp-swagger-gen/ \
	$(WORKDIR)/ \
	build
	rm -f $(UPDATE_GO_MOD)
	
clean-local-evmos:
	rm -r $(HOME)/.evmosd/config
	rm -r $(HOME)/.evmosd/keyring-test/
	rm -r $(HOME)/.evmosd/data/

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

