// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ProductHookRegistryTest} from "./ProductHookRegistryTest.sol";
import {RegistryProductPrice, IProductHookRegistry, IProductPrice} from "@/utils/RegistryProductPrice.sol";

abstract contract RegistryProductPriceTest is ProductHookRegistryTest {
    function testSupportsInterface_RegistryProductPrice() public view {
        assertTrue(IProductPrice(hook).supportsInterface(type(IProductPrice).interfaceId));
        assertTrue(IProductPrice(hook).supportsInterface(type(IProductHookRegistry).interfaceId));
    }
}
