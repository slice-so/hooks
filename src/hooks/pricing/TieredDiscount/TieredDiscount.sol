// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IProductsModule} from "slice/interfaces/IProductsModule.sol";
import {
    RegistryPrice,
    IProductPrice,
    IProductTypePrice,
    ISlicerProductPrice,
    ProductLineItem
} from "@/utils/RegistryPrice.sol";
import {DiscountParams} from "./types/DiscountParams.sol";

/**
 * @title   TieredDiscount
 * @notice  Tiered discounts based on asset ownership
 * @author  Slice <jacopo.eth>
 */
abstract contract TieredDiscount is RegistryPrice {
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

    mapping(uint256 slicerId => mapping(uint256 productId => mapping(uint256 variantId => DiscountParams[]))) public
        discounts;
    mapping(uint256 slicerId => mapping(uint256 productTypeId => DiscountParams[])) public productTypeDiscounts;
    mapping(uint256 slicerId => DiscountParams[]) public slicerDiscounts;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryPrice(productsModuleAddress) {}

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
        address,
        uint256 basePrice,
        uint256,
        address buyer,
        bytes memory
    ) public view override returns (uint256) {
        DiscountParams[] memory discountParams = discounts[slicerId][productId][variantId];

        return _productPrice(buyer, basePrice, discountParams);
    }

    /**
     * @inheritdoc IProductTypePrice
     */
    function productTypePrice(
        uint256 slicerId,
        uint256 productTypeId,
        address,
        uint256 basePrice,
        uint256,
        address buyer
    ) public view override returns (uint256) {
        DiscountParams[] memory discountParams = productTypeDiscounts[slicerId][productTypeId];

        return _productPrice(buyer, basePrice, discountParams);
    }

    /**
     * @inheritdoc ISlicerProductPrice
     */
    function slicerProductPrice(
        uint256 slicerId,
        address,
        address buyer,
        ProductLineItem[] memory productLineItems,
        uint256[] memory basePrices
    ) public view override returns (uint256[] memory updatedBasePrices) {
        DiscountParams[] memory discountParams = slicerDiscounts[slicerId];
        updatedBasePrices = new uint256[](basePrices.length);

        for (uint256 i; i < productLineItems.length;) {
            updatedBasePrices[i] = _productPrice(buyer, basePrices[i], discountParams);
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic for calculating product price. To be implemented by child contracts.
     *
     * @param buyer Address of the buyer.
     * @param basePrice Base price of the product in selected currency.
     * @param discountParams Array of discount parameters.
     *
     * @return Price of product in selected currency.
     */
    function _productPrice(address buyer, uint256 basePrice, DiscountParams[] memory discountParams)
        internal
        view
        virtual
        returns (uint256);
}
