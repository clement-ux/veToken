// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {GovToken} from "../../../../contracts/GovToken.sol";
import {DeploymentParams as DP} from "../../../../scripts/DeploymentParams.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_GovToken_Constructor_ is Unit_Shared_Test_ {
    function test_RevertWhen_Constructor_Because_VaultIsAddressNull() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        new GovToken(DP.NAME, DP.SYMBOL, address(0), address(tokenLocker), DP.SUPPLY);
    }

    function test_Constructor_WhenVaultIsNotAddressNull() public {
        vm.expectEmit({emitter: computeAddress(address(this), bytes1(uint8(vm.getNonce(address(this)))))});
        emit IERC20.Transfer(address(0), address(vault), DP.SUPPLY);
        govToken = new GovToken(DP.NAME, DP.SYMBOL, address(vault), address(tokenLocker), DP.SUPPLY);

        assertEq(govToken.tokenLocker(), address(tokenLocker));
        assertEq(govToken.balanceOf(address(vault)), DP.SUPPLY);
        assertEq(govToken.totalSupply(), DP.SUPPLY);
        assertEq(govToken.name(), DP.NAME);
        assertEq(govToken.symbol(), DP.SYMBOL);
        assertEq(govToken.decimals(), 18);
    }
}
