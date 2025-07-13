// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistryPricingStrategy, IPricingStrategy, IProductsModule} from "@/utils/RegistryPricingStrategy.sol";
import {ProductDiscounts, DiscountType} from "./types/ProductDiscounts.sol";
import {DiscountParams, NFTType} from "./types/DiscountParams.sol";

/**
 * @title   TieredDiscount
 * @notice  Tiered discounts based on asset ownership
 * @author  Slice <jacopo.eth>
 */
abstract contract TieredDiscount is RegistryPricingStrategy {
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

    constructor(IProductsModule productsModuleAddress) RegistryPricingStrategy(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IPricingStrategy
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

    /**
     * @notice Logic for calculating product price. To be implemented by child contracts.
     *
     * @param slicerId ID of the slicer to set the price params for.
     * @param productId ID of the product to set the price params for.
     * @param currency Currency chosen for the purchase
     * @param quantity Number of units purchased
     * @param buyer Address of the buyer.
     * @param data Data passed to the productPrice function.
     * @param discountParams `ProductDiscounts` struct.
     *
     * @return ethPrice and currencyPrice of product.
     */
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
