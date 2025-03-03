#!/usr/bin/env bash

set -euox pipefail
shopt -s globstar

RPC_URL=$1
SENDER=$2
KEYSTORE1=$3
KEYSTORE2=$4

forge script script/ExampleRequestLoan.s.sol \
  --rpc-url "${RPC_URL}" --keystore $HOME/.foundry/keystores/${KEYSTORE1} \
  --keystore $HOME/.foundry/keystores/${KEYSTORE2} \
  --broadcast --sender ${SENDER}
