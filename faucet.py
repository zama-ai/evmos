#!/bin/env python3

import sys
import os
import subprocess
import json

if len(sys.argv) < 2:
    print('Pass address for tokens in the first argument')

FAUCET_DEST_ADDRESS = sys.argv[1]
FAUCET_WALLET_NAME = os.getenv('FAUCET_WALLET_NAME', default='mykey1')
FAUCET_AMOUNT = os.getenv('FAUCET_AMOUNT', default='100000000000000000000')
DENOM = os.getenv('DENOM', default='aevmos')

def get_faucet_address():
    addresses = json.loads(subprocess.check_output(['evmosd', '--output=json', 'keys', 'list']))
    for address in addresses:
        if address['name'] == FAUCET_WALLET_NAME:
            return address['address']
    return None

def get_bech32_addr(ethereum_address):
    output = subprocess.check_output(['evmosd', 'debug', 'addr', ethereum_address]).decode('utf-8')
    bech32 = next((x for x in output.splitlines() if x.startswith('Bech32 Acc:')))
    return bech32.split(': ')[1]

faucet_address = get_faucet_address()
if faucet_address is None:
    print('Faucet account not found with name ' + FAUCET_WALLET_NAME)
    os.exit(1)

dst_bech_addr = get_bech32_addr(FAUCET_DEST_ADDRESS)
os.system(f'evmosd --output=json tx bank send {faucet_address} {dst_bech_addr} {FAUCET_AMOUNT}{DENOM} --from {FAUCET_WALLET_NAME} --gas-prices 1{DENOM} -y')
