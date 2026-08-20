// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin-4.8.0/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin-4.8.0/interfaces/IERC1155.sol";
import {
    HookRegistry,
    IProductsModule,
    RegistryAction,
    IProductAction,
    IProductTypeAction,
    ISlicerAction,
    ProductLineItem
} from "@/utils/RegistryAction.sol";
import {ProductHookRegistry, IProductHookRegistry} from "@/utils/RegistryProductAction.sol";
import {NftType, NFTGate, NFTGates} from "./types/NFTGate.sol";

/**
 * @title   NFTGated
 * @notice  Onchain action registry for NFT gating.
 * @author  Slice <jacopo.eth>
 */
contract NFTGated is RegistryAction {
    error InvalidNFT();

    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => mapping(uint256 variantId => NFTGates gates))) public
        nftGates;
    mapping(uint256 slicerId => mapping(uint256 productTypeId => NFTGates gates)) public productTypeNftGates;
    mapping(uint256 slicerId => NFTGates gates) public slicerNftGates;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryAction(productsModuleAddress) {}

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
        isAllowed = handleIsPurchaseAllowed(nftGates[slicerId][productId][variantId], buyer);
    }

    /**
     * @inheritdoc IProductTypeAction
     * @dev Checks if `account` owns the required amount of NFT tokens.
     */
    function isProductTypePurchaseAllowed(uint256 slicerId, uint256 productTypeId, address buyer, uint256)
        public
        view
        override
        returns (bool isAllowed)
    {
        isAllowed = handleIsPurchaseAllowed(productTypeNftGates[slicerId][productTypeId], buyer);
    }

    /**
     * @inheritdoc ISlicerAction
     * @dev Checks if `account` owns the required amount of NFT tokens.
     */
    function isSlicerPurchaseAllowed(uint256 slicerId, address buyer, ProductLineItem[] memory)
        public
        view
        override
        returns (bool isAllowed)
    {
        isAllowed = handleIsPurchaseAllowed(slicerNftGates[slicerId], buyer);
    }

    /**
     * @inheritdoc ProductHookRegistry
     * @dev Set the NFT gates for a product.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, uint256 variantId, bytes memory params)
        internal
        override
    {
        delete nftGates[slicerId][productId][variantId].gates;
        handleConfigure(nftGates[slicerId][productId][variantId], params);
    }

    /**
     * @inheritdoc HookRegistry
     * @dev Set the NFT gates for a product type.
     */
    function _configureProductType(uint256 slicerId, uint256 productTypeId, bytes memory params) internal override {
        delete productTypeNftGates[slicerId][productTypeId].gates;
        handleConfigure(productTypeNftGates[slicerId][productTypeId], params);
    }

    /**
     * @inheritdoc HookRegistry
     * @dev Set the NFT gates for a slicer.
     */
    function _configureSlicer(uint256 slicerId, bytes memory params) internal override {
        delete slicerNftGates[slicerId].gates;
        handleConfigure(slicerNftGates[slicerId], params);
    }

    /**
     * @inheritdoc IProductHookRegistry
     */
    function configureProductSchema() public pure override returns (string memory) {
        return "(address nft,uint8 nftType,uint80 id,uint8 minQuantity)[] gates,uint256 minOwned";
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL
    //////////////////////////////////////////////////////////////*/

    function handleConfigure(NFTGates storage gatesStorage, bytes memory params) internal {
        (NFTGate[] memory gates, uint256 minOwned) = abi.decode(params, (NFTGate[], uint256));

        gatesStorage.minOwned = minOwned;
        for (uint256 i = 0; i < gates.length; i++) {
            if (gates[i].nftType == NftType.ERC721) {
                if (!IERC721(gates[i].nft).supportsInterface(type(IERC721).interfaceId)) {
                    revert InvalidNFT();
                }
            } else if (!IERC1155(gates[i].nft).supportsInterface(type(IERC1155).interfaceId)) {
                revert InvalidNFT();
            }
            gatesStorage.gates.push(gates[i]);
        }
    }

    function handleIsPurchaseAllowed(NFTGates memory nftGates_, address buyer) internal view returns (bool) {
        // If no gates, allow purchase
        if (nftGates_.gates.length == 0) {
            return true;
        }

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

        return false;
    }
}
