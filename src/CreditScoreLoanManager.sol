// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CollateralCalculator.sol";
import "./ZKCreditVerifier.sol";
import "./ICreditScoreLoanManager.sol";
import "forge-std/console2.sol";

/**
 * @title CreditScoreLoanManager
 * @dev Manages credit scoring using EZKL zero-knowledge proofs to determine loan collateral requirements
 */
contract CreditScoreLoanManager is ICreditScoreLoanManager {
    // ======== Constants ========

    /// @dev Scaling factor for EZKL output conversion
    /// EZKL uses multiple layers of scaling:
    /// Initial quantization: When EZKL processes an ML model, it first quantizes floating-point values using parameters like input_scale and param_scale.
    /// EZKL then runs a calibration process (via calibrate_settings) to optimize circuit parameters, which affects how values are represented internally.
    /// During proof generation, EZKL automatically handles scale adjustments to ensure values remain within appropriate ranges for the circuit.
    uint256 private constant EZKL_SCALING_FACTOR = 67219;

    /// @dev Contract scaling value - determines when a score needs rescaling
    uint256 private constant CONTRACT_SCALE = 1e18;

    /// @dev Maximum value for human-readable credit score
    uint256 private constant MAX_CREDIT_SCORE = 1000;

    /// @dev Threshold score to qualify for favorable credit tier
    uint256 private constant FAVORABLE_CREDIT_THRESHOLD = 500;

    // ======== State Variables ========

    /// @dev Reference to the collateral calculator contract
    CollateralCalculator public immutable calculator;

    /// @dev Reference to the zero-knowledge verifier contract
    ZKCreditVerifier public immutable zkVerifier;

    /// @dev Maps proof hashes to addresses that used them (prevents proof reuse by different addresses)
    mapping(bytes32 => address) public proofUsers;

    /// @dev Maps borrower addresses to their verified credit tiers
    mapping(address => ICollateralCalculator.CreditTier) public borrowerTiers;

    /// @dev Maps borrower addresses to their credit scores (0-1000 range)
    mapping(address => uint256) private creditScores;

    constructor(address _zkVerifier, address _calculator) {
        zkVerifier = ZKCreditVerifier(_zkVerifier);
        calculator = CollateralCalculator(_calculator);
    }

    /**
     * @dev Submit a credit score ZK proof to update borrower's credit tier
     * @param _proof The zkSNARK proof bytes
     * @param _publicInputs Array of public inputs to the proof
     * @return True if proof verification and update was successful
     */
    function submitCreditScoreProof(bytes calldata _proof, uint256[] calldata _publicInputs) external returns (bool) {
        // Verify the proof is valid - using original unmodified inputs
        bool isValid = zkVerifier.verifyProof(_proof, _publicInputs);
        require(isValid, "Invalid proof");

        // Extract raw credit score from public inputs
        require(_publicInputs.length > 0, "Missing credit score input");
        uint256 rawCreditScore = _publicInputs[0];

        // Scale the credit score appropriately
        uint256 scaledCreditScore = scaleScore(rawCreditScore);

        // Store credit score
        creditScores[msg.sender] = scaledCreditScore;

        // Store proof hash to prevent reuse
        bytes32 proofHash = keccak256(_proof);

        // Check if this proof has been used before by a different address
        if (proofUsers[proofHash] != address(0) && proofUsers[proofHash] != msg.sender) {
            emit ProofAlreadyUsed(msg.sender, proofUsers[proofHash], proofHash);
            revert("Proof already used by another address");
        }

        // Register this proof as used by this address
        proofUsers[proofHash] = msg.sender;

        // Determine tier based on scaled credit score
        ICollateralCalculator.CreditTier tier = scaledCreditScore > FAVORABLE_CREDIT_THRESHOLD
            ? ICollateralCalculator.CreditTier.FAVORABLE
            : ICollateralCalculator.CreditTier.UNKNOWN;

        // Store the borrower's tier
        borrowerTiers[msg.sender] = tier;

        // Update calculator
        calculator.updateTier(msg.sender, scaledCreditScore, true);

        // Emit event for credit score validation
        emit CreditScoreValidated(msg.sender, uint256(tier), proofHash);

        return true;
    }

    /**
     * @dev Scale the raw credit score from EZKL format to contract format
     * @param _rawScore The raw score from EZKL (can be large)
     * @return The scaled score in 0-1000 range
     */
    function scaleScore(uint256 _rawScore) public pure returns (uint256) {
        // Determine if the score needs scaling
        if (_rawScore > CONTRACT_SCALE) {
            // Scale the score down to 0-1000 range
            uint256 scaledScore = (_rawScore * MAX_CREDIT_SCORE) / EZKL_SCALING_FACTOR;

            // Cap it at MAX_CREDIT_SCORE for safety
            return scaledScore > MAX_CREDIT_SCORE ? MAX_CREDIT_SCORE : scaledScore;
        } else {
            // Already in the correct range
            return _rawScore;
        }
    }

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
        returns (uint256 amount, uint256 percentage)
    {
        ICollateralCalculator.CollateralRequirement memory req =
            calculator.getCollateralRequirement(_borrower, _loanAmount);

        return (req.requiredAmount, req.requiredPercentage);
    }

    /**
     * @dev Get the borrower's credit tier
     * @param _borrower Address of the borrower
     * @return Credit tier of the borrower
     */
    function getBorrowerTier(address _borrower) external view returns (ICollateralCalculator.CreditTier) {
        return borrowerTiers[_borrower];
    }

    /**
     * @dev Get the credit score for a borrower
     * @param _borrower Address of the borrower
     * @return Credit score of the borrower (0-1000 range)
     */
    function getCreditScore(address _borrower) external view returns (uint256) {
        return creditScores[_borrower];
    }
}
