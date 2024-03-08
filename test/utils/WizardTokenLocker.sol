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
    uint256 public constant TOTAL_DECAY_RATE_SLOT_REF = 0;
    uint256 public constant TOTAL_UPDATED_EPOCH_SLOT_REF = 0;

    uint256 public constant TOTAL_EPOCH_WEIGHTS_ARRAY_SLOT_REF = 1;
    uint256 public constant TOTAL_EPOCH_UNLOCKS_ARRAY_SLOT_REF = 10924;

    uint256 public constant ACCOUNT_EPOCH_WEIGHTS_MAPPING_SLOT_REF = 19116;
    uint256 public constant ACCOUNT_EPOCH_UNLOCK_MAPPING_SLOT_REF = 19117;
    uint256 public constant ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF = 19118;

    /// @notice Get the total decay rate by slot reading from the storage
    function getTotalDecayRateBySlotReading(Vm vm, address _contract) public view returns (uint32) {
        return
            uint32(uint256(vm.load(address(_contract), bytes32(TOTAL_DECAY_RATE_SLOT_REF)) << (256 - 40) >> (256 - 32)));
    }

    /// @notice Get the total updated epoch by slot reading from the storage
    function getTotalUpdateEpochBySlotReading(Vm vm, address _contract) public view returns (uint16) {
        return uint16(
            uint256(vm.load(address(_contract), bytes32(TOTAL_UPDATED_EPOCH_SLOT_REF)) << (256 - 56) >> (256 - 16))
        );
    }

    /// @notice Get the total epoch weight by slot reading from the storage
    function getTotalEpochWeightBySlotReading(Vm vm, address _contract, uint256 _epoch) public view returns (uint32) {
        uint256 valuePerSlot = 6; // How many uint32 fit in a slot? 256 / 40 = 6.
        uint256 level = _epoch / valuePerSlot;
        bytes32 slot = bytes32(TOTAL_EPOCH_WEIGHTS_ARRAY_SLOT_REF + level);
        uint256 offSet = _epoch % valuePerSlot + 1;
        bytes32 data = vm.load(address(_contract), slot);
        return uint32(uint256((data << (256 - offSet * 40) >> (256 - 40))));
    }

    /// @notice Get the total epoch unlock by slot reading from the storage
    function getTotalEpochUnlockBySlotReading(Vm vm, address _contract, uint256 _epoch) public view returns (uint32) {
        uint256 valuePerSlot = 8; // How many uint32 fit in a slot? 256 / 32 = 8.
        uint256 level = _epoch / valuePerSlot;
        bytes32 slot = bytes32(TOTAL_EPOCH_UNLOCKS_ARRAY_SLOT_REF + level);
        uint256 offSet = _epoch % valuePerSlot + 1;
        bytes32 data = vm.load(address(_contract), slot);
        return uint32(uint256((data << (256 - offSet * 32) >> (256 - 32))));
    }

    /// @notice Get the account epoch weights by slot reading from the storage
    function getAccountEpochWeightsBySlotReading(Vm vm, address _contract, address _account, uint256 _epoch)
        public
        view
        returns (uint32)
    {
        bytes32 slot = SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_EPOCH_WEIGHTS_MAPPING_SLOT_REF);
        uint256 valuePerSlot = 6; // How many uint32 fit in a slot? 256 / 40 = 6.
        uint256 level = _epoch / valuePerSlot;
        slot = bytes32(uint256(slot) + level);
        uint256 offSet = _epoch % valuePerSlot + 1;
        bytes32 data = vm.load(address(_contract), slot);
        return uint32(uint256((data << (256 - offSet * 40) >> (256 - 40))));
    }

    /// @notice Get the account epoch unlocks by slot reading from the storage
    function getAccountEpochUnlocksBySlotReading(Vm vm, address _contract, address _account, uint256 _epoch)
        public
        view
        returns (uint32)
    {
        bytes32 slot = SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_EPOCH_UNLOCK_MAPPING_SLOT_REF);
        uint256 valuePerSlot = 8; // How many uint32 fit in a slot? 256 / 32 = 8.
        uint256 level = _epoch / valuePerSlot;
        slot = bytes32(uint256(slot) + level);
        uint256 offSet = _epoch % valuePerSlot + 1;
        bytes32 data = vm.load(address(_contract), slot);
        return uint32(uint256((data << (256 - offSet * 32) >> (256 - 32))));
    }

    /// @notice Get the amount locked for an account by slot reading from the storage
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
