# How to build evmosd binary on your own machine

## Dependencies:

Evmosd binary is compiled based on three other repositories.

### Tfhe-rs

All the tfhe operations are implemented in this repository. As go-ethereum is written in go we are 
calling FHE operations through cgo. So we need to compile a c_api library using this repository.

<br />
<details>
  <summary>Custom repository</summary>

To use an existing repository please update the environment file **.env** with the path to it or export it:
```bash
export TFHE_RS_PATH=../tfhe-rs
```
</details>
<details>
  <summary>Add it for me!</summary>
<br />

If you want to install it automatically, you can override the default tfhe-rs version by setting TFHE_RS_VERSION env variable and running:
```
export TFHE_RS_VERSION=0.2.4
make install-tfhe-rs
```
</details>
<br />

## Build

Once we are sure TFHE_RS_PATH is correct let's build it

### Local build

```bash
make build-local
```

## Using docker

Here are the steps executed automatically:
- Build a base image (or retrieve it from ghcr.io) called __zama-zbc-build__.
  

- Check tfhe-rs is available in TFHE_RS_PATH (default is work_dir/tfhe-rs)
- In any case the custom version or the cloned (TFHE_RS_VERSION) one is copied into work_dir/tfhe-rs
- Clone go-ethereum and ethermint to work_dir (version are parsed from go.mod to avoid handling ssh keys inside docker because those repositories are private)
- Update go.mod to make it use local repositories (related to the just above change)
- Build a docker called __evmosnodelocal__.

```bash
make build-local-docker
```

If everything work correctly you should have:

```bash
ls work_dir/
ethermint  go-ethereum  tfhe-rs
```

And the following images:

```bash
docker images
REPOSITORY       TAG        IMAGE ID       CREATED          SIZE
evmosnodelocal   latest     04a5b55c8d9c   10 minutes ago   2.22GB
zama-zbc-build   latest     c280fb388ab5   12 minutes ago   1.99GB
golang           bullseye   342faadef914   5 days ago       777MB
```

### Check wich version/tag/commit has been used 

```bash
make print-info
GO_ETHEREUM_TAG: v1.0.1-test ---extracted from go.mod
ETHERMINT_TAG: v1.0.0-test ---extracted from go.mod
...

```


<br />
<details>
  <summary>Troubleshoot ghcr.io</summary>

Here is a tutorial on [how to manage ghcr.io access](https://github.com/zama-ai/zbc-fhe-tool#using-the-published-image-easiest-way).

  If you get trouble to pull image from ghcri.io, one can build it locally with
  ```bash
  docker build . -t zama-zbc-build -f docker/Dockerfile.zbc.build
  ```
</details>

<details>
  <summary>Troubleshoot go modules</summary>

Because evmos depends on private [go-ethereum](https://github.com/zama-ai/go-ethereum) and [ethermint](https://github.com/zama-ai/ethermint) repositories, one need to pay attention to two points to allow go modules manager to work correctly.

1. Check that GOPRIVATE is set to __github.com/zama-ai/*__ (normally this env variable is set by default in Makefile)
2. Check you have the following lines in your gitconfig files:

```bash
[url "ssh://git@github.com/"]
        insteadOf = https://github.com/
```
</details>
<br />


## Run e2e test

To be able to run the e2e, first build the evmos local node image explained in the first part. 

```bash
make build-local-docker
```

Then

```bash
make e2e-test-local
```
Every repositories are cloned into **work_dir**.

This test will:
- check you have all the needed repositories
  - zbc-fhe-tool
  - zbc-solidity
  - zbc-development
- init evmos node by calling /config/setup.sh file
- generate fhe keys using zbc-fhe-tool based on $(ZBC_DEVELOPMENT_PATH)/prepare_volumes_from_fhe_tool.sh script
- copy them at the right folder using $(ZBC_DEVELOPMENT_PATH)/prepare_demo_local.sh script
- start validator and oracle db using docker-compose/docker-compose.local.yml file
- run the e2e test 
  - copy pks to encrypt user input using $(ZBC_SOLIDITY_PATH)/prepare_fhe_keys_from_fhe_tool script
  - start the test using $(ZBC_SOLIDITY_PATH)/run_local_test_from_evmos.sh
    - Get the private key of main account 
    - Give it to the python test script $(ZBC_SOLIDITY_PATH)/demo_test_high_level_fhe_tool

