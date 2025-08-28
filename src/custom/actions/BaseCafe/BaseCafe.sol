// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IProductsModule, ProductAction} from "@/utils/ProductAction.sol";

/**
 * @title BaseCafe
 * @notice Onchain action that mints an NFT to the buyer on every purchase.
 * @author Slice <jacopo.eth>
 */
contract BaseCafe is ProductAction {
    /*//////////////////////////////////////////////////////////////
        IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    ITokenERC1155 public constant MINT_NFT_COLLECTION = ITokenERC1155(0x8485A580A9975deF42F8C7c5C63E9a0FF058561D);
    uint256 public constant MINT_NFT_TOKEN_ID = 9;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress, uint256 slicerId)
        ProductAction(productsModuleAddress, slicerId)
    {}

    /*//////////////////////////////////////////////////////////////
        FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ProductAction
     * @notice Mint `quantity` NFTs to `account` on purchase
     */
    function _onProductPurchase(uint256, uint256, address buyer, uint256 quantity, bytes memory, bytes memory)
        internal
        override
    {
        MINT_NFT_COLLECTION.mintTo(buyer, MINT_NFT_TOKEN_ID, "", quantity);
    }
}

interface ITokenERC1155 {
    function mintTo(address to, uint256 tokenId, string calldata uri, uint256 amount) external;
}
