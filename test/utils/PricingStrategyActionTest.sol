// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {PricingStrategyAction, IOnchainAction, IPricingStrategy} from "@/utils/PricingStrategyAction.sol";

abstract contract PricingStrategyActionTest is HookTest {
    function testSupportsInterface_PricingStrategyAction() public view {
        assertTrue(PricingStrategyAction(hook).supportsInterface(type(IOnchainAction).interfaceId));
        assertTrue(PricingStrategyAction(hook).supportsInterface(type(IPricingStrategy).interfaceId));
    }
}
