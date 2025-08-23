// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookRegistryTest} from "./HookRegistryTest.sol";
import {
    RegistryProductAction, IHookRegistry, IProductAction, IProductPrice
} from "@/utils/RegistryProductPriceAction.sol";

abstract contract RegistryProductPriceActionTest is HookRegistryTest {
    function testSupportsInterface_RegistryProductPriceAction() public view {
        assertTrue(IProductAction(hook).supportsInterface(type(IProductAction).interfaceId));
        assertTrue(IProductAction(hook).supportsInterface(type(IProductPrice).interfaceId));
        assertTrue(IProductAction(hook).supportsInterface(type(IHookRegistry).interfaceId));
    }

    function testRevert_onProductPurchase_NotPurchase() public {
        vm.expectRevert(abi.encodeWithSelector(RegistryProductAction.NotPurchase.selector));
        IProductAction(hook).onProductPurchase(0, 0, address(0), 0, "", "");
    }
}
