// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20Gate} from "./types/ERC20Gate.sol";
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

/**
 * @title   ERC20Gated
 * @notice  Onchain action registry for ERC20 gating.
 * @author  Slice <jacopo.eth>
 */
contract ERC20Gated is RegistryAction {
    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => mapping(uint256 variantId => ERC20Gate[] gates))) public
        tokenGates;
    mapping(uint256 slicerId => mapping(uint256 productTypeId => ERC20Gate[] gates)) public productTypeTokenGates;
    mapping(uint256 slicerId => ERC20Gate[] gates) public slicerTokenGates;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductAction
     * @dev Checks if `account` owns the required amount of all ERC20 tokens.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address buyer,
        uint256,
        bytes memory
    ) public view override returns (bool) {
        ERC20Gate[] memory gates = tokenGates[slicerId][productId][variantId];

        return handleIsPurchaseAllowed(gates, buyer);
    }

    /**
     * @inheritdoc IProductTypeAction
     * @dev Checks if `account` owns the required amount of all ERC20 tokens.
     */
    function isProductTypePurchaseAllowed(uint256 slicerId, uint256 productTypeId, address buyer, uint256)
        public
        view
        override
        returns (bool)
    {
        ERC20Gate[] memory gates = productTypeTokenGates[slicerId][productTypeId];

        return handleIsPurchaseAllowed(gates, buyer);
    }

    /**
     * @inheritdoc ISlicerAction
     * @dev Checks if `account` owns the required amount of all ERC20 tokens.
     */
    function isSlicerPurchaseAllowed(uint256 slicerId, address buyer, ProductLineItem[] memory)
        public
        view
        override
        returns (bool)
    {
        ERC20Gate[] memory gates = slicerTokenGates[slicerId];

        return handleIsPurchaseAllowed(gates, buyer);
    }

    /**
     * @inheritdoc ProductHookRegistry
     * @dev Sets the ERC20 gates for a product.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, uint256 variantId, bytes memory params)
        internal
        override
    {
        delete tokenGates[slicerId][productId][variantId];

        handleConfigure(tokenGates[slicerId][productId][variantId], params);
    }

    /**
     * @inheritdoc HookRegistry
     * @dev Sets the ERC20 gates for a product type.
     */
    function _configureProductType(uint256 slicerId, uint256 productTypeId, bytes memory params) internal override {
        delete productTypeTokenGates[slicerId][productTypeId];

        handleConfigure(productTypeTokenGates[slicerId][productTypeId], params);
    }

    /**
     * @inheritdoc HookRegistry
     * @dev Sets the ERC20 gates for a slicer.
     */
    function _configureSlicer(uint256 slicerId, bytes memory params) internal override {
        delete slicerTokenGates[slicerId];

        handleConfigure(slicerTokenGates[slicerId], params);
    }

    /**
     * @inheritdoc IProductHookRegistry
     */
    function configureProductSchema() public pure override returns (string memory) {
        return "(address erc20,uint256 amount)[] erc20Gates";
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL
    //////////////////////////////////////////////////////////////*/
    function handleConfigure(ERC20Gate[] storage gatesStorage, bytes memory params) internal {
        (ERC20Gate[] memory gates) = abi.decode(params, (ERC20Gate[]));

        for (uint256 i = 0; i < gates.length; i++) {
            gatesStorage.push(gates[i]);
        }
    }

    function handleIsPurchaseAllowed(ERC20Gate[] memory gates, address buyer) internal view returns (bool) {
        ERC20Gate memory gate;
        for (uint256 i = 0; i < gates.length; i++) {
            gate = gates[i];
            uint256 accountBalance = gate.erc20.balanceOf(buyer);
            if (accountBalance < gate.amount) {
                return false;
            }
        }

        return true;
    }
}
