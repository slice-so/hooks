// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum TokenType {
    ERC721,
    ERC1155
}

struct NFTGate {
    address nft;
    TokenType tokenType;
    uint80 id;
    uint8 minQuantity;
}

struct NFTGates {
    NFTGate[] gates;
    uint256 minOwned;
}
