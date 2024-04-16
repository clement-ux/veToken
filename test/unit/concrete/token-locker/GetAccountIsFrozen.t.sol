// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_GetAccountIsFrozen_ is Unit_Shared_Test_ {
    function test_GetAccountIsFrozen_WhenTrue()
        public
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        assertTrue(tokenLocker.getAccountIsFrozen(address(this)));
    }

    function test_GetAccountIsFrozen_WhenFalse() public {
        assertFalse(tokenLocker.getAccountIsFrozen(address(this)));
    }
}
