// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {ProductAction, IProductAction} from "@/utils/ProductAction.sol";

abstract contract ProductActionTest is HookTest {
    function testSupportsInterface_ProductAction() public view {
        assertTrue(IProductAction(hook).supportsInterface(type(IProductAction).interfaceId));
    }

    function testRevert_onProductPurchase_NotPurchase() public {
        vm.expectRevert(abi.encodeWithSelector(ProductAction.NotPurchase.selector));
        IProductAction(hook).onProductPurchase(0, 0, address(0), 0, "", "");
    }

    function testRevert_onProductPurchase_WrongSlicer() public {
        uint256 unauthorizedSlicer = ProductAction(hook).ALLOWED_SLICER_ID() + 1;

        vm.expectRevert(abi.encodeWithSelector(ProductAction.WrongSlicer.selector));
        vm.prank(address(PRODUCTS_MODULE));
        IProductAction(hook).onProductPurchase(unauthorizedSlicer, 0, address(0), 0, "", "");
    }
}
