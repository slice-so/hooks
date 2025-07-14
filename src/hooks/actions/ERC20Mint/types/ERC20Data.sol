// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Mint_BaseToken} from "../utils/ERC20Mint_BaseToken.sol";

struct ERC20Data {
    ERC20Mint_BaseToken token;
    bool revertOnMaxSupplyReached;
    uint256 tokensPerUnit;
}
