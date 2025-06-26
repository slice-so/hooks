// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-5.3.0/interfaces/IERC20.sol";

struct ERC20Gate {
    IERC20 erc20;
    uint256 amount;
}
