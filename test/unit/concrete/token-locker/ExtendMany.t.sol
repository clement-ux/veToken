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
}
