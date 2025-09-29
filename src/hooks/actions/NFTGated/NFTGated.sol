// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin-4.8.0/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin-4.8.0/interfaces/IERC1155.sol";
import {
    IProductsModule,
    RegistryProductAction,
    HookRegistry,
    IProductAction,
    IHookRegistry
} from "@/utils/RegistryProductAction.sol";
import {NftType, NFTGate, NFTGates} from "./types/NFTGate.sol";

/**
 * @title   NFTGated
 * @notice  Onchain action registry for NFT gating.
 * @author  Slice <jacopo.eth>
 */
contract NFTGated is RegistryProductAction {
    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => mapping(uint256 variantId => NFTGates gates))) public
        nftGates;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryProductAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductAction
     * @dev Checks if `account` owns the required amount of NFT tokens.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address buyer,
        uint256,
        bytes memory
    ) public view override returns (bool isAllowed) {
        NFTGates memory nftGates_ = nftGates[slicerId][productId][variantId];

        uint256 totalOwned;
        unchecked {
            for (uint256 i; i < nftGates_.gates.length;) {
                NFTGate memory gate = nftGates_.gates[i];

                if (gate.nftType == NftType.ERC1155) {
                    if (IERC1155(gate.nft).balanceOf(buyer, gate.id) >= gate.minQuantity) {
                        ++totalOwned;
                    }
                } else if (IERC721(gate.nft).balanceOf(buyer) >= gate.minQuantity) {
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
    function _configureProduct(uint256 slicerId, uint256 productId, uint256 variantId, bytes memory params)
        internal
        override
    {
        (NFTGate[] memory gates, uint256 minOwned) = abi.decode(params, (NFTGate[], uint256));

        delete nftGates[slicerId][productId][variantId].gates;

        nftGates[slicerId][productId][variantId].minOwned = minOwned;
        for (uint256 i = 0; i < gates.length; i++) {
            nftGates[slicerId][productId][variantId].gates.push(gates[i]);
        }
    }

    /**
     * @inheritdoc IHookRegistry
     */
    function configureProductSchema() external pure override returns (string memory) {
        return "(address nft,uint8 nftType,uint80 id,uint8 minQuantity)[] gates,uint256 minOwned";
    }
}
