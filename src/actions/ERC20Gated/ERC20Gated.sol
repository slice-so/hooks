// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Gate} from "./types/ERC20Gate.sol";
import {IProductsModule, OnchainAction, IOnchainAction} from "@/utils/OnchainAction.sol";

/**
 * @title   ERC20Gated
 * @notice  Action with ERC20 gate requirement.
 * @dev     Implements ERC20 gate functionality to products.
 * @author  Slice <jacopo.eth>
 */
contract ERC20Gated is OnchainAction {
    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => ERC20Gate[] gates)) public tokenGates;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) OnchainAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc OnchainAction
     * @dev Checks if `account` owns the required amount of all ERC20 tokens.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256,
        bytes memory,
        bytes memory
    ) public view override returns (bool) {
        ERC20Gate[] memory gates = tokenGates[slicerId][productId];

        for (uint256 i = 0; i < gates.length; i++) {
            ERC20Gate memory gate = gates[i];
            uint256 accountBalance = gate.erc20.balanceOf(account);
            if (accountBalance < gate.amount) {
                return false;
            }
        }

        return true;
    }

    /**
     * @inheritdoc OnchainAction
     * @dev Sets the ERC20 gates for a product.
     */
    function _setProductAction(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (ERC20Gate[] memory gates) = abi.decode(params, (ERC20Gate[]));

        for (uint256 i = 0; i < gates.length; i++) {
            tokenGates[slicerId][productId].push(gates[i]);
        }
    }

    /**
     * @inheritdoc IOnchainAction
     */
    function actionParamsSchema() external pure returns (string memory) {
        return "(address erc20,uint256 amount)[] erc20Gates";
    }
}
