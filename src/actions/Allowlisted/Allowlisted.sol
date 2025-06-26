// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleProof} from "@openzeppelin-5.3.0/utils/cryptography/MerkleProof.sol";
import {IProductsModule, OnchainAction, IOnchainAction} from "@/utils/OnchainAction.sol";

/**
 * @title   Allowlisted
 * @notice  Action with allowlist requirement.
 * @dev     Implements allowlist functionality to products.
 * @author  Slice <jacopo.eth>
 */
contract Allowlisted is OnchainAction {
    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => bytes32 merkleRoot)) public merkleRoots;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) OnchainAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc OnchainAction
     * @dev Checks if the account is in the allowlist.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256,
        bytes memory,
        bytes memory buyerCustomData
    ) public view override returns (bool isAllowed) {
        // Get Merkle proof from buyerCustomData
        bytes32[] memory proof = abi.decode(buyerCustomData, (bytes32[]));

        // Generate leaf from account address
        bytes32 leaf = keccak256(abi.encodePacked(account));
        bytes32 root = merkleRoots[slicerId][productId];

        // Check if Merkle proof is valid
        isAllowed = MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @inheritdoc OnchainAction
     * @dev Sets the Merkle root for the allowlist.
     */
    function _setProductAction(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (bytes32 merkleRoot) = abi.decode(params, (bytes32));
        merkleRoots[slicerId][productId] = merkleRoot;
    }

    /**
     * @inheritdoc IOnchainAction
     */
    function actionParamsSchema() external pure returns (string memory) {
        return "bytes32 merkleRoot";
    }
}
