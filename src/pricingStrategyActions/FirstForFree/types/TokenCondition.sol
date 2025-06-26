// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

struct TokenCondition {
    address tokenAddress;
    TokenType tokenType;
    uint80 tokenId;
    uint8 minQuantity;
}

enum TokenType {
    ERC721,
    ERC1155
}
