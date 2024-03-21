// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_Extend_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_Extend_Because_Frozen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        vm.expectRevert("Lock is frozen");
        tokenLocker.extendLock(0, 0, 0);
    }

    function test_RevertWhen_Extend_Because_EpochIsZero() public {
        vm.expectRevert("Min 1 epoch");
        tokenLocker.extendLock(0, 0, 0);
    }

    function test_RevertWhen_Extend_Because_NewEpochExceedsMaxEpoch() public {
        uint256 maxEpoch = tokenLocker.MAX_LOCK_EPOCHS();
        vm.expectRevert("Exceeds MAX_LOCK_EPOCHS");
        tokenLocker.extendLock(0, 1, maxEpoch + 1);
    }

    function test_RevertWhen_Extend_Because_NewEpochIsLessThanCurrentEpoch() public {
        vm.expectRevert("newEpochs must be greater than epochs");
        tokenLocker.extendLock(0, 3, 2);
    }

    function test_RevertWhen_Extend_Because_NewEpochIsEqualToCurrentEpoch() public {
        vm.expectRevert("newEpochs must be greater than epochs");
        tokenLocker.extendLock(0, 3, 3);
    }

    function test_RevertWhen_Extend_Because_AmountIsNull() public {
        vm.expectRevert("Amount must be nonzero");
        tokenLocker.extendLock(0, 1, 2);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test the extension of a lock with the total amount, right after locking
    function test_Extend_All_RightAfterLocking()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
    {
        uint256 startTime = coreOwner.START_TIME();
        uint256 epochLength = coreOwner.EPOCH_LENGTH();
        // --- Assertions before --- //
        uint256 amountLockBefore = 1;
        uint256 unlockTimestampBefore = 5;
        uint256 weightBefore = amountLockBefore * unlockTimestampBefore;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore), amountLockBefore);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            amountLockBefore
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 amountToExtend = amountLockBefore;
        uint256 lockExtension = 2;
        uint256 newUnlockTimestamp = unlockTimestampBefore + lockExtension;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        // --- Main call --- //
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LockExtended(address(this), amountToExtend, unlockTimestampBefore, newUnlockTimestamp);
        tokenLocker.extendLock(amountToExtend, unlockTimestampBefore, newUnlockTimestamp);

        // Assertions after
        uint256 weight = amountToExtend * newUnlockTimestamp;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), newUnlockTimestamp), amountToExtend);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), 0);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp),
            amountToExtend
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp), true);
    }

    /// @notice Test the extension of a lock with half the amount, right after locking
    function test_Extend_Half_RightAfterLocking()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2, duration: 5, skipAfter: 0}))
    {
        uint256 startTime = coreOwner.START_TIME();
        uint256 epochLength = coreOwner.EPOCH_LENGTH();
        // --- Assertions before --- //
        uint256 amountLockBefore = 2;
        uint256 unlockTimestampBefore = 5;
        uint256 weightBefore = amountLockBefore * unlockTimestampBefore;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore), amountLockBefore);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            amountLockBefore
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 amountToExtend = amountLockBefore / 2;
        uint256 lockExtension = 2;
        uint256 newUnlockTimestamp = unlockTimestampBefore + lockExtension;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        // --- Main call --- //
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LockExtended(address(this), amountToExtend, unlockTimestampBefore, newUnlockTimestamp);
        tokenLocker.extendLock(amountToExtend, unlockTimestampBefore, newUnlockTimestamp);

        // Assertions after
        uint256 weight =
            amountToExtend * newUnlockTimestamp + (amountLockBefore - amountToExtend) * unlockTimestampBefore;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(
            vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore),
            amountLockBefore - amountToExtend
        );
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), newUnlockTimestamp), amountToExtend);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            (amountLockBefore - amountToExtend)
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp),
            amountToExtend
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp), true);
    }
}
