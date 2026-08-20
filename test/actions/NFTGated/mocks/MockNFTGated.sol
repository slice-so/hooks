// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IProductsModule, NFTGated, NFTGate} from "@/hooks/actions/NFTGated/NFTGated.sol";

contract MockNFTGated is NFTGated {
    constructor(IProductsModule productsModuleAddress) NFTGated(productsModuleAddress) {}

    function gates(uint256 slicerId, uint256 productId, uint256 variantId) public view returns (NFTGate[] memory) {
        return nftGates[slicerId][productId][variantId].gates;
    }

    function productTypeGates(uint256 slicerId, uint256 productTypeId) public view returns (NFTGate[] memory) {
        return productTypeNftGates[slicerId][productTypeId].gates;
    }

    function slicerGates(uint256 slicerId) public view returns (NFTGate[] memory) {
        return slicerNftGates[slicerId].gates;
    }

    function productTypeMinOwned(uint256 slicerId, uint256 productTypeId) public view returns (uint256) {
        return productTypeNftGates[slicerId][productTypeId].minOwned;
    }

    function slicerMinOwned(uint256 slicerId) public view returns (uint256) {
        return slicerNftGates[slicerId].minOwned;
    }
}
