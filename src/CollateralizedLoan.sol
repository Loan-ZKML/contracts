// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// The borrowed asset is going to be Ether.
// The collateral asset is going to be an ERC-20 token.
//
contract CollateralizedLoan is Ownable {
    struct LoanInfo {
        address borrower;
        uint256 borrowedAmount;
        uint256 collateralAmount;
        uint256 requestedAt;
        bool paid;
        // uint256 amount;
        // uint256 collateral;
        // uint256 interest;
        // uint256 duration;
        // uint256 start;
        // uint256 end;
        // address borrower;
        // address lender;
    }

    IERC20 public collateralToken;

    constructor(
        address initialOwner,
        IERC20 _collateralToken
    ) Ownable(initialOwner) {
        collateralToken = IERC20(_collateralToken);
    }
}
