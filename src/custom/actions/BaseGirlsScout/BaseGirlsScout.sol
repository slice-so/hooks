// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IProductsModule, ProductAction} from "@/utils/ProductAction.sol";
import {Ownable} from "@openzeppelin-4.8.0/access/Ownable.sol";
import {IERC1155} from "@openzeppelin-4.8.0/interfaces/IERC1155.sol";

/**
 * @title BaseGirlsScout
 * @notice Onchain action that mints Base Girls Scout NFTs to the buyer on every purchase.
 * @author Slice <jacopo.eth>
 */
contract BaseGirlsScout is ProductAction, Ownable {
    /*//////////////////////////////////////////////////////////////
        IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    ITokenERC1155 public MINT_NFT_COLLECTION = ITokenERC1155(0x7A110890DF5D95CefdB0151143E595b755B7c9b7);
    uint256 public MINT_NFT_TOKEN_ID = 1;

    /*//////////////////////////////////////////////////////////////
        STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => bool allowed) public allowedSlicerIds;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress, uint256 slicerId)
        ProductAction(productsModuleAddress, slicerId)
        Ownable()
    {
        allowedSlicerIds[2217] = true;
        allowedSlicerIds[2218] = true;
    }

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

    /*//////////////////////////////////////////////////////////////
        FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Called by contract owner to set allowed slicer Ids.
     */
    function setAllowedSlicerId(uint256 slicerId, bool allowed) external onlyOwner {
        allowedSlicerIds[slicerId] = allowed;
    }

    /**
     * @notice Called by contract owner to set the mint token collection and token ID.
     */
    function setMintTokenId(address collection, uint256 tokenId) external onlyOwner {
        MINT_NFT_COLLECTION = ITokenERC1155(collection);
        MINT_NFT_TOKEN_ID = tokenId;
    }
}

interface ITokenERC1155 {
    function mintTo(address to, uint256 tokenId, string calldata uri, uint256 amount) external;
}
