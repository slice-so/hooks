// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {OnchainAction, IOnchainAction} from "@/utils/OnchainAction.sol";

abstract contract OnchainActionTest is HookTest {
    function testSupportsInterface_OnchainAction() public view {
        assertTrue(IOnchainAction(hook).supportsInterface(type(IOnchainAction).interfaceId));
    }

    function testRevert_onProductPurchase_NotPurchase() public {
        vm.expectRevert(abi.encodeWithSelector(OnchainAction.NotPurchase.selector));
        IOnchainAction(hook).onProductPurchase(0, 0, address(0), 0, "", "");
    }

    function testRevert_onProductPurchase_WrongSlicer() public {
        uint256 unauthorizedSlicer = OnchainAction(hook).ALLOWED_SLICER_ID() + 1;

        vm.expectRevert(abi.encodeWithSelector(OnchainAction.WrongSlicer.selector));
        vm.prank(address(PRODUCTS_MODULE));
        IOnchainAction(hook).onProductPurchase(unauthorizedSlicer, 0, address(0), 0, "", "");
    }
}
