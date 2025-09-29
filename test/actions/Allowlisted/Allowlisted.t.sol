// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductActionTest} from "@test/utils/RegistryProductActionTest.sol";
import {Merkle} from "@test/utils/murky/Merkle.sol";
import {Allowlisted} from "@/hooks/actions/Allowlisted/Allowlisted.sol";

uint256 constant slicerId = 0;
uint256 constant productId = 1;
uint256 constant variantId = 0;
uint256 constant variantIdAlt = 1;

contract AllowlistedTest is RegistryProductActionTest {
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
        allowlisted.configureProduct(slicerId, productId, variantId, abi.encode(root));

        assertTrue(allowlisted.merkleRoots(slicerId, productId, variantId) == root);
    }

    function testIsPurchaseAllowed() public {
        bytes32 root = m.getRoot(data);

        vm.prank(productOwner);
        allowlisted.configureProduct(slicerId, productId, variantId, abi.encode(root));

        bytes32[] memory proof = m.getProof(data, 0);
        assertTrue(allowlisted.isPurchaseAllowed(slicerId, productId, variantId, buyer, 0, abi.encode(proof)));
    }

    function testIsPurchaseAllowed_wrongProof() public {
        bytes32 root = m.getRoot(data);

        vm.prank(productOwner);
        allowlisted.configureProduct(slicerId, productId, variantId, abi.encode(root));

        bytes32[] memory wrongProof = m.getProof(data, 1);
        assertFalse(allowlisted.isPurchaseAllowed(slicerId, productId, variantId, buyer, 0, abi.encode(wrongProof)));
    }

    function testIsPurchaseAllowed_variantSpecificConfiguration() public {
        bytes32 root = m.getRoot(data);

        vm.prank(productOwner);
        allowlisted.configureProduct(slicerId, productId, variantId, abi.encode(root));

        address variantBuyer = address(0xBEEF);
        bytes32[] memory variantLeaves = new bytes32[](4);
        variantLeaves[0] = bytes32(keccak256(abi.encode(variantBuyer)));
        variantLeaves[1] = bytes32(keccak256(abi.encode(address(0xCAFE))));
        variantLeaves[2] = bytes32(keccak256(abi.encode(address(0xD00D))));
        variantLeaves[3] = bytes32(keccak256(abi.encode(address(0xFEED))));
        bytes32 variantRoot = m.getRoot(variantLeaves);

        vm.prank(productOwner);
        allowlisted.configureProduct(slicerId, productId, variantIdAlt, abi.encode(variantRoot));

        bytes32[] memory productProof = m.getProof(data, 0);
        assertTrue(allowlisted.isPurchaseAllowed(slicerId, productId, variantId, buyer, 0, abi.encode(productProof)));

        // Product-level allowlist should not apply to variant configuration
        assertFalse(allowlisted.isPurchaseAllowed(slicerId, productId, variantIdAlt, buyer, 0, abi.encode(productProof)));

        bytes32[] memory variantLeavesForProof = new bytes32[](variantLeaves.length);
        for (uint256 i; i < variantLeaves.length; ++i) {
            variantLeavesForProof[i] = variantLeaves[i];
        }
        bytes32[] memory variantProof = m.getProof(variantLeavesForProof, 0);
        assertTrue(
            allowlisted.isPurchaseAllowed(slicerId, productId, variantIdAlt, variantBuyer, 0, abi.encode(variantProof))
        );
    }
}
