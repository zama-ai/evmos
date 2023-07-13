<!--
Guiding Principles:

Changelogs are for humans, not machines.
There should be an entry for every single version.
The same types of changes should be grouped.
Versions and sections should be linkable.
The latest version comes first.
The release date of each version is displayed.
Mention whether you follow Semantic Versioning.

Usage:

Change log entries are to be added to the Unreleased section under the
appropriate stanza (see below). Each entry should ideally include a tag and
the Github issue reference in the following format:

* (<tag>) \#<issue-number> message

The issue numbers will later be link-ified during the release process so you do
not have to worry about including a link manually, but you can if you wish.

Types of changes (Stanzas):

"Features" for new features.
"Improvements" for changes in existing functionality.
"Deprecated" for soon-to-be removed features.
"Bug Fixes" for any bug fixes.
"Client Breaking" for breaking CLI commands and REST routes used by end-users.
"API Breaking" for breaking exported APIs used by developers building on SDK.
"State Machine Breaking" for any changes that result in a different AppState given same genesisState and txList.

Ref: https://keepachangelog.com/en/1.0.0/
-->

# Changelog

## [v0.1.5]

**This version should be stable, from now on we do not think to add important changes for the short-term period.**

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.5

**Major update**: 
* Handle errors from tfhe-rs by @dartdart26 [go-ethereum/pull/135](https://github.com/zama-ai/go-ethereum/pull/135)
* Add scalar ops, bitshift, min/max by @tremblaythibaultl [go-ethereum/pull/130](https://github.com/zama-ai/go-ethereum/pull/130)
* fix(faucet): make faucet drop 10 coins by @tremblaythibaultl [go-ethereum/pull/132](https://github.com/zama-ai/go-ethereum/pull/132)
* Fix nil pointer dereference on gas estimation by @tremblaythibaultl [go-ethereum/pull/133](https://github.com/zama-ai/go-ethereum/pull/133)

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.6                  |
|  ethermint  | repository |                  v0.1.0                  |
|   tfhe-rs   | repository |               0.3.0-beta.0               |


For e2e test:

|     Name      |    Type    | version |
| :-----------: | :--------: | :-----: |
| fhevm-solidity  | repository | v0.1.2  |
| fhevm-tfhe-cli  | repository | v0.1.1  |
| fhevm-requires-db | repository |  main   |

## [v0.1.4]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.4

**Major update**: 
- [improve gas estimation](https://github.com/zama-ai/go-ethereum/pull/124)
- [add support for casting](https://github.com/zama-ai/go-ethereum/pull/118])
- [Add all available FHE ops](https://github.com/zama-ai/go-ethereum/pull/120)

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.4                  |
|  ethermint  | repository |                  v0.1.0                  |
|   tfhe-rs   | repository |               0.3.0-beta.0               |


For e2e test:

|     Name      |    Type    | version |
| :-----------: | :--------: | :-----: |
| fhevm-solidity  | repository | v0.1.1  |
| fhevm-tfhe-cli  | repository | v0.1.1  |
| fhevm-requires-db | repository |  main   |

## [v0.1.3]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.3

**Major update**: move tfhe-rs to tag __0.3.0-beta.0__

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.3                  |
|  ethermint  | repository |                v1.0.0-test               |
|   tfhe-rs   | repository |               0.3.0-beta.0               |


For e2e test:

|     Name      |    Type    | version |
| :-----------: | :--------: | :-----: |
| fhevm-solidity  | repository | v0.1.1  |
| fhevm-tfhe-cli  | repository | v0.1.1  |
| fhevm-requires-db | repository |  main   |

## [v0.1.2]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.2

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.3                  |
|  ethermint  | repository |                v1.0.0-test               |
|   tfhe-rs   | repository | 1d817c45d5234bcf33638406191b656998b30c2a |


For e2e test:

|     Name      |    Type    | version |
| :-----------: | :--------: | :-----: |
| fhevm-solidity  | repository | v0.1.0  |
| fhevm-tfhe-cli  | repository | v0.1.0  |
| fhevm-requires-db | repository |  main   |


## [v0.1.0]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.0

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.0                  |
|  ethermint  | repository |                v1.0.0-test               |
|   tfhe-rs   | repository | 1d817c45d5234bcf33638406191b656998b30c2a |


For e2e test:

|     Name      |    Type    | version |
| :-----------: | :--------: | :-----: |
| fhevm-solidity  | repository | v0.1.0  |
| fhevm-tfhe-cli  | repository | v0.1.0  |
| fhevm-requires-db | repository |  main   |

