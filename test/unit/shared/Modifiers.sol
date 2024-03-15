// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Base_Test_} from "../../Base.sol";

abstract contract Modifiers is Base_Test_ {
    struct Modifier_Lock {
        uint256 skipBefore;
        address user;
        uint256 amountToLock;
        uint256 duration;
        uint256 skipAfter;
    }

    modifier lock(Modifier_Lock memory _lock) {
        skip(_lock.skipBefore);
        deal(address(govToken), _lock.user, _lock.amountToLock * 1 ether);
        vm.prank(_lock.user);
        tokenLocker.lock(_lock.user, _lock.amountToLock, _lock.duration);
        skip(_lock.skipAfter);
        _;
    }
}
