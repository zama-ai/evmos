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

## [v0.1.10]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.10

Evmos-node developer docker image: ghcr.io/zama-ai/evmos-dev-node:v0.1.10

**Major updates**: 
* Added support for remainder operation (precompile)

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.12                 |
|  ethermint  | repository |                  v0.1.2                  |
|   tfhe-rs   | repository |                   0.3.1                  |


For e2e test:

|       Name           |    Type    |     version     |
| :------------------: | :--------: | :-------------: |
|    fhevm-solidity    | repository |     v0.1.14     |
|    fhevm-tfhe-cli    | repository |     v0.2.1      |
| fhevm-decryptions-db | repository |     v0.2.0      |

## [v0.1.9]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.9

Evmos-node developer docker image: ghcr.io/zama-ai/evmos-dev-node:v0.1.9

**Major updates**: 
* Use new parameters for FHE keys by @leventdem in https://github.com/zama-ai/fhevm-tfhe-cli/pull/17
* feature: add fhe rand() by @dartdart26 in https://github.com/zama-ai/evmos/pull/191

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.11                 |
|  ethermint  | repository |                  v0.1.2                  |
|   tfhe-rs   | repository |                   0.3.1                  |


For e2e test:

|       Name           |    Type    |     version     |
| :------------------: | :--------: | :-------------: |
|    fhevm-solidity    | repository |     v0.1.12     |
|    fhevm-tfhe-cli    | repository |     v0.2.1      |
| fhevm-decryptions-db | repository |     v0.2.0      |

## [v0.1.8]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.8

Evmos-node developer docker image: ghcr.io/zama-ai/evmos-dev-node:v0.1.8

**Major updates**: 

* Add TFHE scalar division operation by @david-zama in [go-ethereum/pull/151](https://github.com/zama-ai/go-ethereum/pull/151)
* Add precompile to all releases by @tremblaythibaultl in [go-ethereum/pull/154](https://github.com/zama-ai/go-ethereum/pull/154)
* Fix gas estimation for explicit decryption by @dartdart26 in [go-ethereum/pull/155](https://github.com/zama-ai/go-ethereum/pull/155)

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.9                  |
|  ethermint  | repository |                  v0.1.2                  |
|   tfhe-rs   | repository |                   0.3.1                  |


For e2e test:

|       Name           |    Type    |     version     |
| :------------------: | :--------: | :-------------: |
|    fhevm-solidity    | repository |     v0.1.9      |
|    fhevm-tfhe-cli    | repository |     v0.2.0      |
| fhevm-decryptions-db | repository |     v0.2.0      |

## [v0.1.7]

**This version includes a repository renaming!**

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.7

Evmos-node developer docker image: ghcr.io/zama-ai/evmos-dev-node:v0.1.7

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.7                  |
|  ethermint  | repository |                  v0.1.2                  |
|   tfhe-rs   | repository |               0.3.0-beta.0               |


For e2e test:

|       Name           |    Type    |     version     |
| :------------------: | :--------: | :-------------: |
|    fhevm-solidity    | repository |     v0.1.7      |
|    fhevm-tfhe-cli    | repository |     v0.1.2      |
| fhevm-decryptions-db | repository |     v0.1.0      |

## [v0.1.6]

**This version includes several repositories renaming!**

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.6

**Major updates**: 
* Reduce gas block limit from 100M to 10M by in [evmos/pull/161](https://github.com/zama-ai/evmos/pull/161)
* feat(tfhe): add support for `ebool` type in [fhevm-solidity](https://github.com/zama-ai/fhevm-solidity/pull/86)

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.7                  |
|  ethermint  | repository |                  v0.1.2                  |
|   tfhe-rs   | repository |               0.3.0-beta.0               |


For e2e test:

|       Name        |    Type    |     version     |
| :---------------: | :--------: | :-------------: |
|  fhevm-solidity   | repository |     v0.1.5      |
|  fhevm-tfhe-cli   | repository | v0.1.1-renaming |
| fhevm-requires-db | repository |     v0.1.0      |


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

|     Name           |    Type    | version |
| :-----------:      | :--------: | :-----: |
| fhevm-solidity     | repository | v0.1.2  |
| fhevm-tfhe-cli     | repository | v0.1.1  |
| fhevm-requires-db  | repository |  main   |

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

|     Name           |    Type    | version |
| :-----------:      | :--------: | :-----: |
| fhevm-solidity     | repository | v0.1.1  |
| fhevm-tfhe-cli     | repository | v0.1.1  |
| fhevm-requires-db  | repository |  main   |

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

|     Name           |    Type    | version |
| :-----------:      | :--------: | :-----: |
| fhevm-solidity     | repository | v0.1.1  |
| fhevm-tfhe-cli     | repository | v0.1.1  |
| fhevm-requires-db  | repository |  main   |

## [v0.1.2]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.2

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.3                  |
|  ethermint  | repository |                v1.0.0-test               |
|   tfhe-rs   | repository | 1d817c45d5234bcf33638406191b656998b30c2a |


For e2e test:

|     Name           |    Type    | version |
| :-----------:      | :--------: | :-----: |
| fhevm-solidity     | repository | v0.1.0  |
| fhevm-tfhe-cli     | repository | v0.1.0  |
| fhevm-requires-db  | repository |  main   |


## [v0.1.0]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.0

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.0                  |
|  ethermint  | repository |                v1.0.0-test               |
|   tfhe-rs   | repository | 1d817c45d5234bcf33638406191b656998b30c2a |


For e2e test:

|     Name           |    Type    | version |
| :-----------:      | :--------: | :-----: |
| fhevm-solidity     | repository | v0.1.0  |
| fhevm-tfhe-cli     | repository | v0.1.0  |
| fhevm-requires-db  | repository |  main   |

