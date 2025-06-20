// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IProductsModule} from "../IProductsModule.sol";

/**
 * @notice  Pricing strategy inheritable contract.
 * @author  Slice <jacopo.eth>
 */
abstract contract PricingStrategy {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotProductOwner();

    /*//////////////////////////////////////////////////////////////
                                 IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    IProductsModule public immutable productsModule;

    constructor(IProductsModule _productsModule) {
        productsModule = _productsModule;
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies if msg.sender is the product owner.
     */
    modifier onlyProductOwner(uint256 slicerId, uint256 productId) {
        if (!productsModule.isProductOwner(slicerId, productId, msg.sender)) {
            revert NotProductOwner();
        }
        _;
    }

    /**
     * @notice Function called by Slice protocol to calculate current product price.
     *
     * @param slicerId ID of the slicer being queried
     * @param productId ID of the product being queried
     * @param currency Currency chosen for the purchase
     * @param quantity Number of units purchased
     * @param buyer Address of the buyer
     * @param data Additional data used to calculate price
     *
     * @return ethPrice and currencyPrice of product.
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data
    ) external view virtual returns (uint256 ethPrice, uint256 currencyPrice);
}
