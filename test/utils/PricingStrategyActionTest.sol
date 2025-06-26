// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ProductPricingStrategyTest} from "./ProductPricingStrategyTest.sol";
import {PricingStrategyAction, IOnchainAction} from "@/utils/PricingStrategyAction.sol";

abstract contract PricingStrategyActionTest is ProductPricingStrategyTest {
    function testSupportsInterface_PricingStrategyAction() public view {
        assertTrue(PricingStrategyAction(hook).supportsInterface(type(IOnchainAction).interfaceId));
    }

    // TODO:
    function testActionParamsSchema() public {
        // assertEq(IPricingStrategy(hook).pricingParamsSchema(), "");
    }
}
