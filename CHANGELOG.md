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

## [v0.1.2]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.2

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.3                  |
|  ethermint  | repository |                  v0.1.0                  |
|   tfhe-rs   | repository | 1d817c45d5234bcf33638406191b656998b30c2a |


For e2e test:

|     Name      |    Type    | version |
| :-----------: | :--------: | :-----: |
| zbc-solidity  | repository | v0.1.0  |
| zbc-fhe-tool  | repository | v0.1.0  |
| zbc-oracle-db | repository |  main   |


## [v0.1.0]

Evmos-node docker image: ghcr.io/zama-ai/evmos-node:v0.1.0

For build:

|    Name     |    Type    |                 version                  |
| :---------: | :--------: | :--------------------------------------: |
| go-ethereum | repository |                  v0.1.3                  |
|  ethermint  | repository |                  v0.1.0                  |
|   tfhe-rs   | repository | 1d817c45d5234bcf33638406191b656998b30c2a |


For e2e test:

|     Name      |    Type    | version |
| :-----------: | :--------: | :-----: |
| zbc-solidity  | repository | v0.1.0  |
| zbc-fhe-tool  | repository | v0.1.0  |
| zbc-oracle-db | repository |  main   |

