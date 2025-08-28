// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721Mint_BaseToken} from "../utils/ERC721Mint_BaseToken.sol";

struct ERC721Data {
    ERC721Mint_BaseToken token;
    bool revertOnMaxSupplyReached;
}
