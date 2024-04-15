// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Fuzzing_TokenLocker_WithdrawWithPenalty_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    uint256 internal startTime;
    uint256 internal epochLength;

    function test_Fuzz_WithdrawWithPenalty_ZeroUnlocked_SinglePosition_RightAfterLocking_MaxAmount(uint256 _amount)
        public
        enableWithdrawWithPenalty
    {
        // Bound amount
        _amount = _bound(_amount, 1, govToken.totalSupply() / 1 ether);

        // Lock
        _modifier_lock(
            Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: _amount, duration: 1, skipAfter: 0})
        );

        uint256 balanceBeforeUser = govToken.balanceOf(address(this));
        uint256 balanceBeforeFeeReceiver = govToken.balanceOf(coreOwner.feeReceiver());

        // Withdraw
        (uint256 amountWithdrawn) = tokenLocker.withdrawWithPenalty(MAX);

        // Check
        assertGt(amountWithdrawn, 0, "1");
        assertEq(amountWithdrawn, govToken.balanceOf(address(this)) - balanceBeforeUser, "2");
        assertEq(
            _amount * 1 ether - amountWithdrawn,
            govToken.balanceOf(coreOwner.feeReceiver()) - balanceBeforeFeeReceiver,
            "3"
        );
    }

    function test_Fuzz_WithdrawWithPenalty_ZeroUnlocked_SinglePosition_RightAfterLocking_FixedAmount(
        uint256 _amountToDeposit,
        uint256 _amountToWithdraw
    ) public enableWithdrawWithPenalty {
        // Bound amount to deposit
        _amountToDeposit = _bound(_amountToDeposit, 2, govToken.totalSupply() / 1 ether);

        // Lock
        _modifier_lock(
            Modifier_Lock({
                skipBefore: 0,
                user: address(this),
                amountToLock: _amountToDeposit,
                duration: 1,
                skipAfter: 0
            })
        );

        // Bound amount to withdraw
        _amountToWithdraw = _bound(_amountToWithdraw, 1, _amountToDeposit * 9 / 10);

        uint256 balanceBeforeUser = govToken.balanceOf(address(this));
        uint256 balanceBeforeFeeReceiver = govToken.balanceOf(coreOwner.feeReceiver());

        // Withdraw
        uint256 amountWithdrawn = tokenLocker.withdrawWithPenalty(_amountToWithdraw);
        uint256 penaltyPaid = govToken.balanceOf(coreOwner.feeReceiver()) - balanceBeforeFeeReceiver;

        // Check
        assertGt(penaltyPaid, 0, "1");
        assertGe(amountWithdrawn, penaltyPaid, "2");
        assertEq(amountWithdrawn, govToken.balanceOf(address(this)) - balanceBeforeUser, "3");
        assertLe(penaltyPaid + amountWithdrawn, _amountToDeposit * 1 ether, "4");
    }
}
