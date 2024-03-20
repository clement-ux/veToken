// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_Extend_ is Unit_Shared_Test_ {
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
}
