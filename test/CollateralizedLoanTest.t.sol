// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {CollateralizedLoan} from "../src/CollateralizedLoan.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CollateralizedLoanTest is Test {
    // -------
    // Ownable
    // -------
    function test_ownerIsTheDeployer() public {
        IERC20 collateralToken = new ERC20Mock();

        CollateralizedLoan load = new CollateralizedLoan(
            msg.sender,
            collateralToken
        );

        assertEq(address(load.owner()), address(msg.sender));
    }

    // ----------------
    // collateralToken
    // ----------------
    function test_onDeploymentWeSetPublicCollateralERC20Token() public {
        address initialOwner = makeAddr("panos");
        IERC20 erc20Token = new ERC20Mock();

        CollateralizedLoan loan = new CollateralizedLoan(
            initialOwner,
            erc20Token
        );

        assertEq(address(loan.collateralToken()), address(erc20Token));
    }
}
