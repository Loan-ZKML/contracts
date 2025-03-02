#!/usr/bin/env bash

set -euox pipefail
shopt -s globstar

RPC_URL=$1
PRIVATE_KEY=$2

forge script script/CollateralizedLoan.s.sol --broadcast \
  --rpc-url "${RPC_URL}" --private-key "${PRIVATE_KEY}"
