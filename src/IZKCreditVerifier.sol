// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IZKCreditVerifier
 * @dev Interface for verifying zero-knowledge proofs of credit scoring
 * Note this contract is presuming the EZKL contract generated interfaces.
 */
interface IZKCreditVerifier {
    /**
     * @dev Verifies a zero-knowledge proof of credit score computation
     * @param _proof The zkSNARK proof bytes
     * @param _publicInputs Array of public inputs to the proof
     * @return True if the proof is valid, false otherwise
     */
    function verifyProof(bytes calldata _proof, uint256[] calldata _publicInputs) external view returns (bool);

    /**
     * @dev Gets the verification key hash used for this verifier
     * @return The hash of the verification key
     */
    function getVerificationKeyHash() external view returns (bytes32);
}
