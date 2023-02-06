#!/bin/bash
# Clear everything of previous installation
rm -rf ~/.evmosd*

# Reinstall daemon
COSMOS_BUILD_OPTIONS=nostrip make install

./setup.sh

touch $HOME/privkey
evmos keys unsafe-export-eth-key mykey1 --keyring-backend test > $HOME/privkey
touch $HOME/node_id
evmos tendermint show-node-id > $HOME/node_id