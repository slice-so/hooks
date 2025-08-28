// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {HookRegistryTest} from "./HookRegistryTest.sol";
import {RegistryProductAction, IHookRegistry, IProductAction} from "@/utils/RegistryProductAction.sol";

abstract contract RegistryProductActionTest is HookRegistryTest {
    function testSupportsInterface_RegistryProductAction() public view {
        assertTrue(IProductAction(hook).supportsInterface(type(IProductAction).interfaceId));
        assertTrue(IProductAction(hook).supportsInterface(type(IHookRegistry).interfaceId));
    }

    function testRevert_onProductPurchase_NotPurchase() public {
        vm.expectRevert(abi.encodeWithSelector(RegistryProductAction.NotPurchase.selector));
        IProductAction(hook).onProductPurchase(0, 0, address(0), 0, "", "");
    }
}
