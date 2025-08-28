// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

enum NftType {
    ERC721,
    ERC1155
}

struct NFTGate {
    address nft;
    NftType nftType;
    uint80 id;
    uint8 minQuantity;
}

struct NFTGates {
    NFTGate[] gates;
    uint256 minOwned;
}
