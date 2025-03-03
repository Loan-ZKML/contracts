#!/usr/bin/env bash

set -euox pipefail
shopt -s globstar

RPC_URL=$1
PRIVATE_KEY=$2

forge create --rpc-url "${RPC_URL}" --private-key "${PRIVATE_KEY}" lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol:ERC20Mock \
  --broadcast
