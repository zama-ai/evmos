TRACE=""
LOGLEVEL="info"

# Recompile, if needed.
COSMOS_BUILD_OPTIONS=nostrip make install

cp /node_config/genesis.json ~/.evmosd/config
cp /node_config/config.toml ~/.evmosd/config

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
evmosd start --pruning=nothing $TRACE --log_level $LOGLEVEL \
        --minimum-gas-prices=0.000000000000000001aevmos \
        --json-rpc.gas-cap=9999999999999999 \
        --gas-prices=0.00000000000000000000000000000000001aev0mos \
        --gas-adjustment=0.000000000000000000000000001 \
        --json-rpc.api eth,txpool,personal,net,debug,web3
