from web3 import Web3
from eth_account import Account
from eth_account.signers.local import LocalAccount
from web3.middleware import construct_sign_and_send_raw_middleware
import secrets

import time

w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545', request_kwargs={'timeout': 600}))

# 1. Install Web3py by doing `pip install web3`.
#
# 2. Deploy the following Solidity contract:
# // SPDX-License-Identifier: BSD-3-Clause-Clear
#
# pragma solidity >=0.7.0 <0.9.0;
#
# import "./Ciphertext.sol";

# contract Store {
#     uint256 public h;
#
#     function verifyAndSaveHandle(bytes calldata v) public {
#         h = Ciphertext.verify(v);
#     }
#
#     function verifyAndReturnHandle(bytes calldata v) public view returns(uint256) {
#         return Ciphertext.verify(v);
#     }
#
#     function reencrypt() public view returns(bytes memory) {
#         return Ciphertext.reencrypt(h);
#     }
# }
#
# 3. Change below address and key to match yours:
contract_address = '0x5194EFcc5066577cbEfDAA893531Fe439808C259'
private_key = '0x' + '5f9b483c977b57f1a539fcf8a4a889b300ab3be0b4f90888aad437f5a68ae076'

# ABI matches contract above.
abi = """
[
	{
		"inputs": [
			{
				"internalType": "bytes",
				"name": "v",
				"type": "bytes"
			}
		],
		"name": "verifyAndSaveHandle",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "h",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "reencrypt",
		"outputs": [
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "bytes",
				"name": "v",
				"type": "bytes"
			}
		],
		"name": "verifyAndReturnHandle",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
]
"""

# Create the contract and make sure we use a middleware to automatically sign calls.
contract = w3.eth.contract(address=contract_address, abi=abi)
account: LocalAccount = Account.from_key(private_key)
w3.middleware_onion.add(construct_sign_and_send_raw_middleware(account))

# Generate input.
input = secrets.token_bytes(1024 * 1024 * 20)
print('Input len =', len(input))
print('\n')

# Send a transaction.
start = time.time()
gas = contract.functions.verifyAndSaveHandle(input).estimate_gas({
    'value': 0,
    'from': account.address
})
print('TX: gas =', gas)
print('TX: estimate_gas took %s seconds' % (time.time() - start))

start = time.time()
tx = contract.functions.verifyAndSaveHandle(input).transact({
    'value': 0,
    'from': account.address
})
print('TX: ID =', tx.hex())
print('TX: transact took %s seconds\n' % (time.time() - start))

time.sleep(10)

start = time.time()
handle = contract.functions.verifyAndReturnHandle(input).call({
    'from': account.address
})
print('CALL: handle =', hex(handle))
print('CALL: call took %s seconds' % (time.time() - start))

start = time.time()
ct = contract.functions.reencrypt().call({
    'from': account.address
})
assert ct == input[0:65544]
print('REENCRYPT: len(ct) =', len(ct))
print('REENCRYPT: call took %s seconds' % (time.time() - start))
