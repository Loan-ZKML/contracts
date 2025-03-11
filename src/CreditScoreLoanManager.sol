// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ICreditScoreLoanManager.sol";
import "./ICollateralCalculator.sol";
import "./IZKCreditVerifier.sol";

/**
 * @title CreditScoreLoanManager
 * @dev Implementation of the ICreditScoreLoanManager interface that manages loan
 * collateral requirements based on verified credit scores
 */
contract CreditScoreLoanManager is ICreditScoreLoanManager {
    // Reference to the CollateralCalculator contract
    ICollateralCalculator public immutable collateralCalculator;

    // Reference to the ZKCreditVerifier contract
    IZKCreditVerifier public immutable zkVerifier;

    // Mapping of proof hashes to addresses that used them
    mapping(bytes32 => address) public proofUsers;

    // Mapping of addresses to their credit tier
    mapping(address => ICollateralCalculator.CreditTier) public borrowerTiers;

    // Event is inherited from ICreditScoreLoanManager

    // Constructor
    constructor(address _zkVerifier, address _collateralCalculator) {
        zkVerifier = IZKCreditVerifier(_zkVerifier);
        collateralCalculator = ICollateralCalculator(_collateralCalculator);
    }

    /**
     * @dev Submit a credit score ZK proof to update borrower's credit tier
     * @param _proof The zkSNARK proof bytes
     * @param _publicInputs Array of public inputs to the proof. _publicInputs[0] is the borrower address, _publicInputs[1] is the credit score (0-1000 scale)
     * @return True if proof verification and update was successful
     */
    function submitCreditScoreProof(
        bytes calldata _proof,
        uint256[] calldata _publicInputs,
        uint256 _creditScoreOutput
    ) external override returns (bool) {
        return _processProof(_proof, _publicInputs, _creditScoreOutput);
    }

    /**
     * @dev Internal function to process the proof verification
     * @param _proof The zkSNARK proof bytes
     * @param _publicInputs Array of public inputs to the proof
     * @param _creditScoreOutput The credit score output to use
     * @return True if proof verification and update was successful
     */
    function _processProof(
        bytes calldata _proof,
        uint256[] calldata _publicInputs,
        uint256 _creditScoreOutput
    ) internal returns (bool) {
        // The borrower is the sender of the transaction
        address borrower = msg.sender;
        
        // Generate proof hash for duplication check
        bytes32 proofHash = keccak256(_proof);
        
        // Check if this proof has been used before
        address originalUser = proofUsers[proofHash];
        if (originalUser != address(0)) {
            emit ProofAlreadyUsed(borrower, originalUser, proofHash);
            revert("Proof already used");
        }
        
        // Verify that the public inputs contain the correct address
        require(borrower == address(uint160(_publicInputs[0])), "Proof not bound to sender");
        
        // Verify the proof is valid and contains at least 2 public inputs
        require(_publicInputs.length >= 2, "Invalid public inputs length");
        bool isValid = zkVerifier.verifyProof(_proof, _publicInputs);
        require(isValid, "Invalid proof");
        
        // Extract credit score from public inputs
        uint256 creditScore = _publicInputs[1];
        
        // Validate credit score range
        require(creditScore <= 1000, "Credit score out of range");
        
        // Store this proof as used
        proofUsers[proofHash] = borrower;
        
        // Determine tier based on credit score
        ICollateralCalculator.CreditTier tier = creditScore > 500 ? 
            ICollateralCalculator.CreditTier.FAVORABLE :
            ICollateralCalculator.CreditTier.UNKNOWN;
        
        // Store the borrower's tier
        borrowerTiers[borrower] = tier;
        
        // Use the credit score output as tier value for the event
        uint256 tierValue = _creditScoreOutput;
        
        // Emit event for credit score validation
        emit CreditScoreValidated(borrower, tierValue, proofHash);
        
        return true;
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
        override
        returns (uint256 amount, uint256 percentage)
    {
        ICollateralCalculator.CollateralRequirement memory req =
            collateralCalculator.getCollateralRequirement(_borrower, _loanAmount);

        return (req.requiredAmount, req.requiredPercentage);
    }
}
