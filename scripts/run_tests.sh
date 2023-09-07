#!/bin/bash

cp .env.example .env
docker exec -i evmosnodelocal0 faucet $(npx hardhat task:getEthereumAddress)
sleep 8
docker exec -i evmosnodelocal0 faucet $(npx hardhat accounts | grep 0x |  sed -n '2p')
sleep 8
docker exec -i evmosnodelocal0 faucet $(npx hardhat accounts | grep 0x |  sed -n '3p')
npm test
