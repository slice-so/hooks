// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {wadExp, wadMul, unsafeWadMul, toWadUnsafe} from "@/utils/math/SignedWadMath.sol";
import {IProductsModule, PricingStrategy} from "@/utils/PricingStrategy.sol";

/**
 * @title   VRGDAPrices Pricing Strategy
 * @notice  Variable Rate Gradual Dutch Auction
 * @author  Slice <jacopo.eth>
 */
abstract contract VRGDAPrices is PricingStrategy {
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) PricingStrategy(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of a product according to the VRGDA formula.
    /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
    /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param sold The total number of products sold so far.
    /// @param timeFactor Time-dependent factor used to calculate target sale time.
    /// @param min minimum price to be paid for a token, scaled by 1e18
    /// @return The price of a product according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(
        int256 targetPrice,
        int256 decayConstant,
        int256 timeSinceStart,
        uint256 sold,
        int256 timeFactor,
        uint256 min
    ) public view virtual returns (uint256) {
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
                            timeSinceStart - getTargetSaleTime(toWadUnsafe(sold + 1), timeFactor)
                        )
                    )
                )
            );

            return VRGDAPrice > min ? VRGDAPrice : min;
        }
    }

    /// @dev Given a number of products sold, return the target time that number of products should be sold by.
    /// @param sold A number of products sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @param timeFactor Time-dependent factor used to calculate target sale time.
    /// @return The target time the products should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the products should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold, int256 timeFactor) public view virtual returns (int256) {}

    /// @notice Get product price adjusted to quantity purchased.
    /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
    /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param sold The total number of products sold so far.
    /// @param timeFactor Time-dependent factor used to calculate target sale time.
    /// @param min minimum price to be paid for a token, scaled by 1e18
    /// @param quantity Number of units purchased
    /// @return price of product * quantity according to VRGDA, scaled by 1e18.
    function getAdjustedVRGDAPrice(
        int256 targetPrice,
        int256 decayConstant,
        int256 timeSinceStart,
        uint256 sold,
        int256 timeFactor,
        uint256 min,
        uint256 quantity
    ) public view virtual returns (uint256 price) {
        for (uint256 i; i < quantity;) {
            price += getVRGDAPrice(targetPrice, decayConstant, timeSinceStart, sold + i, timeFactor, min);

            unchecked {
                ++i;
            }
        }
    }
}
