// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ICollateralCalculator.sol";

contract CollateralCalculator is ICollateralCalculator {
    // Mapping of addresses to their collateral tier
    mapping(address => CreditTier) private addressTiers;

    // Get the collateral requirement for a borrower
    function getCollateralRequirement(address borrower, uint256 loanAmount)
        external
        view
        returns (CollateralRequirement memory)
    {
        // default case
        CollateralRequirement memory requirement = CollateralRequirement({
            requiredPercentage: 15000, // 150% in basis points
            requiredAmount: (loanAmount * 150) / 100,
            tier: addressTiers[borrower]
        });

        // Check if the borrower has a favorable tier
        if (requirement.tier == CreditTier.FAVORABLE) {
            requirement.requiredPercentage = 10000; // 100% in basis points
            requirement.requiredAmount = loanAmount;
        }

        return requirement;
    }

    // Update a borrower's tier based on their verified credit score
    function updateTier(address borrower, uint256 creditScore, bool proofValidated)
        public
        returns (CreditTier)
    {
        require(proofValidated, "Invalid proof");

        // Simplified logic: If score > 0.5 (500 in scaled range), set favorable tier
        CreditTier newTier =
            (creditScore > 500) ? CreditTier.FAVORABLE : CreditTier.UNKNOWN;

        // Update the borrower's tier
        addressTiers[borrower] = newTier;

        return newTier;
    }

    // Get the current tier for a borrower
    function getTier(address borrower) external view returns (CreditTier) {
        return addressTiers[borrower];
    }
}
