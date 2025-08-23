// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleProof} from "@openzeppelin-4.8.0/utils/cryptography/MerkleProof.sol";
import {
    IProductsModule,
    RegistryProductAction,
    HookRegistry,
    IProductAction,
    IHookRegistry
} from "@/utils/RegistryProductAction.sol";

/**
 * @title   Allowlisted
 * @notice  Onchain action registry for allowlist requirement.
 * @author  Slice <jacopo.eth>
 */
contract Allowlisted is RegistryProductAction {
    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => bytes32 merkleRoot)) public merkleRoots;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryProductAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductAction
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

        uint256 leafValue = uint256(uint160(account));

        // Generate leaf from account address
        bytes32 leaf;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, leafValue)
            leaf := keccak256(0x00, 0x20)
        }

        bytes32 root = merkleRoots[slicerId][productId];

        // Check if Merkle proof is valid
        isAllowed = MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @inheritdoc HookRegistry
     * @dev Sets the Merkle root for the allowlist.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        (bytes32 merkleRoot) = abi.decode(params, (bytes32));
        merkleRoots[slicerId][productId] = merkleRoot;
    }

    /**
     * @inheritdoc IHookRegistry
     */
    function paramsSchema() external pure override returns (string memory) {
        return "bytes32 merkleRoot";
    }
}
