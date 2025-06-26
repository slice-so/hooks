// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IProductsModule, PricingStrategy} from "@/utils/PricingStrategy.sol";
import {ProductDiscounts, DiscountType} from "./types/ProductDiscounts.sol";
import {DiscountParams, NFTType} from "./types/DiscountParams.sol";

/**
 * @notice  Tiered discounts based on asset ownership
 * @author  Slice <jacopo.eth>
 */
abstract contract TieredDiscount is PricingStrategy {
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

    constructor(IProductsModule productsModuleAddress) PricingStrategy(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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
