// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.28;

// import {Vm} from "lib/forge-std/src/Vm.sol";

// import {CollateralizedLoan} from "src/CollateralizedLoan.sol";
// import {console} from "forge-std/Test.sol";
// import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// contract ExampleRequestLoan {
//     Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

//     /// @notice REPL contract entry point
//     function run() public {
//         CollateralizedLoan cl = CollateralizedLoan(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
//         address owner = cl.owner();
//         console.log("owner", owner);
//         ERC20Mock collateralToken = ERC20Mock(0x5FbDB2315678afecb367f032d93F642f64180aa3);
//         address borrower = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
//         uint256 minimumCollateral = cl.minimumCollateralRequired(30 ether);

//         vm.startBroadcast();
//         collateralToken.mint(borrower, minimumCollateral);
//         vm.stopBroadcast();

//         vm.startBroadcast(borrower);
//         collateralToken.approve(address(cl), minimumCollateral);
//         cl.requestLoan(30 ether, minimumCollateral);
//         vm.stopBroadcast();
//     }
// }
