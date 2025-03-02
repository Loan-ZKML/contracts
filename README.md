# Smart Contract Layer (Solidity)
- Base loan management contract
- Collateral tiers
- Integration with ZK verifier

# Development Environment

## `asdf` - 3rd Party Tools Version Manager

**Important:** I have encountered installation problems with `v0.16.x`. So, I have
stayed to `v0.15.x`.

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

## Deployment and Verification of Smart Contract(s)

Start a local chain:

```bash
$ anvil
...
Listening 127.0.0.1:8545

```

### Using `forge create` (not preferred)

Then you can run the following commands to deploy to the local network:

Note: For owner I use the first owner that `anvil` provides me with. Same for private key.

#### Step 1

Deploy the ERCMock contract. Note down its address:

```bash
$ ./fc_deploy_ercmock.sh 'http://127.0.0.1:8545' '0xac..a...private key....80'
```

#### Step 2

Deploy the Collateralized Loan contract:

```bash
$ ./fc_deploy_collateralized_loan.sh 'http://127.0.0.1:8545' '0xac..a...private key....80' '0xf39Fd...an owner...ffFb92266' '0x5Fb...ERC20Mock Address...0aa3' 20 5
```

### Using `forge script`

```bash
$ ./fs_deploy_collateralized_loan.sh 'http://127.0.0.1:8545' '0xac0 private key ae784d7bf4f2ff80'
```
