// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin-5.3.0/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin-5.3.0/interfaces/IERC1155.sol";
import {IOnchainAction} from "@/interfaces/IOnchainAction.sol";
import {
    IProductPricingStrategy,
    IProductsModule,
    PricingStrategyAction,
    OnchainAction
} from "@/utils/PricingStrategyAction.sol";
import {ProductParams, TokenCondition} from "./types/ProductParams.sol";
import {TokenType} from "./types/TokenCondition.sol";
import {ITokenERC1155} from "./utils/ITokenERC1155.sol";

/**
 * @title   FirstForFree
 * @notice  Discounts the first purchase of a product for free, based on conditions.
 * @author  Slice <jacopo.eth>
 */
contract FirstForFree is PricingStrategyAction {
    /*//////////////////////////////////////////////////////////////
                            MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => ProductParams price)) public usdcPrices;
    mapping(address buyer => mapping(uint256 slicerId => uint256 purchases)) public purchases;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) PricingStrategyAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductPricingStrategy
     * @notice Applies discount only for first N purchases on a slicer.
     */
    function productPrice(uint256 slicerId, uint256 productId, address, uint256 quantity, address buyer, bytes memory)
        public
        view
        override
        returns (uint256 ethPrice, uint256 currencyPrice)
    {
        ProductParams memory productParams = usdcPrices[slicerId][productId];

        if (_isEligible(buyer, productParams.eligibleTokens)) {
            uint256 totalPurchases = purchases[buyer][slicerId];
            if (totalPurchases < productParams.freeUnits) {
                unchecked {
                    uint256 freeUnitsLeft = productParams.freeUnits - totalPurchases;
                    if (quantity <= freeUnitsLeft) {
                        return (0, 0);
                    } else {
                        return (0, usdcPrices[slicerId][productId].usdcPrice * (quantity - freeUnitsLeft));
                    }
                }
            }
        }

        return (0, usdcPrices[slicerId][productId].usdcPrice * quantity);
    }
    /**
     * @inheritdoc OnchainAction
     * @notice Mint `quantity` NFTs to `account` on purchase. Keeps track of total purchases.
     */

    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory,
        bytes memory
    ) internal override {
        purchases[buyer][slicerId] += quantity;

        ProductParams memory productParams = usdcPrices[slicerId][productId];
        if (productParams.mintToken != address(0)) {
            ITokenERC1155(productParams.mintToken).mintTo(buyer, productParams.mintTokenId, "", quantity);
        }
    }

    /**
     * @inheritdoc OnchainAction
     * @notice Sets the product parameters.
     */
    function _setProductAction(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (
            uint256 usdcPrice,
            TokenCondition[] memory eligibleTokens,
            address mintToken,
            uint88 mintTokenId,
            uint8 freeUnits
        ) = abi.decode(params, (uint256, TokenCondition[], address, uint88, uint8));

        ProductParams storage productParams = usdcPrices[slicerId][productId];

        productParams.usdcPrice = usdcPrice;
        productParams.mintToken = mintToken;
        productParams.mintTokenId = mintTokenId;
        productParams.freeUnits = freeUnits;

        // Remove all discount tokens
        delete productParams.eligibleTokens;

        for (uint256 i = 0; i < eligibleTokens.length;) {
            productParams.eligibleTokens.push(eligibleTokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IOnchainAction
     */
    function actionParamsSchema() external pure returns (string memory) {
        return
        "uint256 usdcPrice,(address tokenAddress,uint8 tokenType,uint88 tokenId,uint8 minQuantity)[] eligibleTokens,address mintToken,uint88 mintTokenId,uint8 freeUnits";
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
