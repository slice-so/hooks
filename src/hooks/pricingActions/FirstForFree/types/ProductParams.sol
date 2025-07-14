// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenCondition} from "./TokenCondition.sol";

struct ProductParams {
    uint256 usdcPrice;
    TokenCondition[] eligibleTokens;
    address mintToken;
    uint88 mintTokenId;
    uint8 freeUnits;
}
