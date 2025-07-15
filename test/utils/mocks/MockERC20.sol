// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20, IERC20} from "@openzeppelin-4.8.0/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("name", "symbol") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
