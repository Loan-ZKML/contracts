#!/bin/bash
# Causes an exit if the Foundry process (which executes the ZKCreditScript.s.sol smart contract as a script) 
# generates a non-zero return code (error).
set -e

# Foundry executes ZKCreditScript.s.sol smart contract as a script
# Anvil must be running
forge script script/ZKCreditScript.s.sol --rpc-url anvil --broadcast
