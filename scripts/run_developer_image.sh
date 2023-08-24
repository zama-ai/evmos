#!/bin/bash

set -Eeuo pipefail

# in /config folder

# init node
./setup.sh

# generate keys
./prepare_volumes_from_fhe_tool.sh /usr/local/bin

# Copy keys to evmos home folder
EVMOS_NETWORK_KEYS_PATH=/root/.evmosd/zama/keys/network-fhe-keys ./prepare_validator_ci.sh

# start the node
TRACE=""
LOGLEVEL="info"

./fhevm-decryptions-db &

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
evmosd start --home /root/.evmosd --pruning=nothing $TRACE --log_level $LOGLEVEL \
        --minimum-gas-prices=0.0001aevmos \
        --json-rpc.gas-cap=50000000 \
        --json-rpc.api eth,txpool,net,web3
