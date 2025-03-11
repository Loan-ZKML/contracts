// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/CollateralCalculator.sol";
import "../src/ICollateralCalculator.sol";
import "../src/ZKCreditVerifier.sol";
import "../src/CreditScoreLoanManager.sol";
import "../src/Halo2Verifier.sol";
import "forge-std/console2.sol";

contract ZKCreditTest is Test {
    Halo2Verifier public halo2Verifier;
    ZKCreditVerifier public zkVerifier;
    CollateralCalculator public calculator;
    CreditScoreLoanManager public loanManager;

    address constant TEST_ADDRESS = 0x276ef71c8F12508d187E7D8Fcc2FE6A38a5884B1;
    uint256 constant TEST_PRIVATE_KEY =
        0x08c216a5cbe31fd3c8095aae062a101c47c0f6110d738b97c5b1572993a2e665;

    // Path to the proof file
    string constant CALLDATA_PATH = "script/calldata.json";

    function setUp() public {
        // Deploy contracts
        halo2Verifier = new Halo2Verifier();
        zkVerifier = new ZKCreditVerifier(address(halo2Verifier));
        calculator = new CollateralCalculator();
        // loanManager = new CreditScoreLoanManager(address(calculator), address(zkVerifier));
    }

    function testDefaultTierIsUnknown() public view {
        ICollateralCalculator.CollateralRequirement memory tier = calculator.getCollateralRequirement(TEST_ADDRESS, 1 ether);        

        assertEq(tier.requiredPercentage, 15000, "Default collateral should be 150%");
        assertEq(tier.requiredAmount, 1.5 ether, "Default collateral amount should be 1.5 ETH for 1 ETH loan");
    }

    function testProof() public {
        // Read the binary calldata file
        bytes memory rawCalldata = vm.readFileBinary("script/calldata.json");

        // Extract function selector (first 4 bytes)
        bytes4 selector;
        assembly {
            selector := mload(add(rawCalldata, 32))
            selector := shl(224, shr(224, selector))
        }

        console.log("Found function selector:");
        console.logBytes4(selector);
        console.log("Expected function selector:");
        console.logBytes4(bytes4(hex"1e8e1e13")); // verifyProof selector

        // Use the address from your generation script
        vm.startPrank(TEST_ADDRESS);

        // Get proof offset
        uint256 proofOffset;
        assembly {
            proofOffset := mload(add(rawCalldata, 36)) // 32 + 4
        }
        console.log("Offset to proof data:", proofOffset);

        // Calculate position of proof length field
        uint256 proofLengthPos = 4 + proofOffset;

        // Get proof length
        uint256 proofLength;
        assembly {
            proofLength := mload(add(rawCalldata, add(32, proofLengthPos)))
        }
        console.log("Proof length from calldata:", proofLength);
        console.log("Expected proof length: 3648");

        // Extract proof data
        bytes memory proof = new bytes(proofLength);
        for (uint256 i = 0; i < proofLength; i++) {
            if (proofLengthPos + 32 + i < rawCalldata.length) {
                proof[i] = rawCalldata[proofLengthPos + 32 + i];
            }
        }

        console.log("Extracted proof length:", proof.length);
        console.log("First bytes of proof:");
        console.logBytes32(bytes32(slice(proof, 0, 32)));

        // Get inputs offset
        uint256 inputsOffset;
        assembly {
            inputsOffset := mload(add(rawCalldata, 68)) // 32 + 4 + 32
        }

        // Calculate position of inputs length field
        uint256 inputsLengthPos = 4 + inputsOffset;

        // Get inputs length
        uint256 inputsLength;
        assembly {
            inputsLength := mload(add(rawCalldata, add(32, inputsLengthPos)))
        }

        // Extract public inputs correctly (fixing the assembly issue)
        uint256[] memory publicInputs = new uint256[](inputsLength);
        for (uint256 i = 0; i < inputsLength; i++) {
            uint256 pos = inputsLengthPos + 32 + (i * 32);
            uint256 value;
            assembly {
                value := mload(add(rawCalldata, add(32, pos)))
            }
            publicInputs[i] = value;
        }

        // bool success = loanManager.submitProof(proof, publicInputs, loanAmount);
        
        // Use zkVerifier for proof verification instead of calculator
        bool verified = zkVerifier.verifyProof(proof, publicInputs);
        assertTrue(verified, "Proof verification should succeed");

        // If verified, update the tier in calculator
        if (verified) {
            calculator.updateTier(TEST_ADDRESS, 600, true); // Use 600 as a test credit score
        }

        // Then check the collateral requirement
        uint256 loanAmount = 600;
        ICollateralCalculator.CollateralRequirement memory tier = calculator.getCollateralRequirement(TEST_ADDRESS, loanAmount);
        assertEq(uint256(tier.tier), uint256(ICollateralCalculator.CreditTier.FAVORABLE), "Borrower should be assigned to FAVORABLE tier");

        vm.stopPrank();
    }

    // Helper function to slice bytes
    function slice(bytes memory data, uint256 start, uint256 length)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            if (start + i < data.length) {
                result[i] = data[start + i];
            }
        }
        return result;
    }
}
