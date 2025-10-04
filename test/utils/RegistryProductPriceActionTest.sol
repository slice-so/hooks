// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ProductHookRegistryTest} from "./ProductHookRegistryTest.sol";
import {
    RegistryProductPriceAction,
    RegistryProductAction,
    IProductHookRegistry,
    IProductAction,
    IProductPrice
} from "@/utils/RegistryProductPriceAction.sol";

abstract contract RegistryProductPriceActionTest is ProductHookRegistryTest {
    function testSupportsInterface_RegistryProductPriceAction() public view {
        assertTrue(IProductAction(hook).supportsInterface(type(IProductAction).interfaceId));
        assertTrue(IProductAction(hook).supportsInterface(type(IProductPrice).interfaceId));
        assertTrue(IProductAction(hook).supportsInterface(type(IProductHookRegistry).interfaceId));
    }

    function testRevert_onProductPurchase_NotPurchase() public {
        vm.expectRevert(abi.encodeWithSelector(RegistryProductAction.NotPurchase.selector));
        IProductAction(hook).onProductPurchase(0, 0, 0, address(0), 0, "");
    }
}
