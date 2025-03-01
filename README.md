# Smart Contract Layer (Solidity)
- Base loan management contract
- Collateral tiers
- Integration with ZK verifier

# Development Environment

## `asdf` - 3rd Party Tools Version Manager

We are suggesting [asdf](https://asdf-vm.com/) as the version manager for 3rd party tools.
This is an awesome tool that runs on many different platforms and uses one single file to
manage all tools versions. The file is `.tool-versions`.

### Linux

For Linux, I have made sure that I have `go` installed and used the `go` installation
instructions of `asdf` which are given [here](https://asdf-vm.com/guide/getting-started.html#_1-install-asdf).

### Bash Shell

Then on my `.bashrc` I also added the following:

```
export PATH=$HOME/.asdf/shims:$PATH
. <(asdf completion bash)
```

## Foundry (not Hardhat)

**Important**: This is not installed using `asdf`.

We work with [Foundry](https://book.getfoundry.sh/). Please, follow the installation
instructions [here](https://book.getfoundry.sh/getting-started/installation).

We recommend that you install and use the `stable` release of the tools:

I used the following command to install `foundryup`:

```
curl -L https://foundry.paradigm.xyz | bash
```

Then I restarted my shell and used the command:

```
foundryup --install stable
```
