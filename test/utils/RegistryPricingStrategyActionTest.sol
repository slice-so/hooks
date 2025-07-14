// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookRegistryTest} from "./HookRegistryTest.sol";
import {IHookRegistry, IOnchainAction, IPricingStrategy} from "@/utils/RegistryPricingStrategyAction.sol";

abstract contract RegistryPricingStrategyActionTest is HookRegistryTest {
    function testSupportsInterface_RegistryPricingStrategyAction() public view {
        assertTrue(IOnchainAction(hook).supportsInterface(type(IOnchainAction).interfaceId));
        assertTrue(IOnchainAction(hook).supportsInterface(type(IPricingStrategy).interfaceId));
        assertTrue(IOnchainAction(hook).supportsInterface(type(IHookRegistry).interfaceId));
    }
}
