// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IProductsModule, OnchainAction, IOnchainAction} from "@/utils/OnchainAction.sol";
import {MAX_ROYALTY, ERC721Mint_BaseToken} from "./utils/ERC721Mint_BaseToken.sol";
import {ERC721Data} from "./types/ERC721Data.sol";

/**
 * @title ERC721Mint
 * @notice Mints ERC721 tokens for each unit purchased.
 * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
 * @author  Slice <jacopo.eth>
 */
contract ERC721Mint is OnchainAction {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MaxSupplyExceeded();
    error InvalidRoyaltyFraction();

    /*//////////////////////////////////////////////////////////////
                            MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => ERC721Data tokenData)) public tokenData;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) OnchainAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc OnchainAction
     * @notice Mints tokens to the buyer.
     * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory,
        bytes memory
    ) internal override {
        ERC721Data memory tokenData_ = tokenData[slicerId][productId];

        (bool success,) =
            address(tokenData_.token).call(abi.encodeWithSelector(tokenData_.token.mint.selector, buyer, quantity));

        if (tokenData_.revertOnMaxSupplyReached) {
            if (!success) revert MaxSupplyExceeded();
        }
    }

    /**
     * @inheritdoc OnchainAction
     * @dev Sets the ERC721 data for a product.
     */
    function _setProductAction(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (
            string memory name_,
            string memory symbol_,
            address royaltyReceiver_,
            uint256 royaltyFraction_,
            string memory baseURI__,
            string memory tokenURI__,
            bool revertOnMaxSupplyReached,
            uint256 maxSupply
        ) = abi.decode(params, (string, string, address, uint256, string, string, bool, uint256));

        if (royaltyFraction_ > MAX_ROYALTY) revert InvalidRoyaltyFraction();

        ERC721Mint_BaseToken token = tokenData[slicerId][productId].token;

        if (address(token) == address(0)) {
            token = new ERC721Mint_BaseToken(
                name_, symbol_, maxSupply, royaltyReceiver_, royaltyFraction_, baseURI__, tokenURI__
            );
        } else {
            token.setParams(maxSupply, royaltyReceiver_, royaltyFraction_, baseURI__, tokenURI__);
        }

        tokenData[slicerId][productId] = ERC721Data(token, revertOnMaxSupplyReached);
    }

    /**
     * @inheritdoc IOnchainAction
     */
    function actionParamsSchema() external pure returns (string memory) {
        return
        "string name,string symbol,address royaltyReceiver,uint256 royaltyFraction,string baseURI,string tokenURI,bool revertOnMaxSupplyReached,uint256 maxSupply";
    }
}
