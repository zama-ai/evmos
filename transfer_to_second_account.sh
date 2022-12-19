ADDRESS_FROM=$(evmosd keys show mykey1 -a)
ADDRESS_TO=$(evmosd keys show mykey2 -a)
evmosd tx bank send $ADDRESS_FROM $ADDRESS_TO 50000000000aevmos --chain-id evmos_9000-1 --keyring-backend test
