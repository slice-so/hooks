// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistryOnchainActionTest} from "@test/utils/RegistryOnchainActionTest.sol";
import {Allowlisted} from "@/hooks/actions/Allowlisted/Allowlisted.sol";
import {Merkle} from "@murky/Merkle.sol";

uint256 constant slicerId = 0;
uint256 constant productId = 1;

contract AllowlistedTest is RegistryOnchainActionTest {
    Allowlisted allowlisted;
    Merkle m;
    bytes32[] data;

    function setUp() public {
        allowlisted = new Allowlisted(PRODUCTS_MODULE);
        _setHook(address(allowlisted));

        m = new Merkle();
        data = new bytes32[](4);
        data[0] = bytes32(keccak256(abi.encode(buyer)));
        data[1] = bytes32(keccak256(abi.encode(address(1))));
        data[2] = bytes32(keccak256(abi.encode(address(2))));
        data[3] = bytes32(keccak256(abi.encode(address(3))));
    }

    function testConfigureProduct() public {
        bytes32 root = m.getRoot(data);

        vm.prank(productOwner);
        allowlisted.configureProduct(slicerId, productId, abi.encode(root));

        assertTrue(allowlisted.merkleRoots(slicerId, productId) == root);
    }

    function testIsPurchaseAllowed() public {
        bytes32 root = m.getRoot(data);

        vm.prank(productOwner);
        allowlisted.configureProduct(slicerId, productId, abi.encode(root));

        bytes32[] memory proof = m.getProof(data, 0);
        assertTrue(allowlisted.isPurchaseAllowed(slicerId, productId, buyer, 0, "", abi.encode(proof)));
    }

    function testIsPurchaseAllowed_wrongProof() public {
        bytes32 root = m.getRoot(data);

        vm.prank(productOwner);
        allowlisted.configureProduct(slicerId, productId, abi.encode(root));

        bytes32[] memory wrongProof = m.getProof(data, 1);
        assertFalse(allowlisted.isPurchaseAllowed(slicerId, productId, buyer, 0, "", abi.encode(wrongProof)));
    }
}
