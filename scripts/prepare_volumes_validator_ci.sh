#!/bin/bash

set -Eeuo pipefail

NETWORK_KEYS_PUBLIC_PATH=./volumes/network-public-fhe-keys
NETWORK_KEYS_PRIVATE_PATH=./volumes/network-private-fhe-keys
S3_BUCKET_PATH="s3://zbc-testnet"
S3_NETWORK_KEYS_PATH="$S3_BUCKET_PATH/network-fhe-keys"
S3_NETWORK_KEYS_FULL_PATH="$S3_NETWORK_KEYS_PATH/keys_gen_with_zbc_fhe_tool_v0_1_1"

mkdir -p $NETWORK_KEYS_PUBLIC_PATH
mkdir -p $NETWORK_KEYS_PRIVATE_PATH

key="sks"
echo "Downloading $key from $S3_NETWORK_KEYS_FULL_PATH to $NETWORK_KEYS_PUBLIC_PATH, please wait ..."
aws s3 cp $S3_NETWORK_KEYS_FULL_PATH/$key $NETWORK_KEYS_PUBLIC_PATH/sks

key="pks"
echo "Downloading $key from $S3_NETWORK_KEYS_FULL_PATH to $NETWORK_KEYS_PUBLIC_PATH, please wait ..."
aws s3 cp $S3_NETWORK_KEYS_FULL_PATH/$key $NETWORK_KEYS_PUBLIC_PATH/pks

key="cks"
echo "Downloading $key to $NETWORK_KEYS_PRIVATE_PATH, please wait ..."
aws s3 cp $S3_NETWORK_KEYS_FULL_PATH/$key $NETWORK_KEYS_PRIVATE_PATH/cks


