// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SlotFinder} from "./SlotFinder.sol";
import {Vm} from "forge-std/Vm.sol";

library WizardTokenLocker {
    /**
     * Slot Reference:
     *
     * isPenaltyWithdrawalEnabled -|
     * totalDecayRate -------------|
     * totalUpdatedEpoch ----------|-> 0
     *
     * totalEpochWeights ----------|-> 1 -> 10923 (6 values per slots)
     *
     * totalEpochUnlocks ----------|-> 10924 -> 19115 (8 values per slots)
     *
     * accountEpochWeights --------|-> 19116
     *
     * accountEpochUnlocks --------|-> 19117
     *
     * accountLockData ------------|-> 19118
     */
    uint256 public constant ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF = 19118;

    /// @notice Get the value by slot reading from the storage
    function getLockedBySlotReading(Vm vm, address _contract, address _account) public view returns (uint32) {
        return uint32(
            uint256(
                vm.load(
                    address(_contract),
                    SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF)
                ) << (256 - 32) >> (256 - 32)
            )
        );
    }
}
