// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ProductPricingStrategyTest} from "./ProductPricingStrategyTest.sol";
import {IPricingStrategy} from "@/utils/PricingStrategy.sol";

abstract contract PricingStrategyTest is ProductPricingStrategyTest {
    function testSupportsInterface_PricingStrategy() public view {
        assertTrue(IPricingStrategy(hook).supportsInterface(type(IPricingStrategy).interfaceId));
    }

    // TODO:
    function testPricingParamsSchema() public {
        // assertEq(IPricingStrategy(hook).pricingParamsSchema(), "");
    }
}
