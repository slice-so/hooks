// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookRegistryTest} from "./HookRegistryTest.sol";
import {RegistryOnchainAction, IHookRegistry, IOnchainAction} from "@/utils/RegistryOnchainAction.sol";

abstract contract RegistryOnchainActionTest is HookRegistryTest {
    function testSupportsInterface_RegistryOnchainAction() public view {
        assertTrue(IOnchainAction(hook).supportsInterface(type(IOnchainAction).interfaceId));
        assertTrue(IOnchainAction(hook).supportsInterface(type(IHookRegistry).interfaceId));
    }

    function testRevert_onProductPurchase_NotPurchase() public {
        vm.expectRevert(abi.encodeWithSelector(RegistryOnchainAction.NotPurchase.selector));
        IOnchainAction(hook).onProductPurchase(0, 0, address(0), 0, "", "");
    }
}
