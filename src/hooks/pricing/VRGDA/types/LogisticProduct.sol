// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @param startTime Time when the VRGDA began.
/// @param startUnits Units available at the time when product is set up.
/// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
/// @param min minimum price to be paid for a token, scaled by 1e18
/// @param timeScale Time scale controls the steepness of the logistic curve,
struct LogisticProduct {
    uint40 startTime;
    uint32 startUnits;
    int184 decayConstant;
    uint128 min;
    int256 timeScale;
}
