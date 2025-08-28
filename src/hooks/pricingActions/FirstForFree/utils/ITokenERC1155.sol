// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface ITokenERC1155 {
    /**
     *  @notice Lets an account with MINTER_ROLE mint an NFT.
     *
     *  @param to The address to mint the NFT to.
     *  @param tokenId The tokenId of the NFTs to mint
     *  @param uri The URI to assign to the NFT.
     *  @param amount The number of copies of the NFT to mint.
     *
     */
    function mintTo(address to, uint256 tokenId, string calldata uri, uint256 amount) external;
}
