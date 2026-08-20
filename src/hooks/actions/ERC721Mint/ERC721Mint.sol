// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {HookRegistry, IProductsModule, RegistryAction, ProductLineItem} from "@/utils/RegistryAction.sol";
import {ProductHookRegistry, IProductHookRegistry} from "@/utils/RegistryProductAction.sol";
import {MAX_ROYALTY, ERC721Mint_BaseToken} from "./utils/ERC721Mint_BaseToken.sol";
import {ERC721Data} from "./types/ERC721Data.sol";

/**
 * @title   ERC721Mint
 * @notice  Onchain action registry for minting ERC721 tokens on every purchase.
 * @dev     If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
 * @author  Slice <jacopo.eth>
 */
contract ERC721Mint is RegistryAction {
    /*//////////////////////////////////////////////////////////////
        ERRORS
    //////////////////////////////////////////////////////////////*/

    error MaxSupplyExceeded();
    error InvalidRoyaltyFraction();

    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => mapping(uint256 variantId => ERC721Data tokenData))) public
        tokenData;
    mapping(uint256 slicerId => mapping(uint256 productTypeId => ERC721Data tokenData)) public productTypeTokenData;
    mapping(uint256 slicerId => ERC721Data tokenData) public slicerTokenData;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc RegistryAction
     * @notice Mint tokens to the buyer.
     * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address buyer,
        uint256 quantity,
        bytes memory
    ) internal override {
        ERC721Data memory tokenData_ = tokenData[slicerId][productId][variantId];

        handleOnProductPurchase(tokenData_, buyer, quantity, false);
    }

    /**
     * @inheritdoc RegistryAction
     * @notice Mint tokens to the buyer.
     * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
     */
    function _onProductTypePurchase(uint256 slicerId, uint256 productTypeId, address buyer, uint256 quantity)
        internal
        override
    {
        ERC721Data memory tokenData_ = productTypeTokenData[slicerId][productTypeId];
        handleOnProductPurchase(tokenData_, buyer, quantity, false);
    }

    /**
     * @inheritdoc RegistryAction
     * @notice Mint tokens to the buyer.
     * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
     */
    function _onSlicerPurchase(uint256 slicerId, address buyer, ProductLineItem[] memory productLineItems)
        internal
        override
    {
        ERC721Data memory tokenData_ = slicerTokenData[slicerId];

        uint256 quantity;
        for (uint256 i = 0; i < productLineItems.length;) {
            quantity += productLineItems[i].quantity;

            unchecked {
                ++i;
            }
        }

        handleOnProductPurchase(tokenData_, buyer, quantity, true);
    }

    /**
     * @inheritdoc ProductHookRegistry
     * @dev Set the ERC721 data for a product.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, uint256 variantId, bytes memory params)
        internal
        override
    {
        handleConfigure(tokenData[slicerId][productId][variantId], params);
    }

    /**
     * @inheritdoc HookRegistry
     * @dev Set the ERC721 data for a product type.
     */
    function _configureProductType(uint256 slicerId, uint256 productTypeId, bytes memory params) internal override {
        handleConfigure(productTypeTokenData[slicerId][productTypeId], params);
    }

    /**
     * @inheritdoc HookRegistry
     * @dev Set the ERC721 data for a slicer.
     */
    function _configureSlicer(uint256 slicerId, bytes memory params) internal override {
        handleConfigure(slicerTokenData[slicerId], params);
    }

    /**
     * @inheritdoc IProductHookRegistry
     */
    function configureProductSchema() public pure override returns (string memory) {
        return
        "string name,string symbol,address royaltyReceiver,uint256 royaltyFraction,string baseURI,string tokenURI,bool revertOnMaxSupplyReached,uint256 maxSupply";
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL
    //////////////////////////////////////////////////////////////*/
    function handleConfigure(ERC721Data storage tokenDataStorage, bytes memory params) internal {
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

        ERC721Mint_BaseToken token = tokenDataStorage.token;

        if (address(token) == address(0)) {
            token = new ERC721Mint_BaseToken(
                name_, symbol_, maxSupply, royaltyReceiver_, royaltyFraction_, baseURI__, tokenURI__
            );
        } else {
            token.setParams(maxSupply, royaltyReceiver_, royaltyFraction_, baseURI__, tokenURI__);
        }

        tokenDataStorage.token = token;
        tokenDataStorage.revertOnMaxSupplyReached = revertOnMaxSupplyReached;
    }

    function handleOnProductPurchase(ERC721Data memory tokenData_, address buyer, uint256 quantity, bool isSlicerAction)
        internal
    {
        (bool success,) =
            address(tokenData_.token).call(abi.encodeWithSelector(tokenData_.token.mint.selector, buyer, quantity));

        if (!isSlicerAction && tokenData_.revertOnMaxSupplyReached) {
            if (!success) revert MaxSupplyExceeded();
        }
    }
}
