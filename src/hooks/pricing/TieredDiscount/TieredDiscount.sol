// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IProductsModule} from "slice/interfaces/IProductsModule.sol";
import {RegistryProductPrice, IProductPrice} from "@/utils/RegistryProductPrice.sol";
import {DiscountParams} from "./types/DiscountParams.sol";
import {Price} from "slice/types/Price.sol";

/**
 * @title   TieredDiscount
 * @notice  Tiered discounts based on asset ownership
 * @author  Slice <jacopo.eth>
 */
abstract contract TieredDiscount is RegistryProductPrice {
    /*//////////////////////////////////////////////////////////////
        ERRORS
    //////////////////////////////////////////////////////////////*/

    error WrongCurrency();
    error InvalidRelativeAmount();
    error InvalidMinQuantity();
    error DiscountsNotDescending(DiscountParams nft);

    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => DiscountParams[])) public discounts;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryProductPrice(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductPrice
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data
    ) public view override returns (Price memory) {
        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, currency, quantity);

        DiscountParams[] memory discountParams = discounts[slicerId][productId];

        return _productPrice(
            slicerId,
            productId,
            variantId,
            currency,
            quantity,
            buyer,
            data,
            currency == address(0) ? basePrice.eth : basePrice.currency,
            discountParams
        );
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
     * @param basePrice Base price of the product.
     * @param discountParams Array of discount parameters.
     *
     * @return ethPrice and currencyPrice of product.
     */
    function _productPrice(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data,
        uint256 basePrice,
        DiscountParams[] memory discountParams
    ) internal view virtual returns (Price memory);
}
