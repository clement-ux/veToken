// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreOwner} from "../../../../contracts/CoreOwner.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_CoreOwner_Constructor_ is Unit_Shared_Test_ {
    function test_Constructor_When_EpochIs_GreaterThan_StartOffSet() public {
        // Setup initial timestamp at 10 weeks after 1970-01-01T00:00:00+00:00.
        vm.warp(10 weeks);
        uint256 epochLength = 1 weeks;
        uint256 startOffset = 3 days;

        coreOwner = new CoreOwner(multisig, feeReceiver, epochLength, startOffset);

        assertEq(coreOwner.owner(), multisig);
        assertEq(coreOwner.feeReceiver(), feeReceiver);
        assertEq(coreOwner.EPOCH_LENGTH(), 1 weeks);
        assertEq(coreOwner.START_TIME(), block.timestamp - 3 days);

        // Can be seen as invariant.
        assertGe(coreOwner.START_TIME(), block.timestamp - epochLength, "inv A");
        assertLt(coreOwner.START_TIME(), block.timestamp, "inv B");
    }

    function testFail_Constructor_When_EpochIs_LowerThan_StartOffSet() public {
        // Setup initial timestamp at 10 weeks after 1970-01-01T00:00:00+00:00.
        vm.warp(10 weeks);
        uint256 epochLength = 1 weeks;
        uint256 startOffset = 2 weeks + 3 days;

        coreOwner = new CoreOwner(multisig, feeReceiver, epochLength, startOffset);

        assertEq(coreOwner.owner(), multisig);
        assertEq(coreOwner.feeReceiver(), feeReceiver);
        assertEq(coreOwner.START_TIME(), block.timestamp - (1 weeks + 3 days));
        assertEq(coreOwner.EPOCH_LENGTH(), 1 weeks);

        // Can be seen as invariant.
        assertGe(coreOwner.START_TIME(), block.timestamp - epochLength, "inv A");
        assertLt(coreOwner.START_TIME(), block.timestamp, "inv B");

        // TODO: It could be nice to assert that startOffset is lower than 2*epochLength? 
    }
}
