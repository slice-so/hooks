// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {IHookRegistry} from "@/utils/RegistryProductPrice.sol";
import {MockProductsModule} from "./mocks/MockProductsModule.sol";
import {SliceContext} from "@/utils/RegistryProductAction.sol";

abstract contract HookRegistryTest is HookTest {
    function testParamsSchema() public view {
        string memory schema = IHookRegistry(hook).paramsSchema();
        assertTrue(bytes(schema).length > 0);
    }

    function testConfigureProduct_AccessControl() public {
        vm.expectRevert(abi.encodeWithSelector(SliceContext.NotProductOwner.selector));
        IHookRegistry(hook).configureProduct(0, 0, "");
    }

    // TODO: verify paramsSchema effectively corresponds to the params

    // Blocker: generate bytes params based on a generic string schema
    // function generateParamsFromSchema(string memory schema) public returns (bytes memory) {
    //     string[] memory params = vm.split(schema, ",");

    //     // example schema: "(address currency,int128 targetPrice,uint128 min,int256 perTimeUnit)[] linearParams,int256 priceDecayPercent";

    //     for (uint256 i = 0; i < params.length; i++) {
    //         string[] memory keyValue = vm.split(params[i], " ");
    //         //   ...
    //     }
    // }
}
