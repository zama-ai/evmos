#!/bin/bash
# Clear everything of previous installation
rm -rf ~/.evmosd*

# Reinstall daemon
COSMOS_BUILD_OPTIONS=nostrip make install

./setup.sh

#get genesis.json and privkey from AWS
cp ~/genesis.json ~/.evmosd/config/
NODE_ID=`cat ~/node_id` 
cp ~/.evmosd/config/config.toml temp
awk -v node_id=$NODE_ID 'NR==212 { sub("\"\"", "\""node_id"@15.188.64.234:26656\"") }; { print }' temp >~/.evmosd/config/config.toml
rm temp