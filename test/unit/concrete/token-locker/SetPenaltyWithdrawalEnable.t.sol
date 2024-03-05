// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_TokenLocker_SetPenaltyWithdrawalEnable_ is Unit_Shared_Test_ {
    function test_RevertWhen_SetPenaltyWithdrawalEnabled_Because_NotOwner() public {
        assertNotEq(alice, coreOwner.owner());

        vm.prank(alice);
        vm.expectRevert("Only owner");
        tokenLocker.setPenaltyWithdrawalEnabled(true);
    }

    function test_SetPenaltyWithdrawalEnabled_WhenOwner() public {
        bool statusBefore = tokenLocker.isPenaltyWithdrawalEnabled();

        vm.prank(coreOwner.owner());
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLocker.PenaltyWithdrawalSet(!statusBefore);
        bool success = tokenLocker.setPenaltyWithdrawalEnabled(!statusBefore);

        assertTrue(success);
        assertEq(tokenLocker.isPenaltyWithdrawalEnabled(), !statusBefore);
    }
}
