// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// The borrowed asset is going to be Ether.
// The collateral asset is going to be an ERC-20 token.
// The lender is the Smart Contract itself.
//
contract CollateralizedLoan is Ownable {
    struct LoanInfo {
        address borrower;
        uint256 borrowedAmount;
        uint256 collateralAmount;
        uint256 requestedAt;
        bool paid;
    }
    // uint256 amount;
    // uint256 collateral;
    // uint256 interest;
    // uint256 duration;
    // uint256 start;
    // uint256 end;
    // address borrower;
    // address lender;

    IERC20 s_collateralToken;
    uint256 s_interestRate; // percentage, e.g. 20%. It can be more than 100
    uint256 s_minCollateralizationRatio; // percentage. It can be more than 100

    mapping(address => LoanInfo) s_loans;

    // --------------------------------------
    // Events
    // --------------------------------------
    event LoanGranted(address indexed borrower, uint256 borrowedAmount, uint256 collateralAmount);

    event LoanRepaid(address borrower, uint256 repaidAmount);
    //-----------------------------------------------------------------------

    // --------------------------------------
    // Errors
    // --------------------------------------
    error NotEnoughCollateralProvidedForBorrowedAmountError(
        uint256 borrowedAmountRequested,
        uint256 minCollateralizationRatio,
        uint256 minimumCollateralRequired,
        uint256 collateralProvided
    );

    error LenderDoesNotHaveEnoughEtherError(uint256 amountRequested, uint256 lenderBalance);

    error BorrowerDoesNotHaveEnoughCollateralError(address borrower, uint256 amountRequired, uint256 borrowerBalance);

    error BorrowerHasUnpaidLoanError(address borrower, uint256 borrowedAmount, uint256 requestedAt);

    error SendingEtherFailedError(address sender, address recipient, uint256 value);
    // ----------------------------------------------------

    constructor(
        address _initialOwner,
        IERC20 _collateralToken,
        uint256 _interestRate,
        uint256 _minCollateralizationRatio
    ) Ownable(_initialOwner) {
        s_collateralToken = IERC20(_collateralToken);
        s_interestRate = _interestRate;
        s_minCollateralizationRatio = _minCollateralizationRatio;
    }

    // ----------------------------------------------------------
    // Public View Functions
    // ----------------------------------------------------------
    function collateralToken() public view returns (IERC20) {
        return s_collateralToken;
    }

    function interestRate() public view returns (uint256) {
        return s_interestRate;
    }

    function minimumCollateralRequired(uint256 _borrowedAmount) public view returns (uint256) {
        uint256 l_extraAmountToLiquidate = (_borrowedAmount * s_minCollateralizationRatio) / 100;

        return (_borrowedAmount + l_extraAmountToLiquidate);
    }

    function myLoanInfo() public view returns (LoanInfo memory) {
        return s_loans[msg.sender];
    }

    // ----------------------------------------------------------
    // External Transactions
    // ----------------------------------------------------------

    // The caller is requesting +_borrowedAmount+ of Ether.
    // To get the loan, they send +_collateralAmount+ of the
    // +s_collateralToken+.
    // There is a minimum amount of collateral that they should
    // send. It is equal to the +_borrowedAmount+ increased by
    // its +s_minCollateralizationRatio+.
    //
    function requestLoan(uint256 _borrowedAmount, uint256 _collateralAmount) external {
        LoanInfo storage loanInfo = s_loans[msg.sender];
        if (loanInfo.borrowedAmount > 0 && !loanInfo.paid) {
            revert BorrowerHasUnpaidLoanError({
                borrower: msg.sender,
                borrowedAmount: loanInfo.borrowedAmount,
                requestedAt: loanInfo.requestedAt
            });
        }

        uint256 l_minimumCollateralRequired = minimumCollateralRequired(_borrowedAmount);

        if (_collateralAmount < l_minimumCollateralRequired) {
            revert NotEnoughCollateralProvidedForBorrowedAmountError({
                borrowedAmountRequested: _borrowedAmount,
                minCollateralizationRatio: s_minCollateralizationRatio,
                minimumCollateralRequired: l_minimumCollateralRequired,
                collateralProvided: _collateralAmount
            });
        }

        if (address(this).balance < _borrowedAmount) {
            revert LenderDoesNotHaveEnoughEtherError({
                amountRequested: _borrowedAmount,
                lenderBalance: address(this).balance
            });
        }

        uint256 borrowerCollateralBalance = s_collateralToken.balanceOf(msg.sender);

        if (borrowerCollateralBalance < _collateralAmount) {
            revert BorrowerDoesNotHaveEnoughCollateralError({
                borrower: msg.sender,
                amountRequired: _collateralAmount,
                borrowerBalance: borrowerCollateralBalance
            });
        }

        // we take from the borrower and we move Collateral to the contract
        // The +msg.sender+ (the borrower) needs to have approved the +CollateralizedLoan+ to
        // get money/collateralToken from +msg.sender+ and deposit to it itself
        //
        s_collateralToken.transferFrom(msg.sender, address(this), _collateralAmount);

        _sendEthersTo(payable(msg.sender), _borrowedAmount);

        s_loans[msg.sender] = LoanInfo({
            borrower: msg.sender,
            borrowedAmount: _borrowedAmount,
            collateralAmount: _collateralAmount,
            requestedAt: block.timestamp,
            paid: false
        });

        emit LoanGranted(msg.sender, _borrowedAmount, _collateralAmount);
    }

    // -------
    // private
    // -------

    function _sendEthersTo(address payable _recipient, uint256 _amount) private {
        (bool sent,) = _recipient.call{value: _amount}("");
        if (!sent) {
            revert SendingEtherFailedError({sender: address(this), recipient: _recipient, value: _amount});
        }
    }
}
