#!/bin/bash

# This bash script creates global fhe keys
# and copy them to the right folder in volumes directory.
# It accepts the path to the fhevm-tfhe-cli as parameter.

set -Eeuo pipefail

if [ "$#" -ne 1 ]; then
    echo "Please give the path to the fhevm-tfhe-cli"
    echo "Example: $(basename $0) PATH_TO/fhevm-tfhe-cli/target/release"
    echo "Reminder to build fhevm-tfhe-cli: cargo build --release "
    exit
fi

FHEVM_TFHE_CLI_PATH=$1
BINARY_NAME="fhevm-tfhe-cli"
CURRENT_FOLDER=$PWD

echo "Check if $BINARY_NAME is available in $FHEVM_TFHE_CLI_PATH "
if [ ! -f "$FHEVM_TFHE_CLI_PATH/$BINARY_NAME" ]; then
    echo "#####ATTENTION######"
    echo "BINARY_NAME does not exist!"
    echo "####################"
    exit
else
    echo "$BINARY_NAME exists, let's create keys!"
fi


KEYS_FULL_PATH=$CURRENT_FOLDER/res/keys
mkdir -p $KEYS_FULL_PATH

$FHEVM_TFHE_CLI_PATH/$BINARY_NAME generate-keys -d res/keys


echo "###########################################################"
echo "Keys creation is done, they are stored in $KEYS_FULL_PATH"
echo "###########################################################"


NETWORK_KEYS_PUBLIC_PATH=./volumes/network-public-fhe-keys
NETWORK_KEYS_PRIVATE_PATH=./volumes/network-private-fhe-keys

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


echo "###########################################################"
echo "If you want to execute a local test using the same keys,"
echo "please run the following command in zbc-solidity:"
echo "prepare_fhe_keys_from_fhe_tool.sh $KEYS_FULL_PATH"
echo "###########################################################"

