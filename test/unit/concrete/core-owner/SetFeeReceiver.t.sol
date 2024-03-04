// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreOwner} from "../../../../contracts/CoreOwner.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_CoreOwner_SetFeeReceiver_ is Unit_Shared_Test_ {
    function test_RevertWhen_SetFeeReceiver_WhenNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Only owner");
        coreOwner.setFeeReceiver(address(0x1));
    }

    function test_SetFeeReceiver_WhenOwner() public {
        address newFeeReceiver = makeAddr("newFeeReceiver");

        // Assertions Before
        assertNotEq(coreOwner.feeReceiver(), newFeeReceiver);

        vm.prank(coreOwner.owner());
        vm.expectEmit({emitter: address(coreOwner)});
        emit CoreOwner.FeeReceiverSet(newFeeReceiver);

        // Main call
        coreOwner.setFeeReceiver(newFeeReceiver);

        // Assertions After
        assertEq(coreOwner.feeReceiver(), newFeeReceiver);
    }
}
