// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_Lock_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_Lock_Because_EpochIsNull() public {
        vm.expectRevert("Min 1 epoch");
        tokenLocker.lock(alice, 1, 0);
    }

    function test_RevertWhen_Lock_Because_AmountIsZero() public {
        vm.expectRevert("Amount must be nonzero");
        tokenLocker.lock(alice, 0, 1);
    }

    function test_RevertWhen_Lock_Because_EpochIsGreaterThanMaxEpoch() public {
        uint256 maxEpoch = tokenLocker.MAX_LOCK_EPOCHS();
        vm.expectRevert("Exceeds MAX_LOCK_EPOCHS");
        tokenLocker.lock(alice, 1, maxEpoch + 1);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite: accountEpoch == systemEpoch.
    /// - on getTotalWeightWrite: weight == 0.
    /// - on _lock: block.timestamp is in the final half of the epoch.
    /// - on _lock:  previous == 0. (i.e. there is not lock expiring at the same epoch that user new lock expired).
    function test_Lock_InitialLock_FirstEpoch_InFinalHalfOfEpoch() public {
        // --- Assertions before --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 2), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 0);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 2), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 0), false);

        // --- Main call --- //
        uint256 amountToLock = 1;
        deal(address(govToken), address(this), amountToLock * 1 ether);
        tokenLocker.lock(address(this), amountToLock, 1);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 2), amountToLock);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), amountToLock * 2);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), amountToLock * 2);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 2), amountToLock);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountToLock);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 2), true);
    }

    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite:
    ///     - accountEpoch < systemEpoch.
    ///     - accountData.frozen == 0
    ///     - accountData.locked == 0
    /// - on getTotalWeightWrite: weight == 0.
    /// - on _lock: block.timestamp is not in the final half of the epoch.
    /// - on _lock:  previous == 0. (i.e. there is not lock expiring at the same epoch that user new lock expired).
    function test_Lock_InitialLock_SecondEpoch_NotInFirstHalfOfEpoch() public {
        uint256 startTime = coreOwner.START_TIME();
        uint256 epochLength = coreOwner.EPOCH_LENGTH();

        // --- Assertions before --- //
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch), 0);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 0), false);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 1;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        // --- Main call --- //
        uint256 amountToLock = 1;
        uint256 lockDuration = 2;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock * 1 ether);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch + lockDuration), amountToLock);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), amountToLock * lockDuration);
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch),
            amountToLock * lockDuration
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration),
            amountToLock
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountToLock);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), true
        );
    }

    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite:
    ///     - accountEpoch < systemEpoch.
    ///     - accountData.frozen == 0
    ///     - accountData.locked != 0
    ///     - accountEpoch % 256 != 0
    ///     - bitfield & uint256(1) != 1 always (i.e. not unlocked between old epoch to current epoch)
    /// - on getTotalWeightWrite: weight != 0.
    /// - on _lock: block.timestamp is not in the final half of the epoch.
    /// - on _lock:  previous == 0. (i.e. there is not lock expiring at the same epoch that user new lock expired).
    /// - a 5 week lock is perfomed before the start of the test
    function test_Lock_SecondLock_SecondEpoch_NoUnlockOverlapping() public lock(address(this), 1, 5) {
        uint256 startTime = coreOwner.START_TIME();
        uint256 epochLength = coreOwner.EPOCH_LENGTH();
        uint256 amountLockedBefore = 1;
        uint256 previousLockDuration = 5;

        // --- Assertions before --- //
        uint256 oldEpoch = (block.timestamp - startTime) / epochLength;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 1);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(
            vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch),
            amountLockedBefore * previousLockDuration
        );
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch),
            amountLockedBefore * previousLockDuration
        );
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 3;
        vm.warp(startTime + (oldEpoch + epochToSkip) * epochLength);
        // --- Main call --- //
        uint256 amountToLock = 1;
        uint256 lockDuration = 5;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock * 1 ether);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        uint256 weight = amountLockedBefore * (previousLockDuration - epochToSkip) + amountToLock * lockDuration;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockedBefore + amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch + lockDuration), amountToLock);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration),
            amountToLock
        );
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore + amountToLock
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), previousLockDuration), true);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), true
        );
    }

    modifier lock(address _user, uint256 _amount, uint256 _duration) {
        deal(address(govToken), _user, _amount * 1 ether);
        vm.prank(_user);
        tokenLocker.lock(_user, _amount, _duration);
        _;
    }
}
