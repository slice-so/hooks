// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ProductOnchainActionTest} from "./ProductOnchainActionTest.sol";
import {IOnchainAction, IProductOnchainAction} from "@/utils/OnchainAction.sol";

abstract contract OnchainActionTest is ProductOnchainActionTest {
    function testSupportsInterface_OnchainAction() public view {
        assertTrue(IOnchainAction(hook).supportsInterface(type(IOnchainAction).interfaceId));
    }

    // TODO:
    function testActionParamsSchema() public {
        string memory schema = IOnchainAction(hook).actionParamsSchema();
        assertTrue(bytes(schema).length > 0);
    }
}
