// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IProductsModule} from "@/utils/PricingStrategy.sol";

abstract contract HookTest is Test {
    MockProductsModule public mockProductsModule = new MockProductsModule();
    IProductsModule public PRODUCTS_MODULE = IProductsModule(address(mockProductsModule));

    address public hook;

    function _setHook(address _hookAddress) internal {
        hook = _hookAddress;
    }

    function testHookInitialized() public view {
        assertTrue(hook != address(0), "Hook address is not set with `_setHook`");
    }

    // TODO: parse the schema and generate the params
    // function generateParamsFromSchema(string memory schema) public pure returns (bytes memory) {
    // string[] memory params = vm.split(schema, ",");

    // example schema: "(address currency,int128 targetPrice,uint128 min,int256 perTimeUnit)[] linearParams,int256 priceDecayPercent";

    // for (uint256 i = 0; i < params.length; i++) {
    // string[] memory keyValue = vm.split(params[i], " ");
    // ...
    // }
    // }
}

contract MockProductsModule {
    function isProductOwner(uint256, uint256, address account) external pure returns (bool isAllowed) {
        isAllowed = account == address(0);
    }

    function availableUnits(uint256, uint256) external pure returns (uint256 units, bool isInfinite) {
        units = 6392;
        isInfinite = false;
    }
}
