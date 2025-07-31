// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721Mint_BaseToken} from "../utils/ERC721Mint_BaseToken.sol";

struct ERC721Data {
    ERC721Mint_BaseToken token;
    bool revertOnMaxSupplyReached;
}
