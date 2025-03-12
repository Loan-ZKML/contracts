// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ICreditScoreLoanManager
 * @dev Combined interface for the main loan manager contract that integrates ZK verification
 * and collateral calculation
 */
interface ICreditScoreLoanManager {
    /**
     * @dev Event emitted when a credit score is validated with ZK proof
     */
    event CreditScoreValidated(address indexed borrower, uint256 creditScoreTier, bytes32 proofHash);

    /**
     * Optional for a more comprehensive credit score implementation
     * @dev Event emitted when a new loan is created
     */
    event LoanCreated(
        address indexed borrower,
        uint256 loanId,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 collateralPercentage
    );

    event ProofAlreadyUsed(address indexed attemptedUser, address indexed originalUser, bytes32 proofHash);

    /**
     * @dev Submit a credit score ZK proof to update borrower's credit tier
     * @param _proof The zkSNARK proof bytes
     * @param _publicInputs Array of public inputs to the proof (may include the borrower's address)
     * @return True if proof verification and update was successful
     */
    function submitCreditScoreProof(bytes calldata _proof, uint256[] calldata _publicInputs) external returns (bool);

    /**
     * @dev Calculate collateral requirement without submitting proof (preview function)
     * @param _borrower Address of the borrower
     * @param _loanAmount Amount of the loan requested
     * @return amount Required collateral amount
     * @return percentage Required collateral percentage
     */
    function calculateCollateralRequirement(address _borrower, uint256 _loanAmount)
        external
        view
        returns (uint256 amount, uint256 percentage);

    /**
     * @dev Request a loan with the current credit score/tier
     * @param _loanAmount Amount of the loan requested
     * @return loanId ID of the created loan
     * @return requiredCollateral Amount of collateral required
     */
    /**
     * enhanced tier
     * function requestLoan(
     *     uint256 _loanAmount
     * ) external returns (uint256 loanId, uint256 requiredCollateral);
     *
     */

    /**
     * @dev Get the borrower's credit tier as verified by zk proofs
     * @param _borrower Address of the borrower
     * @return Credit tier level assigned to the borrower
     */
    /**
     * enhanced tier
     * function getBorrowerCreditTier(
     *     address _borrower
     * ) external view returns (uint256);
     *
     */

    /**
     * @dev Submit collateral and accept loan
     * @param _loanId ID of the loan previously requested
     * @param _collateralAmount Amount of collateral being submitted
     * @return success True if loan acceptance was successful
     */
    /**
     * enhanced tier
     * function acceptLoan(
     *     uint256 _loanId,
     *     uint256 _collateralAmount
     * ) external returns (bool success);
     *
     */
}
