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

```bash
make build
```

<br />
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


### Build with docker

In order to have a clean dev machine, one can build evmosd through docker.
