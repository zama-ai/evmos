#!/bin/bash

# This bash script creates global fhe keys
# and copy them to the right folder in volumes directory.
# It accepts the versin of fhevm-tfhe-cli as parameter.

set -Eeuo pipefail

if [ "$#" -ne 1 ]; then
    echo "Please give the version of fhevm-tfhe-cli"
    echo "Example: $(basename $0) v0.1.2"
    exit
fi

FHEVM_TFHE_CLI_VERSION=$1
BINARY_NAME="fhevm-tfhe-cli"
DOCKER_IMAGE=ghcr.io/zama-ai/fhevm-tfhe-cli:$FHEVM_TFHE_CLI_VERSION
CURRENT_FOLDER=$PWD


KEYS_FULL_PATH=$CURRENT_FOLDER/res/keys
mkdir -p $KEYS_FULL_PATH

docker run -v $PWD:/usr/local/app $DOCKER_IMAGE $BINARY_NAME generate-keys -d res/keys


echo "###########################################################"
echo "Keys creation is done, they are stored in $KEYS_FULL_PATH"
echo "###########################################################"

NETWORK_KEYS_PUBLIC_PATH="${LOCAL_BUILD_KEY_PATH:-./volumes/network-public-fhe-keys}"
NETWORK_KEYS_PRIVATE_PATH="${LOCAL_BUILD_KEY_PATH:-./volumes/network-private-fhe-keys}"

echo "$NETWORK_KEYS_PUBLIC_PATH"
echo "$NETWORK_KEYS_PRIVATE_PATH"

MANDATORY_KEYS_LIST=('sks' 'cks' 'pks')

for key in "${MANDATORY_KEYS_LIST[@]}"
    do
        if [ ! -f "$KEYS_FULL_PATH/$key" ]; then
            echo "#####ATTENTION######"
            echo "$key does not exist in $KEYS_FULL_PATH!"
            echo "####################"
            exit
        fi
done

echo "###########################################################"
echo "All the required keys exist in $KEYS_FULL_PATH"
echo "###########################################################"

mkdir -p $NETWORK_KEYS_PUBLIC_PATH
mkdir -p $NETWORK_KEYS_PRIVATE_PATH

key="sks"
echo "Copying $key to $NETWORK_KEYS_PUBLIC_PATH, please wait ..."
cp $KEYS_FULL_PATH/$key $NETWORK_KEYS_PUBLIC_PATH/sks

key="pks"
echo "Copying $key to $NETWORK_KEYS_PUBLIC_PATH, please wait ..."
cp $KEYS_FULL_PATH/$key $NETWORK_KEYS_PUBLIC_PATH/pks

key="cks"
echo "Copying $key to $NETWORK_KEYS_PRIVATE_PATH, please wait ..."
cp $KEYS_FULL_PATH/$key $NETWORK_KEYS_PRIVATE_PATH/cks



