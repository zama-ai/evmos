#!/bin/bash
COSMOS_BUILD_OPTIONS=nostrip make install

./setup.sh

touch $HOME/privkey
evmosd keys unsafe-export-eth-key mykey1 --keyring-backend test > $HOME/privkey
touch $HOME/node_id
evmosd tendermint show-node-id > $HOME/node_id