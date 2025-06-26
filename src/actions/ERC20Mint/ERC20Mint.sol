// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IProductsModule, OnchainAction, IOnchainAction} from "@/utils/OnchainAction.sol";
import {ERC20Data} from "./types/ERC20Data.sol";
import {ERC20Mint_BaseToken} from "./utils/ERC20Mint_BaseToken.sol";

/**
 * @title ERC20Mint
 * @notice Mints ERC20 tokens for each unit purchased.
 * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
 * @author  Slice <jacopo.eth>
 */
contract ERC20Mint is OnchainAction {
    /*//////////////////////////////////////////////////////////////
        ERRORS
    //////////////////////////////////////////////////////////////*/

    error MaxSupplyExceeded();
    error InvalidTokensPerUnit();

    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => ERC20Data tokenData)) public tokenData;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) OnchainAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc OnchainAction
     * @dev If `revertOnMaxSupplyReached` is set to true, returns false when max supply is exceeded.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address,
        uint256 quantity,
        bytes memory,
        bytes memory
    ) public view virtual override returns (bool isAllowed) {
        ERC20Data memory tokenData_ = tokenData[slicerId][productId];

        if (tokenData_.revertOnMaxSupplyReached) {
            return
                tokenData_.token.totalSupply() + (quantity * tokenData_.tokensPerUnit) <= tokenData_.token.maxSupply();
        }

        return true;
    }

    /**
     * @inheritdoc OnchainAction
     * @notice Mints tokens to the buyer.
     * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory,
        bytes memory
    ) internal override {
        ERC20Data memory tokenData_ = tokenData[slicerId][productId];

        uint256 tokensToMint = quantity * tokenData_.tokensPerUnit;

        (bool success,) =
            address(tokenData_.token).call(abi.encodeWithSelector(tokenData_.token.mint.selector, buyer, tokensToMint));

        if (tokenData_.revertOnMaxSupplyReached) {
            if (!success) revert MaxSupplyExceeded();
        }
    }

    /**
     * @inheritdoc OnchainAction
     * @dev Sets the ERC20 data for a product.
     */
    function _setProductAction(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (
            string memory name,
            string memory symbol,
            uint256 premintAmount,
            address premintReceiver,
            bool revertOnMaxSupplyReached,
            uint256 maxSupply,
            uint256 tokensPerUnit
        ) = abi.decode(params, (string, string, uint256, address, bool, uint256, uint256));

        if (tokensPerUnit == 0) revert InvalidTokensPerUnit();

        ERC20Mint_BaseToken token = tokenData[slicerId][productId].token;
        if (address(token) == address(0)) {
            token = new ERC20Mint_BaseToken(name, symbol, maxSupply);

            if (premintAmount != 0) {
                token.mint(premintReceiver, premintAmount);
            }
        } else {
            token.setMaxSupply(maxSupply);
        }

        tokenData[slicerId][productId] = ERC20Data(token, revertOnMaxSupplyReached, tokensPerUnit);
    }

    /**
     * @inheritdoc IOnchainAction
     */
    function actionParamsSchema() external pure returns (string memory) {
        return
        "string name,string symbol,uint256 premintAmount,address premintReceiver,uint256 maxSupply,uint256 tokensPerUnit";
    }
}
