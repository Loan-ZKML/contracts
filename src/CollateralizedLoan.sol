// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// The borrowed asset is going to be Ether.
// The collateral asset is going to be an ERC-20 token.
//
contract CollateralizedLoan is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}
}
