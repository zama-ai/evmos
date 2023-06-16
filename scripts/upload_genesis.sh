#!/bin/bash

set -Eeuo pipefail

S3_BUCKET_PATH="s3://zbc-testnet"
S3_FULL_PATH="$S3_BUCKET_PATH/testnet_full_node"
LOCAL_PATH_TO_NODE="./node"
LOCAL_PATH_TO_EVMOSD="./running_node/node2"

echo "Getting the privkey"
docker compose -f docker-compose/docker-compose.validator.yml exec validator evmosd --home /root/.evmosd tendermint show-node-id > $LOCAL_PATH_TO_NODE/node_id

echo "Getting the node_id"
docker compose -f docker-compose/docker-compose.validator.yml exec validator evmosd --home /root/.evmosd keys unsafe-export-eth-key mykey1 --keyring-backend test > $LOCAL_PATH_TO_NODE/privkey

echo "Uploading genesis.json to S3 bucket..."
aws s3 cp $LOCAL_PATH_TO_EVMOSD/.evmosd/config/genesis.json $S3_FULL_PATH/genesis.json

echo "Uploading privkey to S3 bucket..."
aws s3 cp $LOCAL_PATH_TO_NODE/privkey $S3_FULL_PATH/privkey

echo "Uploading node_id to S3 bucket..."
aws s3 cp $LOCAL_PATH_TO_NODE/node_id  $S3_FULL_PATH/node_id

