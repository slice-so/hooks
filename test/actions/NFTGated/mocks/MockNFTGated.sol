// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IProductsModule, NFTGated, NFTGate} from "@/hooks/actions/NFTGated/NFTGated.sol";

contract MockNFTGated is NFTGated {
    constructor(IProductsModule productsModuleAddress) NFTGated(productsModuleAddress) {}

    function gates(uint256 slicerId, uint256 productId) public view returns (NFTGate[] memory) {
        return nftGates[slicerId][productId].gates;
    }
}
