// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookRegistryTest} from "./HookRegistryTest.sol";
import {IHookRegistry, IPricingStrategy} from "@/utils/RegistryPricingStrategy.sol";

abstract contract RegistryPricingStrategyTest is HookRegistryTest {
    function testSupportsInterface_RegistryPricingStrategy() public view {
        assertTrue(IPricingStrategy(hook).supportsInterface(type(IPricingStrategy).interfaceId));
        assertTrue(IPricingStrategy(hook).supportsInterface(type(IHookRegistry).interfaceId));
    }
}
