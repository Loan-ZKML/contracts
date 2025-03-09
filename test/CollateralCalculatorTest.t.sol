// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {CollateralCalculator} from "../src/CollateralCalculator.sol";
import {ICollateralCalculator} from "../src/ICollateralCalculator.sol";

contract CollateralCalculatorTest is Test {
    CollateralCalculator s_collateralCalculator;

    function setUp() public {
        s_collateralCalculator = new CollateralCalculator();
    }

    // ---------------------------------
    // updateCreditScore()
    // ---------------------------------
    function test_updateCreditScore_whenProofIsInvalid_setsCreditTierToUnknown() public {
        address borrower = makeAddr("panos");
        uint256 creditScore = 0;
        bool proofValidated = false;

        // fire
        vm.expectEmit(true, false, false, true, address(s_collateralCalculator));
        emit ICollateralCalculator.CreditScoreUpdated(borrower, creditScore, ICollateralCalculator.CreditTier.UNKNOWN);
        s_collateralCalculator.updateCreditScore(borrower, creditScore, proofValidated);

        // check the credit tier of the borrower
        ICollateralCalculator.CreditTier tier = s_collateralCalculator.getBorrowerCreditTier(borrower);
        assertEq(uint256(tier), uint256(ICollateralCalculator.CreditTier.UNKNOWN));
    }

    function test_updateCreditScore_whenProofIsValidAndCreditScoreLessThan400_setsCreditTierToLow() public {
        address borrower = makeAddr("panos");
        uint256 creditScore = 399;
        bool proofValidated = true;

        // fire
        vm.expectEmit(true, false, false, true, address(s_collateralCalculator));
        emit ICollateralCalculator.CreditScoreUpdated(borrower, creditScore, ICollateralCalculator.CreditTier.LOW);
        s_collateralCalculator.updateCreditScore(borrower, creditScore, proofValidated);

        // check the credit tier of the borrower
        ICollateralCalculator.CreditTier tier = s_collateralCalculator.getBorrowerCreditTier(borrower);
        assertEq(uint256(tier), uint256(ICollateralCalculator.CreditTier.LOW));
    }

    function test_updateCreditScore_whenProofIsValidAndCreditScoreLessThan700_setsCreditTierToMedium() public {
        address borrower = makeAddr("panos");
        uint256 creditScore = 699;
        bool proofValidated = true;

        // fire
        vm.expectEmit(true, false, false, true, address(s_collateralCalculator));
        emit ICollateralCalculator.CreditScoreUpdated(borrower, creditScore, ICollateralCalculator.CreditTier.MEDIUM);
        s_collateralCalculator.updateCreditScore(borrower, creditScore, proofValidated);

        // check the credit tier of the borrower
        ICollateralCalculator.CreditTier tier = s_collateralCalculator.getBorrowerCreditTier(borrower);
        assertEq(uint256(tier), uint256(ICollateralCalculator.CreditTier.MEDIUM));
    }

    function test_updateCreditScore_whenProofIsValidAndCreditScoreGreaterThanOrEqualTo700_setsCreditTierToHigh()
        public
    {
        address borrower = makeAddr("panos");
        uint256 creditScore = 700;
        bool proofValidated = true;

        // fire
        vm.expectEmit(true, false, false, true, address(s_collateralCalculator));
        emit ICollateralCalculator.CreditScoreUpdated(borrower, creditScore, ICollateralCalculator.CreditTier.HIGH);
        s_collateralCalculator.updateCreditScore(borrower, creditScore, proofValidated);

        // check the credit tier of the borrower
        ICollateralCalculator.CreditTier tier = s_collateralCalculator.getBorrowerCreditTier(borrower);
        assertEq(uint256(tier), uint256(ICollateralCalculator.CreditTier.HIGH));
    }

    // ---------------------------------
    // getBorrowerCreditTier()
    // ---------------------------------

    function test_getBorrowerCreditTier_whenBorrowerIsNotRegistered_itReturnsUnknown() public {
        address borrower = makeAddr("panos");

        // fire
        ICollateralCalculator.CreditTier tier = s_collateralCalculator.getBorrowerCreditTier(borrower);

        // check the credit tier of the borrower
        assertEq(uint256(tier), uint256(ICollateralCalculator.CreditTier.UNKNOWN));
    }

    // ------------------------------
    // getCollateralRequirement()
    // ------------------------------

    function test_getCollateralRequirement_whenBorrowerDoesNotHaveCredit_itReturnsAmountWithUnknownTier() public {
        console.log("Testing getCollateralRequirement()");

        // Arrange
        address panos = makeAddr("panos");
        uint256 borrowedAmount = 1_000 ether;

        // Act
        CollateralCalculator.CollateralRequirement memory collateralRequirement =
            s_collateralCalculator.getCollateralRequirement(panos, borrowedAmount);

        // Assert
        assertEq(collateralRequirement.requiredPercentage, 120);
        assertEq(collateralRequirement.requiredAmount, 1_200 ether);
        assertEq(uint256(collateralRequirement.tier), uint256(ICollateralCalculator.CreditTier.UNKNOWN));
    }
}
