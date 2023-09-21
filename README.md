<!--
parent:
  order: false
-->

<div align="center">
  <h1> Evmos </h1>
</div>

<div align="center">
  <a href="https://github.com/evmos/evmos/releases/latest">
    <img alt="Version" src="https://img.shields.io/github/tag/tharsis/evmos.svg" />
  </a>
  <a href="https://github.com/evmos/evmos/blob/main/LICENSE">
    <img alt="License: Apache-2.0" src="https://img.shields.io/github/license/tharsis/evmos.svg" />
  </a>
  <a href="https://pkg.go.dev/github.com/evmos/evmos">
    <img alt="GoDoc" src="https://godoc.org/github.com/evmos/evmos?status.svg" />
  </a>
  <a href="https://goreportcard.com/report/github.com/evmos/evmos">
    <img alt="Go report card" src="https://goreportcard.com/badge/github.com/evmos/evmos"/>
  </a>
  <a href="https://bestpractices.coreinfrastructure.org/projects/5018">
    <img alt="Lines of code" src="https://img.shields.io/tokei/lines/github/tharsis/evmos">
  </a>
</div>
<div align="center">
  <a href="https://discord.gg/evmos">
    <img alt="Discord" src="https://img.shields.io/discord/809048090249134080.svg" />
  </a>
  <a href="https://github.com/evmos/evmos/actions?query=branch%3Amain+workflow%3ALint">
    <img alt="Lint Status" src="https://github.com/evmos/evmos/actions/workflows/lint.yml/badge.svg?branch=main" />
  </a>
  <a href="https://codecov.io/gh/tharsis/evmos">
    <img alt="Code Coverage" src="https://codecov.io/gh/tharsis/evmos/branch/main/graph/badge.svg" />
  </a>
  <a href="https://twitter.com/EvmosOrg">
    <img alt="Twitter Follow Evmos" src="https://img.shields.io/twitter/follow/EvmosOrg"/>
  </a>
</div>

# Evmos
This repository is a fork of Evmos [v9.1.0](https://github.com/evmos/evmos/tree/v9.1.0).
We expand on version v9.1.0 by adding functionalities that allow smart contracts to compute on encrypted data.

Evmos is a scalable, high-throughput Proof-of-Stake blockchain that is fully compatible and
interoperable with Ethereum. It's built using the [Cosmos SDK](https://github.com/cosmos/cosmos-sdk/) which runs on top of [Tendermint Core](https://github.com/tendermint/tendermint) consensus engine.

**Note**: Requires [Go 1.18+](https://golang.org/dl/)

# What is the last version

Please check the [CHANGELOG](./CHANGELOG.md) to get the last version of the published (ready-to-use)  docker image and check all the related dependencies.

# Where to start as a developer

Based on your objectives, here are some helpful suggestions.

- __I just want to run fhEVM and see the node's logs.__

So check this [section please](https://github.com/zama-ai/fhevm-hardhat-template#start-fhevm) with a self-sufficient docker image.

- __I want to run without building anything and see the node's configuration, how the FHE keys are generated and a few more details.__

In this case, this [section](#from-github-package-registry) will help you to run the node, see the setup phase.


- __I want to build the FhEVM from source using docker.__

In this case, this [section](#local-build-through-docker-and-e2e-test) will help you to build the node and run it. This build take a few time to complete.

- __I am a core developer :sunglasses:, I need to add some prints :grin: in the code__

In this case, this following [section](#local-build) is for you, good luck!



# Local build

## Prepare tfhe-rs C API

### Build

To build automatically the C library one can use the following commands:

```bash
make build_c_api_tfhe
```

This will clone **tfhe-rs** repository in work_dir folder and build the C api in __work_dir/tfhe-rs/target/release__. 

If the developer has its own **tfhe-rs** repository the TFHE_RS_PATH env variable could be set in .env file. 

### Copy tfhe header file and C library

**Go-ethereum** needs the tfhe.h header file located in __go-ethereum/core/vm__ and the libtfhe.so (linux) or libtfhe.dylib for (Mac) in __go-ethereum/core/vm/lib__.

```bash
cp work_dir/tfhe-rs/target/release/tfhe.h ../go-ethereum/core/vm
mkdir -p ../go-ethereum/core/vm/lib
# Mac
cp work_dir/tfhe-rs/target/release/libtfhe.dylib ../go-ethereum/core/vm/lib
# Linux
cp work_dir/tfhe-rs/target/release/libtfhe.so ../go-ethereum/core/vm/lib
# For linux set LD_LIBRARY_PATH to libtfhe.so also
```

<details>
  <summary>Why do we need to copy the header file and libtfhe?</summary>
<br />

In order to extend geth, we give access to all tfhe operations gathered in the lib c through pre-compiled smart contracts. One can check the file called **tfhe.go** in  __go-ethereum/core/vm__ to go deeper.

</details>
<br />


## Prepare custom go-ethereum and ethermint repositories

To use custom **go-ethereum** and **ethermint** repositories, clone them at the same level as evmos, make your changes and update the go.mod file accordingly:

```bash
-replace github.com/ethereum/go-ethereum v1.10.19 => github.com/zama-ai/go-ethereum v0.1.10
+replace github.com/ethereum/go-ethereum v1.10.19 => ../go-ethereum
 
-replace github.com/evmos/ethermint v0.19.3 => github.com/zama-ai/ethermint v0.1.2
+replace github.com/evmos/ethermint v0.19.3 => ../ethermint
```

Here is the hierarchy of folders:

```bash
.
├── evmos
│   └── work_dir
│       └── tfhe-rs
├── go-ethereum
├── ethermint
```

## Build evmosd binary

To build evmosd binary directly in your system. 

```bash
make install
```

The binary is installed in your system go binary path (e.g. $HOME/go/bin).
If needed update your **PATH** env variable to be able to run evmosd binary from anywhere. 

## Run the node

### Prepare FHE keys

```bash
LOCAL_BUILD_KEY_PATH="$HOME/.evmosd/zama/keys/network-fhe-keys" ./scripts/prepare_volumes_from_fhe_tool_docker.sh v0.2.0
```

This script generates fhe keys and copy them to evmos HOME folder in __$HOME/.evmosd/zama/keys/network-fhe-keys__.


### Setup the node

```bash
# jq is required
./setup.sh
```

### Start the node

```bash
./start.sh
# in a new terminal run the fhevm-decryption-db
docker run -p 8001:8001 ghcr.io/zama-ai/fhevm-decryptions-db:v0.1.5
```

### Reset state

```bash
make clean-local-evmos
# must run ./setup.sh after
```


IMPORTANT NOTES:


<details>
  <summary>Use the faucet</summary>
<br />

```bash
# In evmos root folder
# Replace with your ethereum address
python3 faucet.py 0xa5e1defb98EFe38EBb2D958CEe052410247F4c80
```

</details>

<details>
  <summary>Check if evmosd is linked with the right tfhe-rs C libray - Linux</summary>
<br />

```bash
ldd $HOME/go/bin/evmosd
	linux-vdso.so.1 (0x00007ffdb6d73000)
	libtfhe.so => /PATH_TO/tfhe-rs/target/release/libtfhe.so (0x00007fa87c3a7000)
	libc.so.6 => /lib64/libc.so.6 (0x00007fa87c185000)
	libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x00007fa87c165000)
	libm.so.6 => /lib64/libm.so.6 (0x00007fa87c087000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fa87c9e5000)
```

If the user get:
```bash
evmosd: error while loading shared libraries: libtfhe.so: cannot open shared object file: No such file or directory
```

For linux one solution is to update the LD_LIBRARY_PATH to the libtfhe.so compiled in tfhe-rs

</details>
<br />

Dependencies:

| Name        | Type       | Variable name   | where it is defined |
| ----------- | ---------- | --------------- | ------------------- |
| go-ethereum | repository | -               | directly in go.mod  |
| ethermint   | repository | -               | directly in go.mod  |
| tfhe-rs     | repository | TFHE_RS_VERSION | Makefile/.env       |





# Local build through docker and e2e test

## From sources

If the developer wants to build everything locally from sources, and run the e2e test, this build is the more adapted.

Dependencies:

| Name        | Type       | Variable name   | where it is defined |
| ----------- | ---------- | --------------- | ------------------- |
| evmos       | repository | LOCAL_BUILD     | .env (set to true)  |
| go-ethereum | repository | -               | directly in go.mod  |
| ethermint   | repository | -               | directly in go.mod  |
| tfhe-rs     | repository | TFHE_RS_VERSION | Makefile/.env       |




```bash
make build-docker
```

<br />
<details>
  <summary>Here are the steps executed automatically</summary>
<br />


- Build a base image (or retrieve it from ghcr.io) called __zama-zbc-build__.
- Check tfhe-rs is available in TFHE_RS_PATH (default is work_dir/tfhe-rs)
- In any case the custom version or the cloned (TFHE_RS_VERSION) one is copied into work_dir/tfhe-rs
- Clone go-ethereum and ethermint to work_dir (version are parsed from go.mod)
- Update go.mod to force use local repositories (related to the just above changes)
- Build a container called __evmosnodelocal__.

</details>
<br />

To only init and run the node:

```bash
make init-evmos-node
make run_evmos
# make stop_evmos
```

Docker ps output:

```
CONTAINER ID   IMAGE                     NAMES
0bc6ae374153   evmosnodelocal            evmosnodelocal0
422f83a0ea73   docker-compose_oracledb   zbcoracledb

```


To execute the e2e test, here are the dependencies:

| Name                 | Type       | Variable name                | where it is defined |
| -------------------- | ---------- | ---------------------------- | ------------------- |
| evmos                | repository | LOCAL_BUILD                  | .env (set to true)  |
| fhevm-solidity       | repository | FHEVM_SOLIDITY_VERSION       | Makefile/.env       |
| fhevm-tfhe-cli       | repository | FHEVM_TFHE_CLI_VERSION       | Makefile/.env       |
| fhevm-decryptions-db | repository | FHEVM_DECRYPTIONS_DB_VERSION | Makefile/.env       |





```bash
# without the previous init
make e2e-test
# or if evmos is already initialized.
make run_evmos 
make run_e2e_test
make stop_evmos
```

<br />
<details>
  <summary>Here are the steps executed automatically</summary>
<br />


- check you have all the needed repositories
  - fhevm-tfhe-cli
  - fhevm-solidity
  - fhevm-decryptions-db
- init evmos node by calling /config/setup.sh file
- generate fhe keys using fhevm-tfhe-cli based on scripts/prepare_volumes_from_fhe_tool.sh script
- copy them at the right folder using scripts/prepare_demo_local.sh script
- start evmosnodelocal0 and oracledb (local build) using docker-compose/docker-compose.local.yml file
- run the e2e test 
  - start the test from fhevm-solidity

</details>
<br />

## From github package registry

The fast way to run the e2e test locally using ready to use docker images

Dependencies:

| Name                       | Type              | Variable name | where it is defined          |
| -------------------------- | ----------------- | ------------- | ---------------------------- |
| evmos                      | repository        | LOCAL_BUILD   | .env   (set to false)        |
| ghcr.io/zama-ai/evmos-node | docker image name | hard-coded    | docker-compose.validator.yml |


Init evmos and run it:

```bash
make init-evmos-node
make run_evmos
# make stop_evmos
```

Docker ps output:
```
CONTAINER ID   IMAGE                                       NAMES
02b40fb0bdf7   ghcr.io/zama-ai/evmos-node:v0.1.9           evmosnode0
ac2073c0d6fc   ghcr.io/zama-ai/fhevm-decryptions-db:v0.2.0 zbcoracledb
```


To execute the e2e test, here are the dependencies:

```bash
# if evmos is already initialized.
make run_evmos 
make run_e2e_test
make stop_evmos
```
|            Name            |       Type        |        Variable name         |     where it is defined      |
| :------------------------: | :---------------: | :--------------------------: | :--------------------------: |
|           evmos            |       evmos       |         LOCAL_BUILD          |             .env             |
| ghcr.io/zama-ai/evmos-node | docker image name |          hard-coded          | docker-compose.validator.yml |
|     oracle-db-service      | docker image name |          hard-coded          | docker-compose.validator.yml |
|       fhevm-solidity       |    repository     |    FHEVM_SOLIDITY_VERSION    |        Makefile/.env         |
|       fhevm-tfhe-cli       |    repository     |    FHEVM_TFHE_CLI_VERSION    |        Makefile/.env         |
|    fhevm-decryptions-db    |    repository     | FHEVM_DECRYPTIONS_DB_VERSION |        Makefile/.env         |




## Contributing

Looking for a good place to start contributing? Check out some [`good first issues`](https://github.com/evmos/evmos/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22).

For additional instructions, standards and style guides, please refer to the [Contributing](./CONTRIBUTING.md) document.
