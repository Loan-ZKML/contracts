// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ICollateralCalculator
 * @dev Interface for calculating required loan collateral based on credit score
 */
interface ICollateralCalculator {
    /**
     * @dev Enum representing 2 credit score tiers
     */
    enum CreditTier {
        UNKNOWN, // 150% collateral
        FAVORABLE // 100% collateral

    }

    /**
     * @dev Struct containing collateral requirement details
     */
    struct CollateralRequirement {
        uint256 requiredPercentage; // Collateral percentage (in basis points: 8000 = 80%)
        uint256 requiredAmount; // Actual collateral amount required for the requested loan
        // optional enhanced tier
        CreditTier tier; // The credit tier this requirement is based on
    }

    /**
     * @dev Get collateral requirement for a specific address and loan amount
     * @param _borrower Address of the borrower
     * @param _loanAmount Amount of the loan requested
     * @return Collateral requirement details
     */
    function getCollateralRequirement(address _borrower, uint256 _loanAmount)
        external
        view
        returns (CollateralRequirement memory);

    /**
     * @dev Update credit score for an address after verifying ZK proof
     * @param _borrower Address of the borrower
     * @param _creditScore Verified credit score (public output from ZK proof)
     * @param _proofValidated Boolean indicating if the proof was validated
     * @return New credit tier assigned
     */
    /**
     * enhanced tier
     *     function updateCreditScore(
     *         address _borrower,
     *         uint256 _creditScore,
     *         bool _proofValidated
     *     ) external returns (CreditTier);
     */
}
