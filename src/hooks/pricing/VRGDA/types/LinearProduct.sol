// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @param startTime Time when the VRGDA began.
/// @param startUnits Units available at the time when product is set up.
/// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
/// @param min minimum price to be paid for a token, in percentage of the target price (1e5 = 100%)
/// @param perTimeUnit The total number of products to target selling every full unit of time.
struct LinearProduct {
    uint40 startTime;
    uint32 startUnits;
    int184 decayConstant;
    uint16 min;
    int256 perTimeUnit;
}
