// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Base_Test_} from "../../Base.sol";

import {TokenLocker} from "../../../contracts/TokenLocker.sol";

abstract contract Modifiers is Base_Test_ {
    struct Modifier_Lock {
        uint256 skipBefore;
        address user;
        uint256 amountToLock;
        uint256 duration;
        uint256 skipAfter;
    }

    struct Modifier_LockMany {
        uint256 skipBefore;
        address user;
        uint8[5] amountToLock;
        uint8[5] duration;
        uint256 skipAfter;
    }

    struct Modifier_Freeze {
        uint256 skipBefore;
        address user;
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

    modifier lockMany(Modifier_LockMany memory _lockMany) {
        skip(_lockMany.skipBefore);

        // Find correct lenght for the array
        uint256 len;
        for (uint256 i; i < _lockMany.amountToLock.length; i++) {
            if (_lockMany.amountToLock[i] == 0) {
                len = i;
                break;
            }
        }

        TokenLocker.LockData[] memory data = new TokenLocker.LockData[](len);
        uint256 totalAmount;
        for (uint256 i = 0; i < len; i++) {
            uint256 amount = _lockMany.amountToLock[i];

            totalAmount += amount;
            data[i] = TokenLocker.LockData({amount: amount, epochsToUnlock: _lockMany.duration[i]});
        }

        deal(address(govToken), _lockMany.user, totalAmount * 1 ether);
        vm.prank(_lockMany.user);
        tokenLocker.lockMany(_lockMany.user, data);
        skip(_lockMany.skipAfter);
        _;
    }

    modifier freeze(Modifier_Freeze memory _freeze) {
        skip(_freeze.skipBefore);
        vm.prank(_freeze.user);
        tokenLocker.freeze();
        skip(_freeze.skipAfter);
        _;
    }

    modifier enableWithdrawWithPenalty() {
        vm.prank(coreOwner.owner());
        tokenLocker.setPenaltyWithdrawalEnabled(true);
        _;
    }

    modifier disableWithdrawWithPenalty() {
        vm.prank(coreOwner.owner());
        tokenLocker.setPenaltyWithdrawalEnabled(false);
        _;
    }
}
