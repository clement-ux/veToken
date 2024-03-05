// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreOwner} from "../../../../contracts/CoreOwner.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_CoreOwner_AcceptTransferOwnership_ is Unit_Shared_Test_ {
    function test_RevertWhen_AcceptTransferOwnership_Because_Owner() public {
        vm.prank(coreOwner.owner());
        vm.expectRevert("Only new owner");
        coreOwner.acceptTransferOwnership();
    }

    function test_RevertWhen_AcceptTransferOwnership_Because_DeadlineNotPassed()
        public
        commitTransferOwnership(alice)
    {
        vm.prank(alice);
        vm.expectRevert("Deadline not passed");
        coreOwner.acceptTransferOwnership();
    }

    function test_RevertWhen_AcceptTransferOwnership_Because_DeadlineJustNotPassed()
        public
        commitTransferOwnership(alice)
    {
        skip(coreOwner.OWNERSHIP_TRANSFER_DELAY() - 1);

        vm.prank(alice);
        vm.expectRevert("Deadline not passed");
        coreOwner.acceptTransferOwnership();
    }

    function test_AcceptTransferOwnership_When_DeadlineExactlyPassed() public commitTransferOwnership(alice) {
        skip(coreOwner.OWNERSHIP_TRANSFER_DELAY());

        // Assertions Before
        address previousOwner = coreOwner.owner();
        assertNotEq(previousOwner, alice);
        assertEq(coreOwner.pendingOwner(), alice);
        assertEq(coreOwner.ownershipTransferDeadline(), block.timestamp);

        vm.prank(alice);
        vm.expectEmit({emitter: address(coreOwner)});
        emit CoreOwner.NewOwnerAccepted(previousOwner, alice);

        // Main call
        coreOwner.acceptTransferOwnership();

        // Assertions After
        assertEq(coreOwner.owner(), alice);
        assertEq(coreOwner.pendingOwner(), address(0));
        assertEq(coreOwner.ownershipTransferDeadline(), 0);
    }

    function test_AcceptTransferOwnership_When_DeadlineWayPassed() public commitTransferOwnership(alice) {
        skip(coreOwner.OWNERSHIP_TRANSFER_DELAY() * 2);

        // Assertions Before
        address previousOwner = coreOwner.owner();
        assertNotEq(previousOwner, alice);
        assertEq(coreOwner.pendingOwner(), alice);
        assertEq(coreOwner.ownershipTransferDeadline(), block.timestamp - coreOwner.OWNERSHIP_TRANSFER_DELAY());

        vm.prank(alice);
        vm.expectEmit({emitter: address(coreOwner)});
        emit CoreOwner.NewOwnerAccepted(previousOwner, alice);

        // Main call
        coreOwner.acceptTransferOwnership();

        // Assertions After
        assertEq(coreOwner.owner(), alice);
        assertEq(coreOwner.pendingOwner(), address(0));
        assertEq(coreOwner.ownershipTransferDeadline(), 0);
    }
}
