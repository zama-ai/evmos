#!/bin/bash

set -Eeuo pipefail

VOLUME_NETWORK_PUBLIC_KEYS_PATH=./volumes/network-public-fhe-keys
VOLUME_NETWORK_PRIVATE_KEYS_PATH=./volumes/network-private-fhe-keys
EVMOS_NETWORK_KEYS_PATH=./running_node/node1/.evmosd/zama/keys/network-fhe-keys

mkdir -p $EVMOS_NETWORK_KEYS_PATH

# In go-ethereum both private and public key for network are at the same place
NETWORK_PUBLIC_KEYS_LIST=('sks' 'pks')
 
for key in "${NETWORK_PUBLIC_KEYS_LIST[@]}"
do
    if [[ ! -f "$VOLUME_NETWORK_PUBLIC_KEYS_PATH/$key" ]]; then
        echo "The file $VOLUME_NETWORK_PUBLIC_KEYS_PATH/$key does not exist."
        exit
    fi
    echo "Copying $VOLUME_NETWORK_PUBLIC_KEYS_PATH/$key to $EVMOS_NETWORK_KEYS_PATH, please wait ..."
    cp -v $VOLUME_NETWORK_PUBLIC_KEYS_PATH/$key $EVMOS_NETWORK_KEYS_PATH
done

NETWORK_PRIVATE_KEYS_LIST=('cks')
 
for key in "${NETWORK_PRIVATE_KEYS_LIST[@]}"
do
    if [[ ! -f "$VOLUME_NETWORK_PRIVATE_KEYS_PATH/$key" ]]; then
        echo "The file $VOLUME_NETWORK_PRIVATE_KEYS_PATH/$key does not exist."
        exit
    fi
    echo "Copying $VOLUME_NETWORK_PRIVATE_KEYS_PATH/$key to $EVMOS_NETWORK_KEYS_PATH, please wait ..."
    cp -v $VOLUME_NETWORK_PRIVATE_KEYS_PATH/$key $EVMOS_NETWORK_KEYS_PATH
done

