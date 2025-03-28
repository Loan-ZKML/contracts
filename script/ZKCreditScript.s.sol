// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/CollateralCalculator.sol";
import "../src/ZKCreditVerifier.sol";
import "../src/CreditScoreLoanManager.sol";
import "../src/Halo2Verifier.sol";
import "../src/ICollateralCalculator.sol";

/*
 * ************ Dependency with Anvil running at -----------> http://localhost:8545
 */

contract ZKCreditScript is Script {
    // The test account from proof generation
    address constant TEST_ADDRESS = 0x276ef71c8F12508d187E7D8Fcc2FE6A38a5884B1;
    uint256 constant TEST_PRIVATE_KEY = 0x08c216a5cbe31fd3c8095aae062a101c47c0f6110d738b97c5b1572993a2e665;

    // Anvil's first pre-funded account
    address constant ANVIL_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    // Load and extract both proof and public inputs from calldata.json
    function loadProofAndInputs() internal view returns (bytes memory proof, uint256[] memory publicInputs) {
        // Original implementation unchanged
        bytes memory rawCalldata = vm.readFileBinary("script/calldata.json");
        console2.log("Loaded calldata.json, size:", rawCalldata.length);

        // Extract function selector (first 4 bytes)
        bytes4 selector;
        assembly {
            selector := mload(add(rawCalldata, 32))
            selector := shl(224, shr(224, selector))
        }
        bytes32 selectorBytes;
        assembly {
            selectorBytes := selector
        }
        console2.log("Function selector:");
        console2.logBytes32(selectorBytes);

        // Verify correct function selector
        if (selector != 0x1e8e1e13) {
            console2.log("WARNING: Function selector mismatch, expected 0x1e8e1e13");
            return (hex"", new uint256[](0));
        }

        // Get the offset to the proof data (first parameter)
        uint256 proofOffset;
        assembly {
            proofOffset := mload(add(rawCalldata, 36)) // 32 + 4
        }
        console2.log("Proof offset:", proofOffset);

        // Calculate position of proof length field
        uint256 proofLengthPos = 4 + proofOffset;

        // Get proof length
        uint256 proofLength;
        assembly {
            proofLength := mload(add(rawCalldata, add(32, proofLengthPos)))
        }
        console2.log("Proof length:", proofLength);

        // Extract proof data
        proof = new bytes(proofLength);
        for (uint256 i = 0; i < proofLength; i++) {
            if (proofLengthPos + 32 + i < rawCalldata.length) {
                proof[i] = rawCalldata[proofLengthPos + 32 + i];
            }
        }

        // Get the offset to the public inputs (second parameter)
        uint256 inputsOffset;
        assembly {
            inputsOffset := mload(add(rawCalldata, 68)) // 32 + 4 + 32
        }
        console2.log("Inputs offset:", inputsOffset);

        // Calculate position of inputs length field
        uint256 inputsLengthPos = 4 + inputsOffset;

        // Get inputs length
        uint256 inputsLength;
        assembly {
            inputsLength := mload(add(rawCalldata, add(32, inputsLengthPos)))
        }
        console2.log("Number of public inputs:", inputsLength);

        // Extract public inputs
        publicInputs = new uint256[](inputsLength);
        for (uint256 i = 0; i < inputsLength; i++) {
            uint256 pos = inputsLengthPos + 32 + (i * 32);
            uint256 value;
            assembly {
                value := mload(add(rawCalldata, add(32, pos)))
            }
            publicInputs[i] = value;
            console2.log("Public input", i, ":", value);
        }

        return (proof, publicInputs);
    }

    function run() external {
        // First, use the Anvil account to fund our test address
        console2.log("Step 1: Funding test address from Anvil account");
        vm.startBroadcast(ANVIL_PRIVATE_KEY);

        // Send 1 ETH to model test address to cover gas costs
        payable(TEST_ADDRESS).transfer(1 ether);
        console2.log("Transferred 1 ETH from Anvil account to test address");

        vm.stopBroadcast();

        // proceed with the test using funded address
        console2.log("Step 2: Deploying contracts with test address");
        vm.startBroadcast(TEST_PRIVATE_KEY);

        console2.log("Deploying contracts as:", vm.addr(TEST_PRIVATE_KEY));

        // Deploy contracts
        Halo2Verifier halo2Verifier = new Halo2Verifier();
        console2.log("Deployed Halo2Verifier at:", address(halo2Verifier));

        ZKCreditVerifier zkVerifier = new ZKCreditVerifier(address(halo2Verifier));
        console2.log("Deployed ZKCreditVerifier at:", address(zkVerifier));

        CollateralCalculator calculator = new CollateralCalculator();
        console2.log("Deployed CollateralCalculator at:", address(calculator));

        CreditScoreLoanManager loanManager = new CreditScoreLoanManager(address(zkVerifier), address(calculator));
        console2.log("Deployed ScaledCreditScoreLoanManager at:", address(loanManager));

        // Check initial collateral requirement
        // Get initial collateral requirement struct
        ICollateralCalculator.CollateralRequirement memory initialRequirement =
            calculator.getCollateralRequirement(TEST_ADDRESS, 1 ether);
        console2.log("Initial collateral requirement:");
        console2.log(" - Percentage:", initialRequirement.requiredPercentage);
        console2.log(" - Amount for 1 ETH loan:", initialRequirement.requiredAmount);
        console2.log(" - Tier:", uint8(initialRequirement.tier));

        // Load proof and original public inputs
        (bytes memory proof, uint256[] memory publicInputs) = loadProofAndInputs();

        // Validate we have a proper proof
        if (proof.length == 0) {
            console2.log("Failed to load valid proof, aborting");
            vm.stopBroadcast();
            return;
        }

        // Test direct verification first for debugging
        // Redundant because the loanManager's submitCreditScoreProof()
        // would enforce this
        console2.log("Testing direct verification with Halo2Verifier...");
        try halo2Verifier.verifyProof(proof, publicInputs) returns (bool directResult) {
            console2.log("Direct verification result:", directResult);
        } catch (bytes memory reason) {
            console2.log("Direct verification reverted:");
            console2.logBytes(reason);
        }

        // Log raw credit score
        uint256 rawCreditScore = 0;
        if (publicInputs.length > 0) {
            rawCreditScore = publicInputs[0];
        }
        console2.log("Raw credit score from proof:", rawCreditScore);

        // Calculate descaled credit score (using the same logic as CreditScoreLoanManager)
        uint256 EZKL_BASE_SCALE_NUMERATOR = 67219; // Based on the observed scaling factor
        uint256 EZKL_BASE_SCALE_DENOMINATOR = 1;
        uint256 descaledScore = (rawCreditScore * EZKL_BASE_SCALE_DENOMINATOR) / EZKL_BASE_SCALE_NUMERATOR;
        console2.log("Descaled credit score (0-1000 scale):", descaledScore);
        console2.log("Submitting proof from address:", TEST_ADDRESS);

        // Use the original inputs without modification
        try loanManager.submitCreditScoreProof(proof, publicInputs) returns (bool success) {
            if (success) {
                console2.log("Proof verification successful!");

                // Check updated collateral requirement
                ICollateralCalculator.CollateralRequirement memory newRequirement =
                    calculator.getCollateralRequirement(TEST_ADDRESS, 1 ether);
                console2.log("Updated collateral requirement:");
                console2.log(" - Percentage:", newRequirement.requiredPercentage);
                console2.log(" - Amount for 1 ETH loan:", newRequirement.requiredAmount);
                console2.log(" - Tier:", uint8(newRequirement.tier));

                // Get the stored credit score from the loan manager
                uint256 storedScore = loanManager.getCreditScore(TEST_ADDRESS);
                console2.log("Stored credit score in contract:", storedScore);

                if (newRequirement.requiredPercentage == 10000) {
                    console2.log("Successfully qualified for favorable rate (100% collateral)");
                } else {
                    console2.log("Failed to qualify for favorable rate");
                }
            } else {
                console2.log("Proof verification failed");
            }
        } catch (bytes memory reason) {
            console2.log("Proof submission reverted:");
            console2.logBytes(reason);
        }

        vm.stopBroadcast();
    }
}
