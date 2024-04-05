// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_WithdrawWithPenalty_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    uint256 internal startTime;
    uint256 internal epochLength;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        startTime = coreOwner.START_TIME();
        epochLength = coreOwner.EPOCH_LENGTH();
    }

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_WithdrawWithPenalty_Because_Disable() public disableWithdrawWithPenalty {
        vm.expectRevert("Penalty withdrawals are disabled");
        tokenLocker.withdrawWithPenalty(1);
    }

    function test_RevertWhen_WithdrawWithPenalty_Because_InsufficentBalanceAfterFees()
        public
        enableWithdrawWithPenalty
    {
        vm.expectRevert("Insufficient balance after fees");
        tokenLocker.withdrawWithPenalty(1);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test freeze, Using following conditions:
    /// - Lock 2 token for 5 epochs
    /// - Skip 5 epochs
    /// - Withdraw 1 token with penalty (no penalty at the end)
    function test_WithdrawWithPenalty_When_Unlocked_IsGreaterThan_AmountToWithdraw()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2, duration: 5, skipAfter: 0}))
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // No need to add assertions before as almost the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 5;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), 1 ether);
        tokenLocker.withdrawWithPenalty(1);

        // Assertions
        uint256 weight = 0;
        // Total values - Not updated in this case!
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 2);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 2);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 10);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 1);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Lock 1 token for 5 epochs
    /// - Skip 5 epochs
    /// - Withdraw 1 token with penalty (no penalty at the end)
    function test_WithdrawWithPenalty_When_Unlocked_EqualTo_AmountToWithdraw()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 5;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), 1 ether);
        tokenLocker.withdrawWithPenalty(1);

        // Assertions
        uint256 weight = 0;
        // Total values - Not updated in this case!
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 1);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 5);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
    }
}
