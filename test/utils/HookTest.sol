// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {IProductsModule} from "@/utils/ProductAction.sol";
import {MockProductsModule} from "./mocks/MockProductsModule.sol";

abstract contract HookTest is Test {
    IProductsModule public PRODUCTS_MODULE = IProductsModule(address(new MockProductsModule()));

    address constant ETH = address(0);
    address public productOwner = makeAddr("productOwner");
    address public buyer = makeAddr("buyer");
    address public buyer2 = makeAddr("buyer2");
    address public buyer3 = makeAddr("buyer3");
    address public buyer4 = makeAddr("buyer4");
    address public hook;

    function _setHook(address _hookAddress) internal {
        hook = _hookAddress;
    }

    function testSetup_HookInitialized() public view {
        assertTrue(hook != address(0), "Hook address is not set with `_setHook`");
        assertTrue(hook.code.length > 0, "Hook code is not deployed");
    }
}
