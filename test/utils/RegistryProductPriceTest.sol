// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {HookRegistryTest} from "./HookRegistryTest.sol";
import {RegistryProductPrice, IHookRegistry, IProductPrice} from "@/utils/RegistryProductPrice.sol";

abstract contract RegistryProductPriceTest is HookRegistryTest {
    function testSupportsInterface_RegistryProductPrice() public view {
        assertTrue(IProductPrice(hook).supportsInterface(type(IProductPrice).interfaceId));
        assertTrue(IProductPrice(hook).supportsInterface(type(IHookRegistry).interfaceId));
    }
}
