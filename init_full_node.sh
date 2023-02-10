#!/bin/bash
# Clear everything of previous installation
rm -rf ~/.evmosd*

# Reinstall daemon
COSMOS_BUILD_OPTIONS=nostrip make install

./setup.sh

cp /keys/network-fhe-public-keys/* ~/.evmosd/zama/keys/network-fhe-keys
cp -r /keys/users-fhe-keys ~/.evmosd/zama/keys