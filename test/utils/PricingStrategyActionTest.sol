// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HookTest} from "./HookTest.sol";
import {
    OnchainAction, PricingStrategyAction, IOnchainAction, IPricingStrategy
} from "@/utils/PricingStrategyAction.sol";

abstract contract PricingStrategyActionTest is HookTest {
    function testSupportsInterface_PricingStrategyAction() public view {
        assertTrue(PricingStrategyAction(hook).supportsInterface(type(IOnchainAction).interfaceId));
        assertTrue(PricingStrategyAction(hook).supportsInterface(type(IPricingStrategy).interfaceId));
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
