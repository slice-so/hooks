// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {HookTest} from "./HookTest.sol";
import {IProductPrice} from "@/utils/ProductPrice.sol";

abstract contract ProductPriceTest is HookTest {
    function testSupportsInterface_ProductPrice() public view {
        assertTrue(IProductPrice(hook).supportsInterface(type(IProductPrice).interfaceId));
    }
}
