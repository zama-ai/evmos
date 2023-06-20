TRACE=""
LOGLEVEL="info"

# Recompile, if needed.
COSMOS_BUILD_OPTIONS=nostrip make install

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
evmosd start --pruning=nothing $TRACE --log_level $LOGLEVEL \
        --minimum-gas-prices=0.0001aevmos \
        --json-rpc.gas-cap=50000000 \
        --json-rpc.api eth,txpool,net,web3
