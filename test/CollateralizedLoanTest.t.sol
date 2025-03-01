// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {CollateralizedLoan} from "../src/CollateralizedLoan.sol";
import {Test, console} from "forge-std/Test.sol";

contract CollateralizedLoanTest is Test {
    // -------
    // Ownable
    // -------
    function test_ownerIsTheDeployer() public {
        CollateralizedLoan load = new CollateralizedLoan(msg.sender);

        assertEq(address(load.owner()), address(msg.sender));
    }
}
