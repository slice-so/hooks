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
            revert NotAuthorized(bytes32(uint256(1 << 1 | 1 << 3)));
        }
    }

    function isProductOwner(uint256, uint256, address account) external pure returns (bool isAllowed) {
        isAllowed = account == vm.addr(uint256(keccak256(abi.encodePacked("productOwner"))));
    }

    function basePrice(uint256, uint256, uint256, address currency, uint256 quantity)
        external
        pure
        returns (uint256 amount)
    {
        if (currency == address(0)) {
            amount = 1e16 * quantity;
        } else {
            // USDC
            amount = 100e6 * quantity;
        }
    }

    function stockUnits(uint256, uint256, uint256) external pure returns (uint256 units, bool isInfinite) {
        units = 6392;
        isInfinite = false;
    }

    function getPurchases(address, uint256, uint256, uint256)
        external
        pure
        returns (uint256 purchasedUnits, bytes memory purchaseData)
    {
        purchasedUnits = 0;
        purchaseData = "";
    }

    function productExists(uint256 slicerId, uint256 productId) external view {}
}
