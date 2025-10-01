// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {HookRegistry, IProductPrice, IHookRegistry, IProductsModule} from "@/utils/RegistryProductPrice.sol";
import {
    wadMul,
    toWadUnsafe,
    wadLn,
    unsafeWadDiv,
    toDaysWadUnsafe,
    unsafeDiv,
    wadExp,
    unsafeWadMul
} from "@/utils/math/SignedWadMath.sol";
import {LogisticProduct} from "../types/LogisticProduct.sol";
import {IProductsModule, VRGDAPrices} from "../VRGDAPrices.sol";

/// @title   LogisticVRGDAPrices
/// @notice  VRGDA with a logistic issuance curve - Price library with different params for each Slice product.
/// @author  Slice <jacopo.eth>
contract LogisticVRGDAPrices is VRGDAPrices {
    /*//////////////////////////////////////////////////////////////
        STORAGE
    //////////////////////////////////////////////////////////////*/

    // Mapping from slicerId to productId to LogisticProduct
    mapping(uint256 slicerId => mapping(uint256 productId => mapping(uint256 variantId => LogisticProduct))) private
        _productParams;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) VRGDAPrices(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc HookRegistry
     * @notice Set LogisticVRGDAParams for a product.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, uint256 variantId, bytes memory params)
        internal
        override
    {
        (int184 priceDecayPercent, uint16 min, int256 timescale) = abi.decode(params, (int184, uint16, int256));

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);
        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
        require(decayConstant >= type(int184).min, "MIN_DECAY_CONSTANT_EXCEEDED");

        // Get product availability and isInfinite
        (uint256 stockUnits_, bool isInfinite) = getStockUnits(slicerId, productId, 0);

        // Product must not have infinite availability
        require(!isInfinite, "NON_FINITE_AVAILABILITY");

        // Set product params
        _productParams[slicerId][productId][variantId] = LogisticProduct({
            startTime: uint40(block.timestamp),
            startUnits: uint32(stockUnits_),
            decayConstant: int184(decayConstant),
            min: min,
            timeScale: timescale
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
        LogisticProduct storage productParams = _productParams[slicerId][productId][variantId];

        require(productParams.startTime != 0, "PRODUCT_UNSET");

        // Get available units and base price
        (uint256 stockUnits_,) = getStockUnits(slicerId, productId, variantId);
        uint256 basePrice_ = getBasePrice(slicerId, productId, variantId, currency, 1);

        // Calculate sold units from stockUnits
        uint256 soldUnits = productParams.startUnits - stockUnits_;

        price = getAdjustedVRGDALogisticPrice(
            int256(basePrice_),
            productParams.decayConstant,
            toDaysWadUnsafe(block.timestamp - productParams.startTime),
            toWadUnsafe(productParams.startUnits + 1),
            soldUnits,
            productParams.timeScale,
            basePrice_ * productParams.min / 1e5,
            quantity
        );
    }

    /**
     * @inheritdoc IHookRegistry
     */
    function configureProductSchema() external pure override returns (string memory) {
        return "int184 priceDecayPercent,uint16 min,int256 timescale";
    }

    /*//////////////////////////////////////////////////////////////
        PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Same as `getVRGDAPrice` but which additionally accepts `logisticLimit` and
    /// `logisticLimitDouble` as param.
    /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
    /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param logisticLimit The maximum number of products to sell + 1.
    /// @param logisticLimitDouble The maximum number of products to sell + 1 multiplied by 2.
    /// @param sold The total number of products sold so far.
    /// @param timeFactor Time-dependent factor used to calculate target sale time.
    /// @param min minimum price to be paid for a token, scaled by 1e18
    /// @return The price of a product according to VRGDA, scaled by 1e18.
    function getVRGDALogisticPrice(
        int256 targetPrice,
        int256 decayConstant,
        int256 timeSinceStart,
        int256 logisticLimit,
        int256 logisticLimitDouble,
        uint256 sold,
        int256 timeFactor,
        uint256 min
    ) public pure returns (uint256) {
        unchecked {
            // prettier-ignore
            uint256 VRGDAPrice = uint256(
                wadMul(
                    targetPrice,
                    wadExp(
                        unsafeWadMul(
                            decayConstant,
                            // We use sold + 1 as the VRGDA formula's n param represents the nth product and sold is the
                            // n-1th product.
                            timeSinceStart
                                - getTargetSaleTime(
                                    unsafeDiv(logisticLimitDouble, toWadUnsafe(sold + 1) + logisticLimit), timeFactor
                                )
                        )
                    )
                )
            );

            return VRGDAPrice > min ? VRGDAPrice : min;
        }
    }

    /// @notice Get product price adjusted to quantity purchased.
    /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
    /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param logisticLimit The maximum number of products to sell + 1.
    /// @param sold The total number of products sold so far.
    /// @param timeFactor Time-dependent factor used to calculate target sale time.
    /// @param min minimum price to be paid for a token, scaled by 1e18
    /// @param quantity Number of units purchased
    /// @return price of product * quantity according to VRGDA, scaled by 1e18.
    function getAdjustedVRGDALogisticPrice(
        int256 targetPrice,
        int256 decayConstant,
        int256 timeSinceStart,
        int256 logisticLimit,
        uint256 sold,
        int256 timeFactor,
        uint256 min,
        uint256 quantity
    ) public pure returns (uint256 price) {
        int256 logisticLimitDouble = logisticLimit * 2e18;
        for (uint256 i; i < quantity;) {
            price += getVRGDALogisticPrice(
                targetPrice,
                decayConstant,
                timeSinceStart,
                logisticLimit,
                logisticLimitDouble,
                sold + i,
                timeFactor,
                min
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Given a number of products sold, return the target time that number of products should be sold by.
    /// @param saleFactor Sales-dependent factor used to calculate target sale time.
    /// @param timeFactor Time-dependent factor used to calculate target sale time.
    /// @return The target time the products should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the products should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 saleFactor, int256 timeFactor) public pure override returns (int256) {
        unchecked {
            return -unsafeWadDiv(wadLn(saleFactor - 1e18), timeFactor);
        }
    }
}
