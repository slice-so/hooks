// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin-4.8.0/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin-4.8.0/interfaces/IERC1155.sol";
import {
    IProductsModule,
    RegistryOnchainAction,
    HookRegistry,
    IOnchainAction,
    IHookRegistry
} from "@/utils/RegistryOnchainAction.sol";
import {TokenType, NFTGate, NFTGates} from "./types/NFTGate.sol";

/**
 * @title   NFTGated
 * @notice  Onchain action registry for NFT gating.
 * @author  Slice <jacopo.eth>
 */
contract NFTGated is RegistryOnchainAction {
    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => NFTGates gates)) public nftGates;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryOnchainAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IOnchainAction
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
     * @inheritdoc HookRegistry
     * @dev Set the NFT gates for a product.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (NFTGates memory nftGates_) = abi.decode(params, (NFTGates));

        nftGates[slicerId][productId].minOwned = nftGates_.minOwned;
        for (uint256 i = 0; i < nftGates_.gates.length; i++) {
            nftGates[slicerId][productId].gates.push(nftGates_.gates[i]);
        }
    }

    /**
     * @inheritdoc IHookRegistry
     */
    function paramsSchema() external pure override returns (string memory) {
        return "(address nft,uint8 tokenType,uint80 id,uint8 minQuantity)[] nftGates,uint256 minOwned";
    }
}
