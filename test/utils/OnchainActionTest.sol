// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {IOnchainAction} from "@/utils/OnchainAction.sol";

abstract contract OnchainActionTest is HookTest {
    function testSupportsInterface_OnchainAction() public view {
        assertTrue(IOnchainAction(hook).supportsInterface(type(IOnchainAction).interfaceId));
    }
}
