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
        return halo2Verifier.verifyProof(_proof, _publicInputs);
    }
    function verifyProofAndExtractScore(bytes calldata _proof, uint256[] calldata _publicInputs)
        external
        returns (bool verified, uint256 creditScore)
    {
