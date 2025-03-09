// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ICollateralCalculator} from "./ICollateralCalculator.sol";

/**
 * @title CollateralCalculator
 * @dev Calculates required loan collateral based on credit score
 * This contract is used to calculate the required collateral for a loan based on the borrower's credit score.
 * The credit score is verified on-chain with another smart contract (to be provided) and passed to this contract to calculate the required collateral.
 * The required collateral is calculated as a percentage of the loan amount based on the borrower's credit tier.
 *
 */
contract CollateralCalculator is ICollateralCalculator {
    mapping(address borrower => CreditTier creditTier) private s_borrowerCreditTiers;

    uint8[4] private s_creditTierCollateralPercentages = [
        120, // 120 %
        100, // 100 %
        90, // 90 %
        80 // 80 %
    ];

    // ------------------
    // external
    // ------------------

    /*
     * This should only be called by the Smart Contract that delivers the Loan, i.e. by the +CollateralizedLoan+ Smart Contract.
     */
    function updateCreditScore(address _borrower, uint256 _creditScore, bool _proofValidated) external {
        CreditTier newTier;

        if (!_proofValidated) {
            newTier = CreditTier.UNKNOWN;
        } else {
            if (_creditScore < 400) {
                // _creditScore < 400
                newTier = CreditTier.LOW;
            } else if (_creditScore < 700) {
                // 400 <= _creditScore < 700
                newTier = CreditTier.MEDIUM;
            } else {
                // > 0.7
                newTier = CreditTier.HIGH;
            }
        }

        s_borrowerCreditTiers[_borrower] = newTier;

        emit CreditScoreUpdated(_borrower, _creditScore, newTier);
    }

    // ------------------
    // external view
    // ------------------

    function getBorrowerCreditTier(address _borrower) external view override returns (CreditTier) {
        return s_borrowerCreditTiers[_borrower];
    }

    /**
     * TODO: We will see how: This may be called only by the +CollateralizedLoan+ Smart Contract.
     */
    function getCollateralRequirement(address _borrower, uint256 _loanAmount)
        external
        view
        override
        returns (CollateralRequirement memory)
    {
        // Get borrower credit tier
        CreditTier tier = s_borrowerCreditTiers[_borrower];

        // Get required collateral percentage for that tier
        uint8 requiredPercentage = s_creditTierCollateralPercentages[uint256(tier)];

        // Calculate required collateral amount
        uint256 requiredAmount = calculateRequiredAmount(_loanAmount, requiredPercentage);

        return CollateralRequirement(requiredPercentage, requiredAmount, tier);
    }

    // ------------------
    // internal
    // ------------------
    function calculateRequiredAmount(uint256 _loanAmount, uint256 _requiredPercentage)
        internal
        pure
        returns (uint256)
    {
        return (_loanAmount * _requiredPercentage) / 100;
    }
}
