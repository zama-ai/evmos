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

Evmos is a scalable, high-throughput Proof-of-Stake blockchain that is fully compatible and
interoperable with Ethereum. It's built using the [Cosmos SDK](https://github.com/cosmos/cosmos-sdk/) which runs on top of [Tendermint Core](https://github.com/tendermint/tendermint) consensus engine.

**Note**: Requires [Go 1.18+](https://golang.org/dl/)

## Instructions for Zama block chain

1. [MANDATORY] In order to use our custom EVM, please use the branch [__1.10.19-zama__](https://github.com/zama-ai/go-ethereum/tree/1.10.19-zama) in Zama go-ethereum repository.
2. [CHECK] Please check that go.mod in this repository root folder points to the custom go-ethereum repository (end of the file).
3. [MANDATORY] For pre-compiled contracts, we need to add to go_ethereum the C API dynamic library. The [install_tfhe_rs_script](https://github.com/zama-ai/go-ethereum/blob/1.10.19-zama/install_thfe_rs_api.sh) scripts allows to install it directly to the right place. To be more precise, the libray files are built and copied into __core/vm/lib__ folder and the tfhe C header file is placed in __core/vm__ folder. 
4. [HELP_IF_ERROR] If the library is not found when the node is run  consider updating some env variable as __LD_LIBRARY_PATH__ with the path of go-ethereum/core/vm/lib. 
4. [HELP_IF_ERROR_IN_DEBUG] If the library is not found in the DEBUG mode, please consider to add the env variable as for the point 4 for the launch.json file. Here is an example launch.json file. 
```bash
{
    "configurations": [
        {
            "name": "evmosd",
            "type": "go",
            "request": "launch",
            "mode": "exec",
            "program": "/home/ldemir/go/bin/evmosd",
            "env": {
                "LD_LIBRARY_PATH": "/home/ldemir/Documents/dev/blockchain/go-ethereum/core/vm/lib/"
            },
            "args": [
                "start",
                "--pruning=nothing",
                "--log_level=info",
                "--minimum-gas-prices=0.0001aevmos",
                "--json-rpc.api=eth,txpool,personal,net,debug,web3"
            ]
        }
    ]
}
```

Now you can continue to Installation session. 


## Installation

For prerequisites and detailed build instructions please read the [Installation](https://evmos.dev/validators/quickstart/installation.html) instructions. Once the dependencies are installed, run:

```bash
make install
```

Or check out the latest [release](https://github.com/evmos/evmos/releases).

### Quick Start

To learn how the Evmos works from a high-level perspective, go to the [Introduction](https://evmos.dev/about/intro/overview.html) section from the documentation. You can also check the instructions to [Run a Node](https://evmos.dev/validators/quickstart/run_node.html).

## ZBC Testnet

The Zama Blockchain testnet is live. The validator node is located at `13.38.123.182` and the full node is at `13.36.38.238`. 
Whitelisted IPs can trigger the full node's RPC endpoints at `http://13.36.38.238:8545`. 
From this connection, users can interact with encrypted smart contracts.

### Running a testnet

To setup a several node network, one must follow the following steps in order:
1. On each device, clone the following repos: [evmos](https://github.com/zama-ai/evmos), [go-ethereum](https://github.com/zama-ai/go-ethereum) and [ethermint](https://github.com/zama-ai/ethermint) and checkout the zama branches on each repo. On the validator device, clone the [zbc-oracle-db](https://github.com/zama-ai/zbc-oracle-db) repo.
2. On each device, run the `install_thfe_rs_api.sh` script in the `go-ethereum` folder. This will download and build the TFHE-rs C API necessary to perform FHE operations. 
3. On each device, run the `init.sh` script in the `evmos` folder. This will setup a basic inital configuration for the evmos node software.
4. Retrieve the `~/.evmosd/config/genesis.json` from the validator node and distribute it at the same location on all the other nodes. This will overwrite the other nodes' initial configuration, it's ok. 
5. On the validator device, launch the Oracle DB with `cargo run` in the `zbc-oracle-db` folder.
6. On the validator device, run the `start.sh` in the `evmos` folder. This will start the node. 
7. On the validator device, while the node is running, run the command `evmosd tendermint show-node-id` and save the result of this command. 
8. On each device except the validator, we need to add the validator as the seed node. To do so, edit line 212 of file `~/.evmosd/config/config.toml` and in the `seed` field, add `<VALIDATOR_NODE_ID>@<VALIDATOR_IP_ADDRESS>:26656` where the validator node ID is the result of the last step.
9. On each device except the validator, edit the file `~/.evmosd/zama/config/zama_config.toml`. Change the mode to `node` and the Oracle DB address to the IP address of the validator.
10. On each device except the validator, run the `start.sh` script in the `evmos` folder. This will start the full nodes which will start syncing the full chain history from the validator node.

## Community

The following chat channels and forums are a great spot to ask questions about Evmos:

- [Evmos Twitter](https://twitter.com/EvmosOrg)
- [Evmos Discord](https://discord.gg/evmos)
- [Evmos Forum](https://commonwealth.im/evmos)
- [Tharsis Twitter](https://twitter.com/TharsisHQ)

## Contributing

Looking for a good place to start contributing? Check out some [`good first issues`](https://github.com/evmos/evmos/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22).

For additional instructions, standards and style guides, please refer to the [Contributing](./CONTRIBUTING.md) document.

## Careers

See our open positions on [Cosmos Jobs](https://jobs.cosmos.network/project/evmos-d0sk1uxuh-remote/), [Notion](https://tharsis.notion.site), or feel free to [reach out](mailto:careers@thars.is) via email.
