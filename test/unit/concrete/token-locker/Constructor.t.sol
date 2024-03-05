// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {IGovToken} from "../../../../contracts/interfaces/IGovToken.sol";
import {IIncentiveVoting} from "../../../../contracts/interfaces/IIncentiveVoting.sol";
import {DeploymentParams as DP} from "../../../../scripts/DeploymentParams.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_TokenLocker_Constructor_ is Unit_Shared_Test_ {
    function test_RevertWhen_Constructor_Because_TotalSupplyIsTooLarge() public {
        vm.expectRevert("Total supply too large!");
        new TokenLocker(
            address(coreOwner),
            IGovToken(address(govToken)),
            IIncentiveVoting(address(0)), // not used
            DP.LOCK_TO_TOKEN_RATIO / 1e2,
            true
        );
    }

    function test_Constructor_When_TotalSupplyIsNotTooLarge() public {
        new TokenLocker(
            address(coreOwner),
            IGovToken(address(govToken)),
            IIncentiveVoting(address(incentiveVoting)),
            DP.LOCK_TO_TOKEN_RATIO,
            true
        );

        // Core Owner dependency
        assertEq(address(tokenLocker.CORE_OWNER()), address(coreOwner));
        assertEq(tokenLocker.owner(), address(coreOwner.owner()));
        assertEq(address(coreOwner.owner()), multisig);

        assertEq(address(tokenLocker.govToken()), address(govToken));
        assertEq(address(tokenLocker.incentiveVoter()), address(incentiveVoting));
        assertEq(tokenLocker.LOCK_TO_TOKEN_RATIO(), DP.LOCK_TO_TOKEN_RATIO);
        assertEq(tokenLocker.isPenaltyWithdrawalEnabled(), true);
    }
}
