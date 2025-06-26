// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {IProductOnchainAction} from "@/utils/ProductOnchainAction.sol";

abstract contract ProductOnchainActionTest is HookTest {
    function testSupportsInterface_ProductOnchainAction() public view {
        assertTrue(IProductOnchainAction(hook).supportsInterface(type(IProductOnchainAction).interfaceId));
    }
}
