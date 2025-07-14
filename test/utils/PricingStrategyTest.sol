// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {IPricingStrategy} from "@/utils/PricingStrategy.sol";

abstract contract PricingStrategyTest is HookTest {
    function testSupportsInterface_PricingStrategy() public view {
        assertTrue(IPricingStrategy(hook).supportsInterface(type(IPricingStrategy).interfaceId));
    }
}
