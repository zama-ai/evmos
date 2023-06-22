#!/bin/bash

CHAINID="evmos_9000-1"
MONIKER="localtestnet"
KEYRING="test" # remember to change to other types of keyring like 'file' in-case exposing to outside world, otherwise your balance will be wiped quickly. The keyring test does not require private key to steal tokens from you
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
# to trace evm
#TRACE="--trace"
TRACE=""
HOME_EVMOSD="/$HOME/.evmosd"

EVMOSD="evmosd"

# validate dependencies are installed
command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

# used to exit on first error (any non-zero exit code)
set -e

# Reinstall daemon

# Set client config
$EVMOSD config keyring-backend $KEYRING
$EVMOSD config chain-id $CHAINID

# Set moniker and chain-id for Evmos (Moniker can be anything, chain-id must be an integer)
$EVMOSD init $MONIKER --chain-id $CHAINID

# Change parameter token denominations to aevmos
cat $HOME_EVMOSD/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="aevmos"' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json
cat $HOME_EVMOSD/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="aevmos"' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json
cat $HOME_EVMOSD/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="aevmos"' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json
cat $HOME_EVMOSD/config/genesis.json | jq '.app_state["evm"]["params"]["evm_denom"]="aevmos"' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json
cat $HOME_EVMOSD/config/genesis.json | jq '.app_state["inflation"]["params"]["mint_denom"]="aevmos"' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json

# Set gas and txn limit in genesis
cat $HOME_EVMOSD/config/genesis.json | jq '.consensus_params["block"]["max_gas"]="9999999999999999"' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json
cat $HOME_EVMOSD/config/genesis.json | jq '.consensus_params["block"]["max_bytes"]="104857600"' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json

# Set claims start time
node_address=$($EVMOSD keys list | grep  "address: " | cut -c12-)
current_date=$(date -u +"%Y-%m-%dT%TZ")
cat $HOME_EVMOSD/config/genesis.json | jq -r --arg current_date "$current_date" '.app_state["claims"]["params"]["airdrop_start_time"]=$current_date' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json

# Set claims records for validator account
amount_to_claim=10000
cat $HOME_EVMOSD/config/genesis.json | jq -r --arg node_address "$node_address" --arg amount_to_claim "$amount_to_claim" '.app_state["claims"]["claims_records"]=[{"initial_claimable_amount":$amount_to_claim, "actions_completed":[false, false, false, false],"address":$node_address}]' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json

# Set claims decay
cat $HOME_EVMOSD/config/genesis.json | jq '.app_state["claims"]["params"]["duration_of_decay"]="1000000s"' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json
cat $HOME_EVMOSD/config/genesis.json | jq '.app_state["claims"]["params"]["duration_until_decay"]="100000s"' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json

# Claim module account:
# 0xA61808Fe40fEb8B3433778BBC2ecECCAA47c8c47 || evmos15cvq3ljql6utxseh0zau9m8ve2j8erz89m5wkz
cat $HOME_EVMOSD/config/genesis.json | jq -r --arg amount_to_claim "$amount_to_claim" '.app_state["bank"]["balances"] += [{"address":"evmos15cvq3ljql6utxseh0zau9m8ve2j8erz89m5wkz","coins":[{"denom":"aevmos", "amount":$amount_to_claim}]}]' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json

# Disable production of empty blocks.
# Increase transaction and HTTP server body sizes.
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME_EVMOSD/config/config.toml
    sed -i '' 's/max_body_bytes = 1000000/max_body_bytes = 1000000000/g' $HOME_EVMOSD/config/config.toml
    sed -i '' 's/max_tx_bytes = 1048576/max_tx_bytes = 100000000/g' $HOME_EVMOSD/config/config.toml
  else
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME_EVMOSD/config/config.toml
    sed -i 's/max_body_bytes = 1000000/max_body_bytes = 1000000000/g' $HOME_EVMOSD/config/config.toml
    sed -i 's/max_tx_bytes = 1048576/max_tx_bytes = 100000000/g' $HOME_EVMOSD/config/config.toml
fi

if [[ $1 == "pending" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME_EVMOSD/config/config.toml
      sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME_EVMOSD/config/config.toml
      sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME_EVMOSD/config/config.toml
      sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME_EVMOSD/config/config.toml
      sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME_EVMOSD/config/config.toml
      sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME_EVMOSD/config/config.toml
      sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME_EVMOSD/config/config.toml
      sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME_EVMOSD/config/config.toml
      sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME_EVMOSD/config/config.toml
  else
      sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME_EVMOSD/config/config.toml
      sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME_EVMOSD/config/config.toml
      sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME_EVMOSD/config/config.toml
      sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME_EVMOSD/config/config.toml
      sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME_EVMOSD/config/config.toml
      sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME_EVMOSD/config/config.toml
      sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME_EVMOSD/config/config.toml
      sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME_EVMOSD/config/config.toml
      sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME_EVMOSD/config/config.toml
  fi
fi

# Update total supply with claim values
validators_supply=$(cat $HOME_EVMOSD/config/genesis.json | jq -r '.app_state["bank"]["supply"][0]["amount"]')
# Bc is required to add this big numbers
# total_supply=$(bc <<< "$amount_to_claim+$validators_supply")
total_supply=100000000000000000000010000
cat $HOME_EVMOSD/config/genesis.json | jq -r --arg total_supply "$total_supply" '.app_state["bank"]["supply"][0]["amount"]=$total_supply' > $HOME_EVMOSD/config/tmp_genesis.json && mv $HOME_EVMOSD/config/tmp_genesis.json $HOME_EVMOSD/config/genesis.json

# Run this to ensure everything worked and that the genesis file is setup correctly
# $EVMOSD validate-genesis

if [[ $1 == "pending" ]]; then
  echo "pending mode is on, please wait for the first block committed."
fi


# Create Zama-specific directories and files.
mkdir -p $HOME_EVMOSD/zama/keys/users-fhe-keys
mkdir -p $HOME_EVMOSD/zama/keys/network-fhe-keys
mkdir -p $HOME_EVMOSD/zama/keys/signature-keys
mkdir -p $HOME_EVMOSD/zama/config
cp ./zama_config.toml $HOME_EVMOSD/zama/config/
cp ./private.ed25519 $HOME_EVMOSD/zama/keys/signature-keys
cp ./public.ed25519 $HOME_EVMOSD/zama/keys/signature-keys
