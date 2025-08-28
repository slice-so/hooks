// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokenCondition} from "./TokenCondition.sol";

struct ProductParams {
    uint256 usdcPrice;
    TokenCondition[] eligibleTokens;
    address mintToken;
    uint88 mintTokenId;
    uint8 freeUnits;
}
