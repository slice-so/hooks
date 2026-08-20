// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {
    ProductHookRegistry,
    IProductPrice,
    IProductHookRegistry,
    IProductsModule
} from "@/utils/RegistryProductPrice.sol";
import {wadLn, unsafeWadDiv, toDaysWadUnsafe} from "@/utils/math/SignedWadMath.sol";
import {LinearProduct} from "../types/LinearProduct.sol";
import {VRGDAPrices} from "../VRGDAPrices.sol";

/// @title   LinearVRGDAPrices
/// @notice  VRGDA with a linear issuance curve - Price library with different params for each Slice product.
/// @author  Slice <jacopo.eth>
contract LinearVRGDAPrices is VRGDAPrices {
    /*//////////////////////////////////////////////////////////////
        STORAGE
    //////////////////////////////////////////////////////////////*/

    // Mapping from slicerId to productId to ProductParams
    mapping(uint256 slicerId => mapping(uint256 productId => mapping(uint256 variantId => LinearProduct))) private
        _productParams;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) VRGDAPrices(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ProductHookRegistry
     * @notice Set LinearProduct for a product.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, uint256 variantId, bytes memory params)
        internal
        override
    {
        (int184 priceDecayPercent, uint16 min, int256 perTimeUnit) = abi.decode(params, (int184, uint16, int256));

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);
        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
        require(decayConstant >= type(int184).min, "MIN_DECAY_CONSTANT_EXCEEDED");

        /// Get product availability and isInfinite
        (uint32 stockUnits_, bool isInfinite) = getStockUnits(slicerId, productId, 0);

        // Product must not have infinite availability
        require(!isInfinite, "NOT_FINITE_AVAILABILITY");

        // Set product params
        _productParams[slicerId][productId][variantId] = LinearProduct({
            startTime: uint40(block.timestamp),
            startUnits: stockUnits_,
            decayConstant: int184(decayConstant), // forge-lint: disable-line(unsafe-typecast)
            min: min,
            perTimeUnit: perTimeUnit
        });
    }

    /**
     * @inheritdoc IProductPrice
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address currency,
        uint256,
        uint256 quantity,
        address,
        bytes memory
    ) public view override returns (uint256 price) {
        LinearProduct storage productParams = _productParams[slicerId][productId][variantId];

        require(productParams.startTime != 0, "PRODUCT_UNSET");

        // Get available units and base price
        (uint256 stockUnits_,) = getStockUnits(slicerId, productId, variantId);
        uint256 basePrice_ = getBasePrice(slicerId, productId, variantId, currency, 1);

        if (basePrice_ > uint256(type(int256).max)) revert("BASE_PRICE_TOO_HIGH");

        // Calculate sold units from stockUnits
        uint256 soldUnits = productParams.startUnits - stockUnits_;

        price = getAdjustedVRGDAPrice(
            int256(basePrice_), // forge-lint: disable-line(unsafe-typecast)
            productParams.decayConstant,
            toDaysWadUnsafe(block.timestamp - productParams.startTime),
            soldUnits,
            productParams.perTimeUnit,
            basePrice_ * productParams.min / 1e5,
            quantity
        );
    }

    /**
     * @inheritdoc IProductHookRegistry
     */
    function configureProductSchema() public pure override returns (string memory) {
        return "int184 priceDecayPercent,uint16 min,int256 perTimeUnit";
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Given a number of products sold, return the target time that number of products should be sold by.
    /// @param sold A number of products sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @param timeFactor Time-dependent factor used to calculate target sale time.
    /// @return The target time the products should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the products should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold, int256 timeFactor) public pure override returns (int256) {
        return unsafeWadDiv(sold, timeFactor);
    }
}
