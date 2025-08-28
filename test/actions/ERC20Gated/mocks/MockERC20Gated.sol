// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IProductsModule, ERC20Gated, ERC20Gate} from "@/hooks/actions/ERC20Gated/ERC20Gated.sol";

contract MockERC20Gated is ERC20Gated {
    constructor(IProductsModule productsModuleAddress) ERC20Gated(productsModuleAddress) {}

    function gates(uint256 slicerId, uint256 productId) public view returns (ERC20Gate[] memory) {
        return tokenGates[slicerId][productId];
    }
}
