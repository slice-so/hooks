// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin-5.3.0/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 public tokenId;

    constructor() ERC721("name", "symbol") {}

    function mint(address to) external {
        _mint(to, tokenId++);
    }
}
