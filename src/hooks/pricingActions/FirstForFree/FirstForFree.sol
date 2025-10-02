// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin-4.8.0/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin-4.8.0/interfaces/IERC1155.sol";
import {
    IProductPrice,
    RegistryProductAction,
    RegistryProductPriceAction,
    IHookRegistry,
    IProductsModule
} from "@/utils/RegistryProductPriceAction.sol";
import {HookRegistry} from "@/utils/RegistryProductAction.sol";
import {ProductParams, TokenCondition} from "./types/ProductParams.sol";
import {TokenType} from "./types/TokenCondition.sol";
import {ITokenERC1155} from "./utils/ITokenERC1155.sol";

/**
 * @title   FirstForFree
 * @notice  Discounts the first purchase of a product for free, based on conditions.
 * @author  Slice <jacopo.eth>
 */
contract FirstForFree is RegistryProductPriceAction {
    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => mapping(uint256 variantId => ProductParams price))) public
        productParams;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryProductPriceAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductPrice
     * @notice Applies discount only for first N purchases on a slicer.
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address,
        uint256 basePrice,
        uint256 quantity,
        address buyer,
        bytes memory
    ) public view override returns (uint256) {
        ProductParams memory params = productParams[slicerId][productId][variantId];

        if (_isEligible(buyer, params.eligibleTokens)) {
            uint256 totalPurchases = getPurchases(buyer, slicerId, productId, variantId);
            if (totalPurchases < params.freeUnits) {
                unchecked {
                    uint256 freeUnitsLeft = params.freeUnits - totalPurchases;

                    if (quantity <= freeUnitsLeft) {
                        return 0;
                    } else {
                        return getBasePrice(slicerId, productId, variantId, address(0), quantity - freeUnitsLeft);
                    }
                }
            }
        }

        return basePrice;
    }

    /**
     * @inheritdoc RegistryProductAction
     * @notice Mint `quantity` NFTs to `account` on purchase.
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address buyer,
        uint256 quantity,
        bytes memory
    ) internal override {
        ProductParams memory params = productParams[slicerId][productId][variantId];
        if (params.mintToken != address(0)) {
            ITokenERC1155(params.mintToken).mintTo(buyer, params.mintTokenId, "", quantity);
        }
    }

    /**
     * @inheritdoc HookRegistry
     * @notice Sets the product parameters.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, uint256 variantId, bytes memory params)
        internal
        override
    {
        (TokenCondition[] memory eligibleTokens, address mintToken, uint88 mintTokenId, uint8 freeUnits) =
            abi.decode(params, (TokenCondition[], address, uint88, uint8));

        ProductParams storage productParams_ = productParams[slicerId][productId][variantId];

        productParams_.mintToken = mintToken;
        productParams_.mintTokenId = mintTokenId;
        productParams_.freeUnits = freeUnits;

        // Remove all discount tokens
        delete productParams_.eligibleTokens;

        for (uint256 i = 0; i < eligibleTokens.length;) {
            productParams_.eligibleTokens.push(eligibleTokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IHookRegistry
     */
    function configureProductSchema() external pure override returns (string memory) {
        return
        "(address tokenAddress,uint8 tokenType,uint80 tokenId,uint8 minQuantity)[] eligibleTokens,address mintToken,uint88 mintTokenId,uint8 freeUnits";
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _isEligible(address buyer, TokenCondition[] memory eligibleTokens)
        internal
        view
        returns (bool isEligible)
    {
        isEligible = eligibleTokens.length == 0;
        if (!isEligible) {
            TokenCondition memory tokenCondition;
            for (uint256 i = 0; i < eligibleTokens.length;) {
                tokenCondition = eligibleTokens[i];

                isEligible = tokenCondition.tokenType == TokenType.ERC721
                    ? IERC721(tokenCondition.tokenAddress).balanceOf(buyer) >= tokenCondition.minQuantity
                    : IERC1155(tokenCondition.tokenAddress).balanceOf(buyer, tokenCondition.tokenId)
                        >= tokenCondition.minQuantity;

                if (isEligible) break;

                unchecked {
                    ++i;
                }
            }
        }
    }
}
