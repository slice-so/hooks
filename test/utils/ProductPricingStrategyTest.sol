// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {IProductPricingStrategy} from "@/utils/ProductPricingStrategy.sol";

abstract contract ProductPricingStrategyTest is HookTest {
    function testSupportsInterface_ProductPricingStrategy() public view {
        assertTrue(IProductPricingStrategy(hook).supportsInterface(type(IProductPricingStrategy).interfaceId));
    }
}
