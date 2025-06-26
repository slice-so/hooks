// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {wadLn, unsafeWadDiv, toDaysWadUnsafe} from "@/utils/math/SignedWadMath.sol";
import {
    IProductsModule, IProductPricingStrategy, IPricingStrategy, PricingStrategy
} from "@/utils/PricingStrategy.sol";
import {LinearProductParams} from "../types/LinearProductParams.sol";
import {LinearVRGDAParams} from "../types/LinearVRGDAParams.sol";
import {VRGDAPrices} from "../VRGDAPrices.sol";

/// @title   Linear Variable Rate Gradual Dutch Auction - Slice pricing strategy
/// @notice  VRGDA with a linear issuance curve - Price library with different params for each Slice product.
/// @author  Slice <jacopo.eth>
contract LinearVRGDAPrices is VRGDAPrices {
    /*//////////////////////////////////////////////////////////////
        STORAGE
    //////////////////////////////////////////////////////////////*/

    // Mapping from slicerId to productId to ProductParams
    mapping(uint256 => mapping(uint256 => LinearProductParams)) private _productParams;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) VRGDAPrices(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc PricingStrategy
     * @notice Set LinearVRGDAParams for a product.
     */
    function _setProductPrice(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (LinearVRGDAParams[] memory linearParams, int256 priceDecayPercent) =
            abi.decode(params, (LinearVRGDAParams[], int256));

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);
        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
        require(decayConstant >= type(int184).min, "MIN_DECAY_CONSTANT_EXCEEDED");

        /// Get product availability and isInfinite
        /// @dev available units is a uint32
        (uint256 availableUnits, bool isInfinite) = PRODUCTS_MODULE.availableUnits(slicerId, productId);

        // Product must not have infinite availability
        require(!isInfinite, "NOT_FINITE_AVAILABILITY");

        // Set product params
        _productParams[slicerId][productId].startTime = uint40(block.timestamp);
        _productParams[slicerId][productId].startUnits = uint32(availableUnits);
        _productParams[slicerId][productId].decayConstant = int184(decayConstant);

        // Set currency params
        for (uint256 i; i < linearParams.length;) {
            _productParams[slicerId][productId].pricingParams[linearParams[i].currency] = linearParams[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IProductPricingStrategy
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address,
        bytes memory
    ) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
        // Add reference for product and pricing params
        LinearProductParams storage productParams = _productParams[slicerId][productId];
        LinearVRGDAParams memory pricingParams = productParams.pricingParams[currency];

        require(productParams.startTime != 0, "PRODUCT_UNSET");

        // Get available units
        (uint256 availableUnits,) = PRODUCTS_MODULE.availableUnits(slicerId, productId);

        // Calculate sold units from availableUnits
        uint256 soldUnits = productParams.startUnits - availableUnits;

        // Set ethPrice or currencyPrice based on chosen currency
        if (currency == address(0)) {
            ethPrice = getAdjustedVRGDAPrice(
                pricingParams.targetPrice,
                productParams.decayConstant,
                toDaysWadUnsafe(block.timestamp - productParams.startTime),
                soldUnits,
                pricingParams.perTimeUnit,
                pricingParams.min,
                quantity
            );
        } else {
            currencyPrice = getAdjustedVRGDAPrice(
                pricingParams.targetPrice,
                productParams.decayConstant,
                toDaysWadUnsafe(block.timestamp - productParams.startTime),
                soldUnits,
                pricingParams.perTimeUnit,
                pricingParams.min,
                quantity
            );
        }
    }

    /**
     * @inheritdoc IPricingStrategy
     */
    function pricingParamsSchema() external pure returns (string memory) {
        return
        "(address currency,int128 targetPrice,uint128 min,int256 perTimeUnit)[] linearParams,int256 priceDecayPercent";
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
