// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {CollateralizedLoan} from "../src/CollateralizedLoan.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract CollateralizedLoanTest is Test {
    CollateralizedLoan s_loan;
    ERC20Mock s_collateralToken;
    uint256 constant INTEREST_RATE = 20; // 20%
    uint256 constant MIN_COLLATERALIZATION_RATIO = 10; // ?

    function setUp() public {
        console.log("CollateralizedLoanTest#setUp(): msg.sender = ", msg.sender);
        console.log("CollateralizedLoanTest#setUp(): address(this) = ", address(this));

        s_collateralToken = new ERC20Mock();
        s_loan = new CollateralizedLoan(msg.sender, s_collateralToken, INTEREST_RATE, MIN_COLLATERALIZATION_RATIO);
    }

    // -------
    // Ownable
    // -------
    function test_ownerIsTheDeployer() public view {
        assertEq(address(s_loan.owner()), address(msg.sender));
    }

    // ------------------
    // collateralToken()
    // ------------------
    function test_onDeploymentWeSetPublicCollateralERC20Token() public view {
        assertEq(address(s_loan.collateralToken()), address(s_collateralToken));
    }

    // -------------
    // interestRate()
    // -------------
    function test_interestRate_returnsTheInterestRate() public view {
        assertEq(s_loan.interestRate(), INTEREST_RATE);
    }

    // ----------------------------
    // minimumCollateralRequired()
    // ----------------------------
    function test_returnsTheMinimumCollateralRequired() public view {
        uint256 borrowedAmount = 100 ether;
        uint256 result = s_loan.minimumCollateralRequired(borrowedAmount);
        uint256 expectedResult = borrowedAmount + (borrowedAmount * MIN_COLLATERALIZATION_RATIO) / 100;

        assertEq(result, expectedResult);
    }

    // -----------------------------
    // requestLoan()
    // -----------------------------
    function test_requestLoan_whenBorrowerHasUnpaidLoan_itReverts() public {
        address borrower = makeAddr("panos");
        (uint256 borrowedAmount, uint256 collateralAmount) = borrowerHasActiveLoan(borrower);

        // fire

        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                CollateralizedLoan.BorrowerHasUnpaidLoanError.selector, borrower, borrowedAmount, block.timestamp
            )
        );
        s_loan.requestLoan(borrowedAmount, collateralAmount);
    }

    function test_requestLoan_whenCollateralAmountIsBelowMinimumRequired_itReverts() public {
        address borrower = makeAddr("panos");
        uint256 borrowedAmountRequested = 30 ether;
        uint256 minCollateralizationRatio = MIN_COLLATERALIZATION_RATIO;
        uint256 minimumCollateralRequired =
            borrowedAmountRequested + (borrowedAmountRequested * minCollateralizationRatio) / 100;
        uint256 collateralProvided = minimumCollateralRequired - 1;

        // fire
        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                CollateralizedLoan.NotEnoughCollateralProvidedForBorrowedAmountError.selector,
                borrowedAmountRequested,
                minCollateralizationRatio,
                minimumCollateralRequired,
                collateralProvided
            )
        );
        s_loan.requestLoan(borrowedAmountRequested, collateralProvided);
    }

    // -----------------------------
    // private utility functions
    // -----------------------------

    function borrowerHasActiveLoan(address _borrower)
        private
        returns (uint256 _borrowedAmount, uint256 _collateralAmount)
    {
        _borrowedAmount = 10 ether;
        _collateralAmount = 30 ether;

        // the lender needs to have enough in order to lend
        vm.deal(address(s_loan), _borrowedAmount);

        // the borrower needs to have enough in order to send collateral
        s_collateralToken.mint(_borrower, _collateralAmount);

        // the borrower needs to have given the CollateralizedLoan
        // smart contract the allowance to transfer collateral from their
        // account to the smart contract account.
        vm.prank(_borrower);
        s_collateralToken.approve(address(s_loan), _collateralAmount);

        vm.prank(_borrower);
        s_loan.requestLoan(_borrowedAmount, _collateralAmount);
    }
}
