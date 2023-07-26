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

The quick start is to follow this [section](#from-github-package-registry)

Note: on arm64 we still have some issues, fixes are coming soon


# Local build

To build evmosd binary directly in your system. 

```bash
export GOPRIVATE=github.com/zama-ai/*
make build-local
```

The binary is built in build folder.

Dependencies:

| Name        | Type       | Variable name   | where it is defined |
| ----------- | ---------- | --------------- | ------------------- |
| go-ethereum | repository | -               | directly in go.mod  |
| ethermint   | repository | -               | directly in go.mod  |
| tfhe-rs     | repository | TFHE_RS_VERSION | Makefile/.env       |





# Local build through docker and e2e test

## From sources

If the developer wants to build everything locally from sources, and run the e2e test this build is the more adapted.

Dependencies:

| Name        | Type       | Variable name   | where it is defined |
| ----------- | ---------- | --------------- | ------------------- |
| evmos       | repository | LOCAL_BUILD     | .env                |
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
- Clone go-ethereum and ethermint to work_dir (version are parsed from go.mod to avoid handling ssh keys inside docker because those repositories are private)
- Update go.mod to make it use local repositories (related to the just above changes)
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

| Name          | Type       | Variable name         | where it is defined |
| ------------- | ---------- | --------------------- | ------------------- |
| evmos         | repository | LOCAL_BUILD           | .env                |
| fhevm-solidity| repository | ZBC_SOLIDITY_VERSION  | Makefile/.env       |
| fhevm-tfhe-cli  | repository | ZBC_FHE_TOOL_VERSION  | Makefile/.env       |
| zbc-oracle-db | repository | ZBC_ORACLE_DB_VERSION | Makefile/.env       |




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
  - zbc-oracledb
- init evmos node by calling /config/setup.sh file
- generate fhe keys using fhevm-tfhe-cli based on scripts/prepare_volumes_from_fhe_tool.sh script
- copy them at the right folder using scripts/prepare_demo_local.sh script
- start evmosnodelocal0 and oracledb (local build) using docker-compose/docker-compose.local.yml file
- run the e2e test 
  - copy pks to encrypt user input using $(ZBC_SOLIDITY_PATH)/prepare_fhe_keys_for_e2e_test script
  - start the test using $(ZBC_SOLIDITY_PATH)/run_ERC20_e2e_test.sh
    - Get the private key of main account 
    - Give it to the python test script $(ZBC_SOLIDITY_PATH)/ci/tests/ERC20.py

</details>
<br />

## From github package registry

The fast way to run the e2e test locally using ready to use docker images

Dependencies:

| Name                       | Type              | Variable name | where it is defined          |
| -------------------------- | ----------------- | ------------- | ---------------------------- |
| evmos                      | repository        | LOCAL_BUILD   | .env                         |
| ghcr.io/zama-ai/evmos-node | docker image name | hard-coded    | docker-compose.validator.yml |




Init evmos and run it:

```bash
make init-evmos-node
make run_evmos
# make stop_evmos
```

Docker ps output:
```
CONTAINER ID   IMAGE                                      NAMES
02b40fb0bdf7   ghcr.io/zama-ai/evmos-node:v0.1.0     evmosnode0
ac2073c0d6fc   ghcr.io/zama-ai/oracle-db-service:latest   zbcoracledb
```

To execute the e2e test, here are the dependencies:

```bash
# if evmos is already initialized.
make run_evmos 
make run_e2e_test
make stop_evmos
```
|            Name            |       Type        |     Variable name     |     where it is defined      |
| :------------------------: | :---------------: | :-------------------: | :--------------------------: |
|           evmos            |       evmos       |      LOCAL_BUILD      |             .env             |
| ghcr.io/zama-ai/evmos-node | docker image name |      hard-coded       | docker-compose.validator.yml |
|     oracle-db-service      | docker image name |      hard-coded       | docker-compose.validator.yml |
|        fhevm-solidity      |    repository     | ZBC_SOLIDITY_VERSION  |        Makefile/.env         |
|        fhevm-tfhe-cli      |    repository     | ZBC_FHE_TOOL_VERSION  |        Makefile/.env         |
|       zbc-oracle-db        |    repository     | ZBC_ORACLE_DB_VERSION |        Makefile/.env         |




Note:
- for the zbc-oracle-db docker image it could not work on arm64 because the arm64 version is not yet pushed in ghcr.io

<br />
<details>
  <summary>Troubleshoot ghcr.io</summary>

Here is a tutorial on [how to manage ghcr.io access](https://github.com/zama-ai/fhevm-tfhe-cli#using-the-published-image-easiest-way).

  If you get trouble to pull image from ghcri.io, one can build it locally with
  ```bash
  docker build . -t zama-zbc-build -f docker/Dockerfile.zbc.build
  ```
</details>

<details>
  <summary>Troubleshoot go modules for local-build</summary>

Because evmos depends on private [go-ethereum](https://github.com/zama-ai/go-ethereum) and [ethermint](https://github.com/zama-ai/ethermint) repositories, one need to pay attention to two points to allow go modules manager to work correctly.

1. Check that GOPRIVATE is set to __github.com/zama-ai/*__ (normally this env variable is set by default in Makefile)
2. Check you have the following lines in your gitconfig files:

```bash
[url "ssh://git@github.com/"]
        insteadOf = https://github.com/
```
</details>
<br />



## Contributing

Looking for a good place to start contributing? Check out some [`good first issues`](https://github.com/evmos/evmos/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22).

For additional instructions, standards and style guides, please refer to the [Contributing](./CONTRIBUTING.md) document.
