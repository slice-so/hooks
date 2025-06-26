// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {
    ProductPricingStrategyAction,
    IProductOnchainAction,
    IProductPricingStrategy
} from "@/utils/ProductPricingStrategyAction.sol";

abstract contract ProductPricingStrategyActionTest is HookTest {
    function testSupportsInterface_ProductPricingStrategyAction() public view {
        assertTrue(ProductPricingStrategyAction(hook).supportsInterface(type(IProductOnchainAction).interfaceId));
        assertTrue(ProductPricingStrategyAction(hook).supportsInterface(type(IProductPricingStrategy).interfaceId));
    }
}
