// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IZKCreditVerifier.sol";
import "./Halo2Verifier.sol";

/**
 * @title ZKCreditVerifier
 * @dev Implementation of the IZKCreditVerifier interface that uses Halo2Verifier
 * to verify zero-knowledge proofs of credit scores
 */
contract ZKCreditVerifier is IZKCreditVerifier {
    // Reference to the Halo2Verifier contract
    Halo2Verifier public immutable halo2Verifier;

    // Verification key hash for proof validation
    bytes32 private immutable verificationKeyHash;

    constructor(address _halo2Verifier) {
        halo2Verifier = Halo2Verifier(_halo2Verifier);
        // This must match the vk_digest in the Halo2Verifier contract
        verificationKeyHash = 0x26c182c695297802d78de2f6872548ff56eee1276238ee6843abd7143a51f9bb;
    }

    /**
     * @dev Verifies a zero-knowledge proof of credit score computation
     * @param _proof The zkSNARK proof bytes
     * @param _publicInputs Array of public inputs to the proof
     * @return True if the proof is valid, false otherwise
     */
    function verifyProof(bytes calldata _proof, uint256[] calldata _publicInputs)
        external
        override
        returns (bool)
    {
        // Simply delegate to the Halo2Verifier contract
        return halo2Verifier.verifyProof(_proof, _publicInputs);
    }
    
    /**
     * @dev Verifies a zero-knowledge proof and extracts the credit score from public inputs
     * @param _proof The zkSNARK proof bytes
     * @param _publicInputs Array of public inputs to the proof
     * @return verified True if the proof is valid, false otherwise
     * @return creditScore The credit score (first public input) if proof is valid
     */
    function verifyProofAndExtractScore(bytes calldata _proof, uint256[] calldata _publicInputs)
        external
        returns (bool verified, uint256 creditScore)
    {
        require(_publicInputs.length > 0, "Public inputs must include credit score");
        
        verified = halo2Verifier.verifyProof(_proof, _publicInputs);
        
        if (verified) {
            // The first public input is the credit score
            creditScore = _publicInputs[0];
        }
        
        return (verified, creditScore);
    }

    /**
     * @dev Gets the verification key hash used for this verifier
     * @return The hash of the verification key
     */
    function getVerificationKeyHash() external view override returns (bytes32) {
        return verificationKeyHash;
    }
}
