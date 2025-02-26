// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ICreditScoreLoanManager.sol";
import "./ICollateralCalculator.sol";

/**
 * @title IEnhancedLoanManager
 * @dev Extended interface for a full-featured loan management system
 */
interface IEnhancedLoanManager is ICreditScoreLoanManager {
    /**
     * @dev Enum representing loan statuses
     */
    enum LoanStatus {
        PENDING,    // Loan created but not yet funded
        ACTIVE,     // Loan is active
        OVERDUE,    // Loan has missed payments
        LIQUIDATED, // Loan was liquidated due to insufficient collateral
        REPAID      // Loan was fully repaid
    }

    /**
     * @dev Struct containing loan details
     */
    struct Loan {
        uint256 id;
        address borrower;
        uint256 principal;
        uint256 collateralAmount;
        uint256 collateralPercentage; // In basis points (8000 = 80%)
        uint256 interestRate;         // In basis points (500 = 5%)
        uint256 startTime;
        uint256 duration;             // In seconds
        uint256 lastPaymentTime;
        uint256 amountRepaid;
        LoanStatus status;
        ICollateralCalculator.CreditTier tier;
    }

    /**
     * @dev Event emitted when a loan payment is made
     */
    event LoanPayment(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 amountPaid,
        uint256 remainingPrincipal
    );

    /**
     * @dev Event emitted when a loan is liquidated
     */
    event LoanLiquidated(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 collateralLiquidated,
        address liquidator
    );

    /**
     * @dev Event emitted when a loan is fully repaid
     */
    event LoanRepaid(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 totalPaid,
        uint256 collateralReturned
    );

    /**
     * @dev Request a loan with a ZK proof to update credit score in one transaction
     * @param _loanAmount Amount of the loan requested
     * @param _duration Duration of the loan in seconds
     * @param _proof The zkSNARK proof bytes
     * @param _publicInputs Array of public inputs to the proof
     * @param _creditScoreOutput The credit score resulting from the computation
     * @return loanId ID of the created loan
     * @return requiredCollateral Amount of collateral required
     */
    function requestLoanWithProof(
        uint256 _loanAmount,
        uint256 _duration,
        bytes calldata _proof,
        uint256[] calldata _publicInputs,
        uint256 _creditScoreOutput
    ) external returns (uint256 loanId, uint256 requiredCollateral);

    /**
     * @dev Deposit collateral and activate a pending loan
     * @param _loanId ID of the pending loan
     */
    function depositCollateralAndActivate(uint256 _loanId) external payable;

    /**
     * @dev Make a payment on an active loan
     * @param _loanId ID of the loan
     * @param _paymentAmount Amount to pay
     * @return remainingPrincipal Remaining principal after payment
     */
    function makePayment(uint256 _loanId, uint256 _paymentAmount) external returns (uint256 remainingPrincipal);

    /**
     * @dev Early repayment of an active loan
     * @param _loanId ID of the loan
     * @return collateralReturned Amount of collateral returned
     */
    function repayLoan(uint256 _loanId) external returns (uint256 collateralReturned);

    /**
     * @dev Get loan details
     * @param _loanId ID of the loan
     * @return Loan struct with all loan details
     */
    function getLoan(uint256 _loanId) external view returns (Loan memory);

    /**
     * @dev Get all loans for a borrower
     * @param _borrower Address of the borrower
     * @return Array of loan IDs for the borrower
     */
    function getBorrowerLoans(address _borrower) external view returns (uint256[] memory);

    /**
     * @dev Check if a loan is eligible for liquidation
     * @param _loanId ID of the loan
     * @return True if loan can be liquidated
     */
    function isEligibleForLiquidation(uint256 _loanId) external view returns (bool);

    /**
     * @dev Liquidate an undercollateralized loan (callable by anyone)
     * @param _loanId ID of the loan
     * @return collateralLiquidated Amount of collateral liquidated
     */
    function liquidateLoan(uint256 _loanId) external returns (uint256 collateralLiquidated);

    /**
     * @dev Add supported collateral token
     * @param _collateralToken Address of the ERC20 token
     * @param _priceFeed Address of the price feed oracle
     * @param _liquidationThreshold Liquidation threshold in basis points (7500 = 75%)
     */
    function addSupportedCollateral(
        address _collateralToken,
        address _priceFeed,
        uint256 _liquidationThreshold
    ) external;

    /**
     * @dev Update interest rates based on credit tier
     * @param _creditTier Credit tier enum value
     * @param _interestRate New interest rate in basis points
     */
    function updateInterestRate(
        ICollateralCalculator.CreditTier _creditTier,
        uint256 _interestRate
    ) external;

    /**
     * @dev Get current interest rate for a credit tier
     * @param _creditTier Credit tier enum value
     * @return interestRate Interest rate in basis points
     */
    function getInterestRate(ICollateralCalculator.CreditTier _creditTier) external view returns (uint256 interestRate);
}