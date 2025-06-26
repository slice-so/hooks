// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin-5.3.0/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin-5.3.0/interfaces/IERC1155.sol";
import {IProductsModule, OnchainAction, IOnchainAction} from "@/utils/OnchainAction.sol";
import {TokenType, NFTGate, NFTGates} from "./types/NFTGate.sol";

/**
 * @title   NFTGated
 * @notice  Action with NFT gate requirement.
 * @dev     Implements NFT gate functionality to products.
 * @author  Slice <jacopo.eth>
 */
contract NFTGated is OnchainAction {
    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => NFTGates gates)) public nftGates;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) OnchainAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc OnchainAction
     * @dev Checks if `account` owns the required amount of NFT tokens.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256,
        bytes memory,
        bytes memory
    ) public view override returns (bool isAllowed) {
        NFTGates memory nftGates_ = nftGates[slicerId][productId];

        uint256 totalOwned;
        unchecked {
            for (uint256 i; i < nftGates_.gates.length;) {
                NFTGate memory gate = nftGates_.gates[i];

                if (gate.tokenType == TokenType.ERC1155) {
                    if (IERC1155(gate.nft).balanceOf(account, gate.id) >= gate.minQuantity) {
                        ++totalOwned;
                    }
                } else if (IERC721(gate.nft).balanceOf(account) >= gate.minQuantity) {
                    ++totalOwned;
                }

                if (totalOwned >= nftGates_.minOwned) return true;

                ++i;
            }
        }
    }

    /**
     * @inheritdoc OnchainAction
     * @dev Sets the NFT gates for a product.
     */
    function _setProductAction(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (NFTGates memory nftGates_) = abi.decode(params, (NFTGates));

        nftGates[slicerId][productId].minOwned = nftGates_.minOwned;
        for (uint256 i = 0; i < nftGates_.gates.length; i++) {
            nftGates[slicerId][productId].gates.push(nftGates_.gates[i]);
        }
    }

    /**
     * @inheritdoc IOnchainAction
     */
    function actionParamsSchema() external pure returns (string memory) {
        return "(address nft,uint8 tokenType,uint80 id,uint8 minQuantity)[] nftGates,uint256 minOwned";
    }
}
