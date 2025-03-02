#!/usr/bin/env bash

set -euox pipefail
shopt -s globstar

RPC_URL=$1
PRIVATE_KEY=$2
INITIAL_OWNER=$3
ERC20_TOKEN=$4
INTEREST_RATE=$5
MIN_COLLATERALIZATION_RATIO=$6

forge create --rpc-url "${RPC_URL}" --private-key "${PRIVATE_KEY}" src/CollateralizedLoan.sol:CollateralizedLoan \
  --broadcast \
  --constructor-args "${INITIAL_OWNER}" "${ERC20_TOKEN}" ${INTEREST_RATE} ${MIN_COLLATERALIZATION_RATIO} \
