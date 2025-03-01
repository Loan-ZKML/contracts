// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {CollateralizedLoan} from "../src/CollateralizedLoan.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CollateralizedLoanTest is Test {
    CollateralizedLoan loan;
    IERC20 collateralToken;

    function setUp() public {
        collateralToken = new ERC20Mock();
        loan = new CollateralizedLoan(msg.sender, collateralToken);
    }

    // -------
    // Ownable
    // -------
    function test_ownerIsTheDeployer() public view {
        assertEq(address(loan.owner()), address(msg.sender));
    }

    // ----------------
    // collateralToken
    // ----------------
    function test_onDeploymentWeSetPublicCollateralERC20Token() public view {
        assertEq(address(loan.collateralToken()), address(collateralToken));
    }
}
