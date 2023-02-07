#!/bin/bash
# Clear everything of previous installation
rm -rf ~/.evmosd*

# Reinstall daemon
COSMOS_BUILD_OPTIONS=nostrip make install

./setup.sh

cp /keys/network-fhe-public-keys/* ~/.evmosd/zama/keys/network-fhe-keys
cp /keys/network-fhe-private-keys/* ~/.evmosd/zama/keys/network-fhe-keys
cp -r /keys/users-fhe-keys ~/.evmosd/zama/keys

touch $HOME/privkey
evmosd keys unsafe-export-eth-key mykey1 --keyring-backend test > $HOME/privkey
touch $HOME/node_id
evmosd tendermint show-node-id > $HOME/node_id