// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_ExtendMany_ is Unit_Shared_Test_ {
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

    function test_RevertWhen_ExtendMany_Because_Frozen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        vm.expectRevert("Lock is frozen");
        tokenLocker.extendMany(new TokenLocker.ExtendLockData[](0));
    }

    function test_RevertWhen_ExtendMany_Because_EpochIsZero() public {
        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](1);
        data[0] = TokenLocker.ExtendLockData({amount: 0, currentEpochs: 0, newEpochs: 0});
        vm.expectRevert("Min 1 epoch");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_DurationIsGreaterThan_MaxLockEpoch() public {
        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](1);
        data[0] =
            TokenLocker.ExtendLockData({amount: 0, currentEpochs: 1, newEpochs: tokenLocker.MAX_LOCK_EPOCHS() + 1});
        vm.expectRevert("Exceeds MAX_LOCK_EPOCHS");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_NewEpochIsLessThanCurrentEpoch() public {
        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](1);
        data[0] = TokenLocker.ExtendLockData({amount: 0, currentEpochs: 1, newEpochs: 0});
        vm.expectRevert("newEpochs must be greater than epochs");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_NewEpochIsEqualToCurrentEpoch() public {
        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](1);
        data[0] = TokenLocker.ExtendLockData({amount: 0, currentEpochs: 1, newEpochs: 1});
        vm.expectRevert("newEpochs must be greater than epochs");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_AmountIsNull() public {
        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](1);
        data[0] = TokenLocker.ExtendLockData({amount: 0, currentEpochs: 1, newEpochs: 2});
        vm.expectRevert("Amount must be nonzero");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_NoLockAtExtendedEpoch() public {
        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](1);
        data[0] = TokenLocker.ExtendLockData({amount: 1, currentEpochs: 1, newEpochs: 2});
        vm.expectRevert(stdError.arithmeticError);
        tokenLocker.extendMany(data);

        // uint256 changedEpoch = systemEpoch + _epochs;
        // uint256 previous = unlocks[changedEpoch];
        // It will revert here because _amount is previous is null
        // unlocks[changedEpoch] = uint32(previous - _amount);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 1 token for 3 epochs and 2 tokens for 5 epochs
    /// - Timejump no epoch
    /// - Extend 1 token unlocking at epoch 3 for 1 epoch and 2 tokens unlocking at epoch 5 for 2 epochs
    function test_ExtendMany_AllPositions_RightAfterLocking()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1, 2, 0, 0, 0],
                duration: [3, 5, 0, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 1 + 2;
        uint256 weightBefore = 1 * 3 + 2 * 5;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);

        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](2);
        data[0] = TokenLocker.ExtendLockData({amount: 1, currentEpochs: 3, newEpochs: 4});
        data[1] = TokenLocker.ExtendLockData({amount: 2, currentEpochs: 5, newEpochs: 7});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 1 * 4 + 2 * 7;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 1);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 2);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch), totalLockedBefore
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 1 token for 3 epochs,  2 tokens for 5 epochs, 3 tokens for 7 epochs
    /// - Timejump no epoch
    /// - Extend 1 token unlocking at epoch 3 for 1 epoch and 3 tokens unlocking at epoch 7 for 2 epochs
    function test_ExtendMany_PartPosition_RightAfterLocking()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1, 2, 3, 0, 0],
                duration: [3, 5, 7, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 1 + 2 + 3;
        uint256 weightBefore = 1 * 3 + 2 * 5 + 3 * 7;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 2);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 3);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 3);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);

        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](2);
        data[0] = TokenLocker.ExtendLockData({amount: 1, currentEpochs: 3, newEpochs: 4});
        data[1] = TokenLocker.ExtendLockData({amount: 3, currentEpochs: 7, newEpochs: 9});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 1 * 4 + 2 * 5 + 3 * 9;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 1);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 2);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 9), 3);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 4), 1);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 9), 3);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 9), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 2 token for 3 epochs and 2 tokens for 5 epochs
    /// - Timejump no epoch
    /// - Extend 1 token unlocking at epoch 3 for 1 epoch and 1 tokens unlocking at epoch 5 for 2 epochs
    function test_ExtendMany_AllPositionsPartially_RightAfterLocking()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [2, 2, 0, 0, 0],
                duration: [3, 5, 0, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 2 + 2;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // No need to add assertions before as exactly the same as the test `test_ExtendMany_AllPositions_RightAfterLocking`

        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](2);
        data[0] = TokenLocker.ExtendLockData({amount: 1, currentEpochs: 3, newEpochs: 4});
        data[1] = TokenLocker.ExtendLockData({amount: 1, currentEpochs: 5, newEpochs: 7});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 1 * 3 + 1 * 4 + 1 * 5 + 1 * 7;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 1);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 1);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 4), 1);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 1);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
        /*
        */
    }

    function test_ExtendMany_AllPositionsPartially_AfterTwoEpochs()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1, 2, 0, 0, 0],
                duration: [3, 5, 0, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 1 + 2;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // No need to add assertions before as exactly the same as the test `test_ExtendMany_AllPositions_RightAfterLocking`

        TokenLocker.ExtendLockData[] memory data = new TokenLocker.ExtendLockData[](2);
        data[0] = TokenLocker.ExtendLockData({amount: 1, currentEpochs: 1, newEpochs: 2});
        data[1] = TokenLocker.ExtendLockData({amount: 1, currentEpochs: 3, newEpochs: 5});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 1 * 2 + 1 * 3 + 1 * 5;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 1);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 1);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 4), 1);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 1);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 6), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
    }
}
