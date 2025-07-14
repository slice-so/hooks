// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {IHookRegistry} from "@/utils/RegistryPricingStrategy.sol";

abstract contract HookRegistryTest is HookTest {
    // TODO:
    function testParamsSchema() public view {
        string memory schema = IHookRegistry(hook).paramsSchema();
        assertTrue(bytes(schema).length > 0);
    }
}
