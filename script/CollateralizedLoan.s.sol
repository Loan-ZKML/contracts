// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Script, console} from "forge-std/Script.sol";
import {CollateralizedLoan} from "../src/CollateralizedLoan.sol";

contract CollateralizedLoanScript is Script {
    uint256 constant LOCAL_ANVIL_CHAIN_ID = 31337;

    function run() public {
        if (localAnvilChainId()) {
            vm.startBroadcast();

            address initialOwner = msg.sender;
            ERC20Mock collateralToken = new ERC20Mock();
            uint256 interestRate = 20;
            uint256 minCollateralizationRatio = 5;

            new CollateralizedLoan(initialOwner, collateralToken, interestRate, minCollateralizationRatio);

            vm.stopBroadcast();
        }
    }

    // ------------------
    // PRIVATE
    // ------------------

    function localAnvilChainId() private view returns (bool) {
        return (block.chainid == LOCAL_ANVIL_CHAIN_ID);
    }
}
