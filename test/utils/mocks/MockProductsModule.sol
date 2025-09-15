// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// import {IProductsModule} from "@/utils/ProductAction.sol";
import {Price} from "slice/types.sol";
import {Test} from "forge-std/Test.sol";

contract MockProductsModule is
    Test // , IProductsModule
{
    error NotAuthorized(bytes32 rolesMask);

    function checkRoles(uint256, bytes32, address account) public pure {
        if (account != vm.addr(uint256(keccak256(abi.encodePacked("productOwner"))))) {
            revert NotAuthorized(bytes32(uint256(1 << 1 | 1 << 4)));
        }
    }

    function isProductOwner(uint256, uint256, address account) external pure returns (bool isAllowed) {
        isAllowed = account == vm.addr(uint256(keccak256(abi.encodePacked("productOwner"))));
    }

    function basePrice(uint256, uint256, uint256, address, uint256) external pure returns (Price memory price) {
        price.eth = 1e16;
        price.currency = 100e18;
    }

    function stockUnits(uint256, uint256, uint256) external pure returns (uint256 units, bool isInfinite) {
        units = 6392;
        isInfinite = false;
    }
}
