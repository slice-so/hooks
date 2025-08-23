// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin-4.8.0/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin-4.8.0/token/ERC1155/IERC1155.sol";
import {HookRegistry, IHookRegistry, IProductsModule} from "@/utils/RegistryProductPrice.sol";
import {DiscountParams, TieredDiscount} from "../TieredDiscount.sol";
import {NFTType} from "../types/DiscountParams.sol";

/**
 * @title   NFTDiscount
 * @notice  Pricing strategy registry for discounts based on NFT ownership
 * @author  Slice <jacopo.eth>
 */
contract NFTDiscount is TieredDiscount {
    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) TieredDiscount(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc HookRegistry
     * @notice Set base price and NFT discounts for a product.
     * @dev Discounts must be sorted in descending order and expressed as a percentage of the base price as a 4 decimal fixed point number.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (DiscountParams[] memory newDiscounts) = abi.decode(params, (DiscountParams[]));

        DiscountParams[] storage productDiscount = discounts[slicerId][productId];

        delete discounts[slicerId][productId];

        uint256 prevDiscountValue;
        DiscountParams memory discountParam;
        for (uint256 i; i < newDiscounts.length;) {
            discountParam = newDiscounts[i];

            // Check relative discount doesn't exceed max value of 1e4 (100%)
            if (discountParam.discount > 1e4) {
                revert InvalidRelativeAmount();
            }

            if (discountParam.minQuantity == 0) {
                revert InvalidMinQuantity();
            }

            // Check discounts are sorted in descending order
            if (i > 0) {
                if (discountParam.discount > prevDiscountValue) {
                    revert DiscountsNotDescending(discountParam);
                }
            }
            prevDiscountValue = discountParam.discount;

            productDiscount.push(discountParam);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IHookRegistry
     */
    function paramsSchema() external pure override returns (string memory) {
        return "(address nft,uint80 discount,uint8 minQuantity,uint8 nftType,uint256 tokenId)[] discounts";
    }

    /**
     * @inheritdoc TieredDiscount
     * @notice Base price is returned if user does not have a discount.
     */
    function _productPrice(
        uint256,
        uint256,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory,
        uint256 basePrice,
        DiscountParams[] memory discountParams
    ) internal view virtual override returns (uint256 ethPrice, uint256 currencyPrice) {
        uint256 discount = _getHighestDiscount(discountParams, buyer);

        uint256 price = discount != 0 ? _getDiscountedPrice(basePrice, discount, quantity) : quantity * basePrice;

        if (currency == address(0)) {
            ethPrice = price;
        } else {
            currencyPrice = price;
        }
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the highest discount available for a user, based on owned NFTs.
     *
     * @param discountParams `ProductDiscounts` struct
     * @param buyer Address of the buyer
     *
     * @return Discount value
     */
    function _getHighestDiscount(DiscountParams[] memory discountParams, address buyer)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 length = discountParams.length;
        DiscountParams memory el;

        address prevAsset;
        uint256 prevTokenId;
        uint256 nftBalance;
        for (uint256 i; i < length;) {
            el = discountParams[i];

            // Skip retrieving balance if asset is the same as previous iteration
            if (el.nftType == NFTType.ERC1155) {
                if (prevAsset != el.nft || prevTokenId != el.tokenId) {
                    nftBalance = IERC1155(el.nft).balanceOf(buyer, el.tokenId);
                }
            } else if (el.nftType == NFTType.ERC721) {
                if (prevAsset != el.nft) {
                    nftBalance = IERC721(el.nft).balanceOf(buyer);
                }
            }

            // Check if user has at enough NFT to qualify for the discount
            if (nftBalance >= el.minQuantity) {
                return el.discount;
            }

            prevAsset = el.nft;
            prevTokenId = el.tokenId;

            unchecked {
                ++i;
            }
        }

        // Otherwise default to no discount.
        return 0;
    }

    /**
     * @notice Calculate price based on `discountType`
     *
     * @param basePrice Base price of the product
     * @param discount Discount value based on `discountType`
     * @param quantity Number of units purchased
     *
     * @return price of product inclusive of discount.
     */
    function _getDiscountedPrice(uint256 basePrice, uint256 discount, uint256 quantity)
        internal
        pure
        virtual
        returns (uint256 price)
    {
        uint256 k;
        /// @dev discount cannot be higher than 1e4, as it's checked on `setProductPrice`
        unchecked {
            k = 1e4 - discount;
        }

        price = (basePrice * k * quantity) / 1e4;
    }
}
