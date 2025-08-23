// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import {IProductsModule} from "@/utils/ProductAction.sol";
import {Test} from "forge-std/Test.sol";

contract MockProductsModule is
    Test // , IProductsModule
{
    function isProductOwner(uint256, uint256, address account) external pure returns (bool isAllowed) {
        isAllowed = account == vm.addr(uint256(keccak256(abi.encodePacked("productOwner"))));
    }

    function basePrice(uint256, uint256, address, uint256)
        external
        pure
        returns (uint256 ethPrice, uint256 currencyPrice)
    {
        ethPrice = 1e16;
        currencyPrice = 100e18;
    }

    function availableUnits(uint256, uint256) external pure returns (uint256 units, bool isInfinite) {
        units = 6392;
        isInfinite = false;
    }
}
