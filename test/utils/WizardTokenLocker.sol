// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {SlotFinder} from "./SlotFinder.sol";

import {TokenLocker} from "../../contracts/TokenLocker.sol";

library WizardTokenLocker {
    /*//////////////////////////////////////////////////////////////
                            SLOT REFERENCES
    //////////////////////////////////////////////////////////////*/
    /// isPenaltyWithdrawalEnabled -|
    /// totalDecayRate -------------|
    /// totalUpdatedEpoch ----------|-> 0
    ///
    /// totalEpochWeights ----------|-> 1 -> 10923 (6 values per slots)
    ///
    /// totalEpochUnlocks ----------|-> 10924 -> 19115 (8 values per slots)
    ///
    /// accountEpochWeights --------|-> 19116
    ///
    /// accountEpochUnlocks --------|-> 19117
    ///
    /// accountLockData ------------|-> 19118

    uint256 public constant TOTAL_DECAY_RATE_SLOT_REF = 0;
    uint256 public constant TOTAL_UPDATED_EPOCH_SLOT_REF = 0;

    uint256 public constant TOTAL_EPOCH_WEIGHTS_ARRAY_SLOT_REF = 1;
    uint256 public constant TOTAL_EPOCH_UNLOCKS_ARRAY_SLOT_REF = 10924;

    uint256 public constant ACCOUNT_EPOCH_WEIGHTS_MAPPING_SLOT_REF = 19116;
    uint256 public constant ACCOUNT_EPOCH_UNLOCK_MAPPING_SLOT_REF = 19117;
    uint256 public constant ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF = 19118;

    /*//////////////////////////////////////////////////////////////
                              TOTAL VALUES
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                             ACCOUNT VALUES
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                           ACCOUTN LOCK DATA
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the amount locked for an account by slot reading from the storage
    function getLockedAmountBySlotReading(Vm vm, address _contract, address _account) public view returns (uint32) {
        return uint32(
            uint256(
                vm.load(
                    address(_contract),
                    SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF)
                ) << (256 - 32) >> (256 - 32)
            )
        );
    }

    /// @notice Get the amount unlocked for an account by slot reading from the storage
    function getUnlockedAmountBySlotReading(Vm vm, address _contract, address _account) public view returns (uint32) {
        return uint32(
            uint256(
                vm.load(
                    address(_contract),
                    SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF)
                ) << (256 - 64) >> (256 - 32)
            )
        );
    }

    /// @notice Get the amount frozen for an account by slot reading from the storage
    function getFrozenAmountBySlotReading(Vm vm, address _contract, address _account) public view returns (uint32) {
        return uint32(
            uint256(
                vm.load(
                    address(_contract),
                    SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF)
                ) << (256 - 96) >> (256 - 32)
            )
        );
    }

    /// @notice Get if the account is frozen by slot reading from the storage
    function getIsFrozenBySlotReading(Vm vm, address _contract, address _account) public view returns (bool) {
        return uint256(
            vm.load(
                address(_contract), SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF)
            ) << (256 - 104) >> (256 - 8)
        ) == uint256(1);
    }

    /// @notice Get the last updated epoch for an account by slot reading from the storage
    function getEpochBySlotReading(Vm vm, address _contract, address _account) public view returns (uint16) {
        return uint16(
            uint256(
                vm.load(
                    address(_contract),
                    SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF)
                ) << (256 - 120) >> (256 - 16)
            )
        );
    }

    /// @notice Get the update epochs by slot reading from the storage, this decode bitfiled to check if the epoch is updated.
    function getUpdateEpochsBySlotReading(Vm vm, address _contract, address _account, uint256 _epoch)
        public
        view
        returns (bool)
    {
        // Need to add 1 to the slot index because the slot return by SlotFinder.getMappingElementSlotIndex is the slot
        // for the packing of `uint32 locked`+ `uint32 unlocked` + `uint32 frozen` + `bool isFrozen` + `uint16 epoch`
        bytes32 firstSlot =
            bytes32(uint256(SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_MAPPING_SLOT_REF)) + 1);

        uint256 valuePerSlot = 256; // How many bit fit in a slot? 256 / 1 = 256.
        uint256 level = _epoch / valuePerSlot;
        bytes32 slot = bytes32(uint256(firstSlot) + level);
        bytes32 data = vm.load(address(_contract), slot);
        uint256 offSet = _epoch % valuePerSlot + 1;
        return (data << (256 - offSet) >> (256 - 1)) == bytes32(uint256(1));
        //return uint256(data) == (uint256(1) << (_epoch % valuePerSlot)); // Both way seems to works.
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the weight increase for many locks
    function getWeightForManyLock(TokenLocker.LockData[] memory locks) public pure returns (uint256) {
        uint256 weight;
        uint256 len = locks.length;
        for (uint256 i; i < len; ++i) {
            weight += locks[i].amount * locks[i].epochsToUnlock;
        }
        return weight;
    }
}
