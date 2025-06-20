// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {IProductsModule, PricingStrategy} from "@/utils/PricingStrategy.sol";
import {CurrencyParams} from "./structs/CurrencyParams.sol";
import {ProductDiscounts, DiscountType} from "./structs/ProductDiscounts.sol";
import {DiscountParams, NFTType} from "./structs/DiscountParams.sol";

/**
 * @notice  Tiered discounts based on asset ownership
 * @author  Slice <jacopo.eth>
 */
abstract contract TieredDiscount is PricingStrategy {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ProductPriceSet(uint256 slicerId, uint256 productId, CurrencyParams[] params);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error WrongCurrency();
    error InvalidRelativeDiscount();
    error InvalidMinQuantity();
    error DiscountsNotDescending(DiscountParams nft);

    /*//////////////////////////////////////////////////////////////
                            MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => mapping(address currency => ProductDiscounts))) public
        productDiscounts;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule _productsModule) PricingStrategy(_productsModule) {}

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Called by product owner to set base price and discounts for a product.
     *
     * @param slicerId ID of the slicer to set the price params for.
     * @param productId ID of the product to set the price params for.
     * @param params Array of `CurrencyParams` structs
     */
    function setProductPrice(uint256 slicerId, uint256 productId, CurrencyParams[] memory params)
        external
        onlyProductOwner(slicerId, productId)
    {
        _setProductPrice(slicerId, productId, params);
        emit ProductPriceSet(slicerId, productId, params);
    }

    /**
     * @notice See {ISliceProductPrice}
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data
    ) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
        ProductDiscounts memory discountParams = productDiscounts[slicerId][productId][currency];

        if (discountParams.basePrice == 0) {
            if (!discountParams.isFree) revert WrongCurrency();
        } else {
            return _productPrice(slicerId, productId, currency, quantity, buyer, data, discountParams);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _setProductPrice(uint256 slicerId, uint256 productId, CurrencyParams[] memory params) internal virtual;

    function _productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data,
        ProductDiscounts memory discountParams
    ) internal view virtual returns (uint256 ethPrice, uint256 currencyPrice);
}
