// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {GovToken} from "../../../../contracts/GovToken.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_GovToken_TransferToLocker_ is Unit_Shared_Test_ {
    function test_RevertWhen_TransferToLocker_Because_NotLocker() public {
        vm.expectRevert("Not locker");
        govToken.transferToLocker(address(this), 100);
    }

    function test_TransferToLocker_WhenLocker() public {
        deal(address(govToken), alice, 100);

        vm.prank(address(tokenLocker));
        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(alice, address(tokenLocker), 100);
        bool success = govToken.transferToLocker(alice, 100);

        assertTrue(success);
        assertEq(govToken.balanceOf(alice), 0);
        assertEq(govToken.balanceOf(address(tokenLocker)), 100);
    }
}
