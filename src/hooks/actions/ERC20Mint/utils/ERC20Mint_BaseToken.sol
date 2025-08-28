// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin-4.8.0/token/ERC20/ERC20.sol";

/**
 * @title ERC20Mint_BaseToken
 * @notice Base ERC20 token for ERC20Mint onchain action.
 */
contract ERC20Mint_BaseToken is ERC20 {
    /*//////////////////////////////////////////////////////////////
        ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotMinter();
    error MaxSupplyExceeded();

    /*//////////////////////////////////////////////////////////////
        STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable MINTER;
    uint256 public maxSupply;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) ERC20(name_, symbol_) {
        MINTER = msg.sender;
        _setMaxSupply(maxSupply_);
    }

    /*//////////////////////////////////////////////////////////////
        FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) public {
        if (msg.sender != MINTER) revert NotMinter();
        _mint(to, amount);

        if (totalSupply() > maxSupply) revert MaxSupplyExceeded();
    }

    function setMaxSupply(uint256 maxSupply_) public {
        if (msg.sender != MINTER) revert NotMinter();

        _setMaxSupply(maxSupply_);
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setMaxSupply(uint256 maxSupply_) internal {
        maxSupply = maxSupply_ == 0 ? type(uint256).max : maxSupply_;
    }
}
