// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {HookTest} from "./HookTest.sol";
import {IHookRegistry} from "@/utils/RegistryProductPrice.sol";
import {MockProductsModule} from "./mocks/MockProductsModule.sol";
import {SliceContext} from "@/utils/RegistryProductAction.sol";

bytes32 constant PRODUCT_MANAGER_ROLE = bytes32(uint256(0x04));

abstract contract HookRegistryTest is HookTest {
    function testParamsSchema() public view {
        string memory schema = IHookRegistry(hook).configureProductSchema();
        assertTrue(bytes(schema).length > 0);
    }

    function testConfigureProduct_AccessControl() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SliceContext.NotAuthorized.selector,
                bytes32(uint256(1 << 1 | 1 << 3)) /* Role.ADMIN.getMask() | Role.PRODUCT_MANAGER.getMask() */
            )
        );

        IHookRegistry(hook).configureProduct(0, 0, 0, "");
    }

    // TODO: verify configureProductSchema effectively corresponds to the params

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
