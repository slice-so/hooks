// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistryOnchainActionTest} from "@test/utils/RegistryOnchainActionTest.sol";
import {NFTGated, NFTGates, NFTGate, TokenType} from "@/hooks/actions/NFTGated/NFTGated.sol";
import {MockERC721} from "@test/utils/mocks/MockERC721.sol";
import {MockERC1155} from "@test/utils/mocks/MockERC1155.sol";

import {console2} from "forge-std/console2.sol";

uint256 constant slicerId = 0;

contract NFTGatedTest is RegistryOnchainActionTest {
    NFTGated nftGated;
    MockERC721 nft721 = new MockERC721();
    MockERC1155 nft1155 = new MockERC1155();

    uint256[] productIds = [1, 2, 3, 4];

    function setUp() public {
        nftGated = new NFTGated(PRODUCTS_MODULE);
        _setHook(address(nftGated));
    }

    function testConfigureProduct() public {
        NFTGates[] memory nftGates = generateNFTGates();

        vm.startPrank(productOwner);
        for (uint256 i = 0; i < productIds.length; i++) {
            nftGated.configureProduct(slicerId, productIds[i], abi.encode(nftGates[i]));
            assertEq(nftGated.nftGates(slicerId, productIds[i]), nftGates[i].minOwned);
        }
        vm.stopPrank();
    }

    function testIsPurchaseAllowed() public {
        NFTGates[] memory nftGates = generateNFTGates();

        vm.startPrank(productOwner);
        for (uint256 i = 0; i < productIds.length; i++) {
            nftGated.configureProduct(slicerId, productIds[i], abi.encode(nftGates[i]));
        }
        vm.stopPrank();

        // Mint both nfts to buyer, and only one of each to buyer2 and buyer3
        nft721.mint(buyer);
        nft1155.mint(buyer);
        nft721.mint(buyer2);
        nft1155.mint(buyer3);

        // buyer should be able to purchase all products
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[0], buyer, 0, "", ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[1], buyer, 0, "", ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[2], buyer, 0, "", ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[3], buyer, 0, "", ""));

        // buyer 2 should be able to purchase all products except product 2 and 4
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[0], buyer2, 0, "", ""));
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[1], buyer2, 0, "", ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[2], buyer2, 0, "", ""));
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[3], buyer2, 0, "", ""));

        // buyer 3 should be able to purchase all products except product 1 and 4
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[0], buyer3, 0, "", ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[1], buyer3, 0, "", ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[2], buyer3, 0, "", ""));
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[3], buyer3, 0, "", ""));
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL
    //////////////////////////////////////////////////////////////*/

    function generateNFTGates() public view returns (NFTGates[] memory nftGates) {
        nftGates = new NFTGates[](4);

        NFTGate memory gate721 = NFTGate(address(nft721), TokenType.ERC721, 1, 1);
        NFTGate memory gate1155 = NFTGate(address(nft1155), TokenType.ERC1155, 1, 1);

        // Only 721 is required
        NFTGate[] memory gates1 = new NFTGate[](1);
        gates1[0] = gate721;
        nftGates[0] = NFTGates(gates1, 1);

        // Only 1155 is required
        NFTGate[] memory gates2 = new NFTGate[](1);
        gates2[0] = gate1155;
        nftGates[1] = NFTGates(gates2, 1);

        // Either 721 or 1155 are required
        NFTGate[] memory gates3 = new NFTGate[](2);
        gates3[0] = gate721;
        gates3[1] = gate1155;
        nftGates[2] = NFTGates(gates3, 1);

        // Both 721 and 1155 are required
        NFTGate[] memory gates4 = new NFTGate[](2);
        gates4[0] = gate721;
        gates4[1] = gate1155;
        nftGates[3] = NFTGates(gates4, 2);
    }
}
