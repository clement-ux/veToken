// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreOwner} from "../../../../contracts/CoreOwner.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_CoreOwner_CommitTransferOwnership_ is Unit_Shared_Test_ {
    function test_RevertWhen_CommitTransferOwnership_WhenNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Only owner");
        coreOwner.commitTransferOwnership(address(0x1));
    }

    function test_CommitTransferOwnership_WhenOwner() public {
        address newOwner = makeAddr("newOwner");

        // Assertions Before
        assertEq(coreOwner.pendingOwner(), address(0));
        assertEq(coreOwner.ownershipTransferDeadline(), 0);

        address currentOwner = coreOwner.owner();
        uint256 transferDelay = coreOwner.OWNERSHIP_TRANSFER_DELAY();
        vm.prank(currentOwner);
        vm.expectEmit({emitter: address(coreOwner)});
        emit CoreOwner.NewOwnerCommitted(currentOwner, newOwner, block.timestamp + transferDelay);

        // Main call
        coreOwner.commitTransferOwnership(newOwner);

        // Assertions After
        assertEq(coreOwner.pendingOwner(), newOwner);
        assertEq(coreOwner.ownershipTransferDeadline(), block.timestamp + transferDelay);
    }
}
