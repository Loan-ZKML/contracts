// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {CollateralizedLoan} from "../src/CollateralizedLoan.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol"; // Adjust the import path as necessary

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    // myLoanInfo()
    // -----------------------------

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

    function test_requestLoan_whenContractDoesNotHaveEnoughEther_itReverts() public {
        address borrower = makeAddr("panos");
        uint256 borrowedAmount = 30 ether;
        uint256 collateralAmount = borrowedAmount + (borrowedAmount * MIN_COLLATERALIZATION_RATIO) / 100;

        // fire
        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(CollateralizedLoan.LenderDoesNotHaveEnoughEtherError.selector, borrowedAmount, 0)
        );
        s_loan.requestLoan(borrowedAmount, collateralAmount);
    }

    function test_requestLoan_whenBorrowerDoesNotHaveEnoughCollateral_itReverts() public {
        address borrower = makeAddr("panos");
        uint256 borrowedAmount = 30 ether;
        uint256 collateralAmount = borrowedAmount + (borrowedAmount * MIN_COLLATERALIZATION_RATIO) / 100;
        vm.deal(address(s_loan), borrowedAmount);

        // fire
        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                CollateralizedLoan.BorrowerDoesNotHaveEnoughCollateralError.selector, borrower, collateralAmount, 0
            )
        );
        s_loan.requestLoan(borrowedAmount, collateralAmount);
    }

    function test_requestLoan_whenBorrowerHasNotApprovedContractToGetCollateralFromTheirAccount_itReverts() public {
        address borrower = makeAddr("panos");
        uint256 borrowedAmount = 30 ether;
        uint256 collateralAmount = borrowedAmount + (borrowedAmount * MIN_COLLATERALIZATION_RATIO) / 100;
        vm.deal(address(s_loan), borrowedAmount);
        s_collateralToken.mint(borrower, collateralAmount);

        // fire
        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector, address(s_loan), 0, collateralAmount
            )
        );
        s_loan.requestLoan(borrowedAmount, collateralAmount);
    }

    function test_requestLoan_movesMoneyAcrossBorrowerAndLoanContract() public {
        address borrower = makeAddr("panos");
        uint256 borrowedAmount = 30 ether;
        uint256 collateralAmount = borrowedAmount + (borrowedAmount * MIN_COLLATERALIZATION_RATIO) / 100;
        vm.deal(address(s_loan), borrowedAmount);
        s_collateralToken.mint(borrower, collateralAmount);
        vm.prank(borrower);
        s_collateralToken.approve(address(s_loan), collateralAmount);

        uint256 loanEtherBalanceBefore = address(s_loan).balance;
        uint256 borrowerEtherBalanceBefore = borrower.balance;
        uint256 loanCollateralBalanceBefore = s_collateralToken.balanceOf(address(s_loan));
        uint256 borrowerCollateralBalanceBefore = s_collateralToken.balanceOf(borrower);

        // fire
        vm.prank(borrower);

        vm.expectEmit(true, true, false, true, address(s_collateralToken));
        emit IERC20.Transfer(borrower, address(s_loan), collateralAmount);

        vm.expectEmit(true, false, false, true, address(s_loan));
        emit CollateralizedLoan.LoanGranted(borrower, borrowedAmount, collateralAmount);

        s_loan.requestLoan(borrowedAmount, collateralAmount);
        // -----

        uint256 loanEtherBalanceAfter = address(s_loan).balance;
        assertEq(loanEtherBalanceAfter, loanEtherBalanceBefore - borrowedAmount);

        uint256 borrowerEtherBalanceAfter = borrower.balance;
        assertEq(borrowerEtherBalanceAfter, borrowerEtherBalanceBefore + borrowedAmount);

        uint256 loanCollateralBalanceAfter = s_collateralToken.balanceOf(address(s_loan));
        assertEq(loanCollateralBalanceAfter, loanCollateralBalanceBefore + collateralAmount);

        uint256 borrowerCollateralBalanceAfter = s_collateralToken.balanceOf(borrower);
        assertEq(borrowerCollateralBalanceAfter, borrowerCollateralBalanceBefore - collateralAmount);

        vm.prank(borrower);
        CollateralizedLoan.LoanInfo memory loanInfo;
        loanInfo = s_loan.myLoanInfo();

        assertEq(loanInfo.borrower, borrower);
        assertEq(loanInfo.borrowedAmount, borrowedAmount);
        assertEq(loanInfo.collateralAmount, collateralAmount);
        assertEq(loanInfo.requestedAt, block.timestamp);
        assertEq(loanInfo.paid, false);
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
