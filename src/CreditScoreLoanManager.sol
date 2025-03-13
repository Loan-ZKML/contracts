// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./CollateralCalculator.sol";
import "./ZKCreditVerifier.sol";
import "./ICreditScoreLoanManager.sol";

/**
 * @title CreditScoreLoanManager
 * @dev Variant of CreditScoreLoanManager that handles EZKL's output scaling
 */
contract CreditScoreLoanManager is ICreditScoreLoanManager {
    // Reference to the CollateralCalculator contract
    CollateralCalculator public immutable calculator;

    // Reference to the ZKVerifier contract
    ZKCreditVerifier public immutable zkVerifier;

    // Mapping of proof hashes to addresses that used them
    mapping(bytes32 => address) public proofUsers;

    // Mapping of addresses to their credit tier
    mapping(address => ICollateralCalculator.CreditTier) public borrowerTiers;

    // Constants for scaling
    uint256 private constant EZKL_SCALE = 10000;
    uint256 private constant CONTRACT_SCALE = 1000;

    constructor(address _zkVerifier, address _calculator) {
        zkVerifier = ZKCreditVerifier(_zkVerifier);
        calculator = CollateralCalculator(_calculator);
    }

    /**
     * @dev Submit a credit score ZK proof to update borrower's credit tier
     * @param _proof The zkSNARK proof bytes
     * @param _publicInputs Array of public inputs to the proof (may include the borrower's address)
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

        // Store proof hash to prevent reuse
        bytes32 proofHash = keccak256(_proof);

        // Check if this proof has been used before
        if (proofUsers[proofHash] != address(0) && proofUsers[proofHash] != msg.sender) {
            emit ProofAlreadyUsed(msg.sender, proofUsers[proofHash], proofHash);
            revert("Proof already used by another address");
        }

        // Register this proof as used by this address
        proofUsers[proofHash] = msg.sender;

        // Determine tier based on scaled credit score
        ICollateralCalculator.CreditTier tier;
        if (scaledCreditScore > 500) {
            tier = ICollateralCalculator.CreditTier.FAVORABLE;
        } else {
            tier = ICollateralCalculator.CreditTier.UNKNOWN;
        }

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
            uint256 scaledScore = (_rawScore * CONTRACT_SCALE) / EZKL_SCALE;

            // Cap it at 1000 for safety
            return scaledScore > CONTRACT_SCALE ? CONTRACT_SCALE : scaledScore;
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
        CollateralCalculator.CollateralRequirement memory req =
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
}
