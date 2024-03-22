// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_LockMany_ is Unit_Shared_Test_ {
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

        deal(address(govToken), address(this), 1_000_000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_LockMany_Because_Frozen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        vm.expectRevert("Lock is frozen");
        tokenLocker.lockMany(address(this), new TokenLocker.LockData[](0));
    }

    function test_RevertWhen_LockMany_Because_OneAmountIsZero() public {
        vm.expectRevert("Amount must be nonzero");
        tokenLocker.lockMany(address(this), new TokenLocker.LockData[](1));
    }

    function test_RevertWhen_LockMany_Because_OneEpochIsZero() public {
        TokenLocker.LockData[] memory locks = new TokenLocker.LockData[](1);
        locks[0] = TokenLocker.LockData({amount: 1, epochsToUnlock: 0});
        vm.expectRevert("Min 1 epoch");
        tokenLocker.lockMany(address(this), locks);
    }

    function test_RevertWhen_LockMany_Because_OneEpochIsGreaterThanToMax() public {
        TokenLocker.LockData[] memory locks = new TokenLocker.LockData[](1);
        locks[0] = TokenLocker.LockData({amount: 1, epochsToUnlock: tokenLocker.MAX_LOCK_EPOCHS() + 1});
        vm.expectRevert("Exceeds MAX_LOCK_EPOCHS");
        tokenLocker.lockMany(address(this), locks);
    }

    function test_RevertWhen_LockMany_Because_NotEnoughtToken() public {
        deal(address(govToken), address(this), 0);
        TokenLocker.LockData[] memory locks = new TokenLocker.LockData[](1);
        locks[0] = TokenLocker.LockData({amount: 1, epochsToUnlock: 1});
        vm.expectRevert(
            abi.encodePacked(IERC20Errors.ERC20InsufficientBalance.selector, abi.encode(address(this), 0, 1 ether))
        );
        tokenLocker.lockMany(address(this), locks);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test 2 locks at the same time on the final half of the epoch
    /// The 2 locks should overlap.
    function test_LockMany_2Locks_FirstEpoch_OneOnTheFinalHalfOfTheEpoch() public {
        TokenLocker.LockData[] memory locks = new TokenLocker.LockData[](2);
        locks[0] = TokenLocker.LockData({amount: 1, epochsToUnlock: 1});
        locks[1] = TokenLocker.LockData({amount: 1, epochsToUnlock: 2});

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksCreated(address(this), locks);
        tokenLocker.lockMany(address(this), locks);

        // Assertions after
        uint256 unlockEpoch = 2;
        uint256 currentEpoch = 0;
        uint256 amountLocked = 2;
        uint256 weight = amountLocked * 2;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLocked);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch - 1), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch), amountLocked);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch - 1), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch), amountLocked);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLocked);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch - 1), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch), true);
    }

    /// @notice Test 2 locks at the same time on the final half of the epoch
    /// The 2 locks should not overlap.
    function test_LockMany_2Locks_FirstEpoch_NotInTheFinalHalfOfTheEpoch() public {
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;

        TokenLocker.LockData[] memory locks = new TokenLocker.LockData[](2);
        locks[0] = TokenLocker.LockData({amount: 1, epochsToUnlock: 1});
        locks[1] = TokenLocker.LockData({amount: 1, epochsToUnlock: 2});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 1;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksCreated(address(this), locks);
        tokenLocker.lockMany(address(this), locks);

        // Assertions after
        uint256 unlockEpoch = 3;
        uint256 amountLocked = 2;
        uint256 weight = WizardTokenLocker.getWeightForManyLock(locks);
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLocked);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch - 1), amountLocked / 2);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch), amountLocked / 2);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch - 1),
            amountLocked / 2
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch), amountLocked / 2
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLocked);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch - 1), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lock 1 token for 5 epochs.
    /// - Timejump to epoch 6.
    /// - Lock 1 token for 2 epochs and 2 token for 3 epochs.
    function test_LockMany_2Locks_GreaterThanWithPreviousLock_WhenUnlockHappen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
    {
        // No need to add assertions before as exactly the same as the test `Unit_Concrete_TokenLocker_Extend_::test_Extend_All_RightAfterLocking()`.
        uint256 amountLockBefore = 1;
        uint256 unlockTimestampBefore = 5;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;

        TokenLocker.LockData[] memory locks = new TokenLocker.LockData[](2);
        locks[0] = TokenLocker.LockData({amount: 1, epochsToUnlock: 2});
        locks[1] = TokenLocker.LockData({amount: 2, epochsToUnlock: 3});
        uint256 totalAmountLocked = locks[0].amount + locks[1].amount;

        // Start at the beginning of next epoch
        uint256 epochToSkip = 6;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        deal(address(govToken), address(this), totalAmountLocked * 1 ether);
        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksCreated(address(this), locks);
        tokenLocker.lockMany(address(this), locks);

        // Assertions after
        uint256 unlockEpoch1 = epochToSkip + locks[0].epochsToUnlock;
        uint256 unlockEpoch2 = epochToSkip + locks[1].epochsToUnlock;
        uint256 weight = WizardTokenLocker.getWeightForManyLock(locks);
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalAmountLocked);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch1 - 1), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch1), locks[0].amount);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch2), locks[1].amount);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch - 2), 1);
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch - 1), 0);
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            amountLockBefore
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch1), locks[0].amount
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch2), locks[1].amount
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalAmountLocked);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch1), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch2), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lock 1 token for 5 epochs.
    /// - Timejump to epoch 2.
    /// - Lock 1 token for 2 epochs and 1 token for 4 epochs.
    function test_LockMany_2Locks_LowerAndGreaterThanWithPreviousLock_WhenUnlockNotHappen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
    {
        // No need to add assertions before as exactly the same as the test `Unit_Concrete_TokenLocker_Extend_::test_Extend_All_RightAfterLocking()`.

        uint256 amountLockBefore = 1;
        uint256 unlockTimestampBefore = 5;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength; // 0

        TokenLocker.LockData[] memory locks = new TokenLocker.LockData[](2);
        locks[0] = TokenLocker.LockData({amount: 1, epochsToUnlock: 2});
        locks[1] = TokenLocker.LockData({amount: 2, epochsToUnlock: 4});
        uint256 totalAmountLocked = locks[0].amount + locks[1].amount;

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip; // 2

        deal(address(govToken), address(this), totalAmountLocked * 1 ether);
        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksCreated(address(this), locks);
        tokenLocker.lockMany(address(this), locks);

        // Assertions after
        uint256 unlockEpoch1 = epochToSkip + locks[0].epochsToUnlock;
        uint256 unlockEpoch2 = epochToSkip + locks[1].epochsToUnlock;
        uint256 weight =
            WizardTokenLocker.getWeightForManyLock(locks) + amountLockBefore * (unlockTimestampBefore - currentEpoch);
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalAmountLocked + amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore), amountLockBefore);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch1), locks[0].amount);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch2), locks[1].amount);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), amountLockBefore * unlockTimestampBefore);
        assertEq(
            vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 1), amountLockBefore * (unlockTimestampBefore - 1)
        );
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0),
            amountLockBefore * unlockTimestampBefore
        );
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 1),
            amountLockBefore * (unlockTimestampBefore - 1)
        );
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch1), locks[0].amount
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            amountLockBefore
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch2), locks[1].amount
        );
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalAmountLocked + amountLockBefore
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch1), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch2), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lock 1 token for 5 epochs.
    /// - Timejump to epoch 2.
    /// - Lock 1 token for 1 epochs and 2 token for 2 epochs.
    function test_LockMany_2Locks_LowerThanWithPreviousLock_WhenUnlockNotHappen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
    {
        // No need to add assertions before as exactly the same as the test `Unit_Concrete_TokenLocker_Extend_::test_Extend_All_RightAfterLocking()`.

        uint256 amountLockBefore = 1;
        uint256 unlockTimestampBefore = 5;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength; // 0

        TokenLocker.LockData[] memory locks = new TokenLocker.LockData[](2);
        locks[0] = TokenLocker.LockData({amount: 1, epochsToUnlock: 1});
        locks[1] = TokenLocker.LockData({amount: 2, epochsToUnlock: 2});
        uint256 totalAmountLocked = locks[0].amount + locks[1].amount;

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip; // 2

        deal(address(govToken), address(this), totalAmountLocked * 1 ether);
        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksCreated(address(this), locks);
        tokenLocker.lockMany(address(this), locks);

        // Assertions after
        uint256 unlockEpoch1 = epochToSkip + locks[0].epochsToUnlock;
        uint256 unlockEpoch2 = epochToSkip + locks[1].epochsToUnlock;
        uint256 weight =
            WizardTokenLocker.getWeightForManyLock(locks) + amountLockBefore * (unlockTimestampBefore - currentEpoch);
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalAmountLocked + amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore), amountLockBefore);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch1), locks[0].amount);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch2), locks[1].amount);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), amountLockBefore * unlockTimestampBefore);
        assertEq(
            vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 1), amountLockBefore * (unlockTimestampBefore - 1)
        );
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0),
            amountLockBefore * unlockTimestampBefore
        );
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 1),
            amountLockBefore * (unlockTimestampBefore - 1)
        );
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            amountLockBefore
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch1), locks[0].amount
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch2), locks[1].amount
        );
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalAmountLocked + amountLockBefore
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch1), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch2), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lock 1 token for 5 epochs.
    /// - Timejump to epoch 1.
    /// - Lock 1 token for 4 epochs and 2 token for 4 epochs.
    /// This should result into 4 tokens locked until epoch 5.
    function test_LockMany_2Locks_BothOnAlreadyExistingLock_OneEpochAfterFirstLock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
    {
        // No need to add assertions before as exactly the same as the test `Unit_Concrete_TokenLocker_Extend_::test_Extend_All_RightAfterLocking()`.
        uint256 amountLockBefore = 1;
        uint256 unlockTimestampBefore = 5;
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;

        TokenLocker.LockData[] memory locks = new TokenLocker.LockData[](2);
        locks[0] = TokenLocker.LockData({amount: 1, epochsToUnlock: 4});
        locks[1] = TokenLocker.LockData({amount: 2, epochsToUnlock: 4});
        uint256 totalAmountLocked = locks[0].amount + locks[1].amount;

        // Start at the beginning of next epoch
        uint256 epochToSkip = 1;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        deal(address(govToken), address(this), totalAmountLocked * 1 ether);

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.LocksCreated(address(this), locks);
        tokenLocker.lockMany(address(this), locks);

        // Assertions after
        uint256 weight =
            WizardTokenLocker.getWeightForManyLock(locks) + amountLockBefore * (unlockTimestampBefore - currentEpoch);

        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalAmountLocked + amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(
            vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore),
            amountLockBefore + totalAmountLocked
        );
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), amountLockBefore * unlockTimestampBefore);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);

        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0),
            amountLockBefore * unlockTimestampBefore
        );
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            amountLockBefore + totalAmountLocked
        );
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalAmountLocked + amountLockBefore
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);
    }
}
