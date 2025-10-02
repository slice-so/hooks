// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin-4.8.0/token/ERC20/ERC20.sol";
import {RegistryProductActionTest} from "@test/utils/RegistryProductActionTest.sol";
import {MockNFTGated, NFTGated} from "./mocks/MockNFTGated.sol";
import {NFTGate, NftType} from "@/hooks/actions/NFTGated/NFTGated.sol";
import {NFTGates} from "@/hooks/actions/NFTGated/types/NFTGate.sol";
import {MockERC721} from "@test/utils/mocks/MockERC721.sol";
import {MockERC1155} from "@test/utils/mocks/MockERC1155.sol";

uint256 constant slicerId = 0;
uint256 constant variantId = 0;
uint256 constant variantIdAlt = 1;

contract NFTGatedTest is RegistryProductActionTest {
    MockNFTGated nftGated;
    MockERC721 nft721 = new MockERC721();
    MockERC1155 nft1155 = new MockERC1155();

    uint256[] productIds = [1, 2, 3, 4];

    function setUp() public {
        nftGated = new MockNFTGated(PRODUCTS_MODULE);
        _setHook(address(nftGated));
    }

    function testConfigureProduct() public {
        NFTGates[] memory nftGates = generateNFTGates();

        vm.startPrank(productOwner);
        for (uint256 i = 0; i < productIds.length; i++) {
            nftGated.configureProduct(slicerId, productIds[i], variantId, encodeNFTGates(nftGates[i]));
            assertEq(nftGated.nftGates(slicerId, productIds[i], variantId), nftGates[i].minOwned);
        }
        vm.stopPrank();
    }

    function testReconfigureProduct() public {
        NFTGates[] memory nftGates = generateNFTGates();

        vm.startPrank(productOwner);

        nftGated.configureProduct(slicerId, productIds[2], variantId, encodeNFTGates(nftGates[2]));
        assertEq(nftGated.gates(slicerId, productIds[2], variantId)[0].nft, address(nft721));
        assertEq(nftGated.gates(slicerId, productIds[2], variantId)[1].nft, address(nft1155));
        assertEq(nftGated.gates(slicerId, productIds[2], variantId).length, 2);

        nftGated.configureProduct(slicerId, productIds[2], variantId, encodeNFTGates(nftGates[1]));
        assertEq(nftGated.gates(slicerId, productIds[2], variantId)[0].nft, address(nft1155));
        assertEq(nftGated.gates(slicerId, productIds[2], variantId).length, 1);

        vm.stopPrank();
    }

    function testIsPurchaseAllowed() public {
        NFTGates[] memory nftGates = generateNFTGates();

        vm.startPrank(productOwner);
        for (uint256 i = 0; i < productIds.length; i++) {
            nftGated.configureProduct(slicerId, productIds[i], variantId, encodeNFTGates(nftGates[i]));
        }
        vm.stopPrank();

        // Mint both nfts to buyer, and only one of each to buyer2 and buyer3
        nft721.mint(buyer);
        nft1155.mint(buyer);
        nft721.mint(buyer2);
        nft1155.mint(buyer3);

        // buyer should be able to purchase all products
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[0], variantId, buyer, 0, ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[1], variantId, buyer, 0, ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[2], variantId, buyer, 0, ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[3], variantId, buyer, 0, ""));

        // buyer2 should be able to purchase all products except product 2 and 4
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[0], variantId, buyer2, 0, ""));
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[1], variantId, buyer2, 0, ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[2], variantId, buyer2, 0, ""));
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[3], variantId, buyer2, 0, ""));

        // buyer3 should be able to purchase all products except product 1 and 4
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[0], variantId, buyer3, 0, ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[1], variantId, buyer3, 0, ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[2], variantId, buyer3, 0, ""));
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[3], variantId, buyer3, 0, ""));
    }

    function testIsPurchaseAllowed_variantSpecificConfiguration() public {
        NFTGate[] memory productVariantGates = new NFTGate[](1);
        productVariantGates[0] = NFTGate(address(nft721), NftType.ERC721, 1, 1);
        NFTGate[] memory variantSpecificGates = new NFTGate[](1);
        variantSpecificGates[0] = NFTGate(address(nft1155), NftType.ERC1155, 1, 1);

        vm.startPrank(productOwner);
        nftGated.configureProduct(slicerId, productIds[0], variantId, encodeNFTGates(NFTGates(productVariantGates, 1)));
        nftGated.configureProduct(
            slicerId, productIds[0], variantIdAlt, encodeNFTGates(NFTGates(variantSpecificGates, 1))
        );
        vm.stopPrank();

        nft721.mint(buyer);
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[0], variantId, buyer, 0, ""));
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[0], variantIdAlt, buyer, 0, ""));

        nft1155.mint(buyer);
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[0], variantIdAlt, buyer, 0, ""));

        nft1155.mint(buyer2);
        assertFalse(nftGated.isPurchaseAllowed(slicerId, productIds[0], variantId, buyer2, 0, ""));
        assertTrue(nftGated.isPurchaseAllowed(slicerId, productIds[0], variantIdAlt, buyer2, 0, ""));
    }

    function testRevert_ConfigureProduct_InvalidNFT() public {
        NFTGates[] memory nftGates = new NFTGates[](1);

        // Only 721 is required
        NFTGate[] memory gates1 = new NFTGate[](1);
        gates1[0] = NFTGate(address(new TestERC20()), NftType.ERC721, 1, 1);
        nftGates[0] = NFTGates(gates1, 1);

        vm.startPrank(productOwner);

        vm.expectRevert(NFTGated.InvalidNFT.selector);
        nftGated.configureProduct(slicerId, productIds[0], variantId, encodeNFTGates(nftGates[0]));

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL
    //////////////////////////////////////////////////////////////*/

    function generateNFTGates() public view returns (NFTGates[] memory nftGates) {
        nftGates = new NFTGates[](4);

        NFTGate memory gate721 = NFTGate(address(nft721), NftType.ERC721, 1, 1);
        NFTGate memory gate1155 = NFTGate(address(nft1155), NftType.ERC1155, 1, 1);

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

    function encodeNFTGates(NFTGates memory nftGates_) internal pure returns (bytes memory) {
        return abi.encode(nftGates_.gates, nftGates_.minOwned);
    }
}

contract TestERC20 is ERC20 {
    constructor() ERC20("Test", "TST") {}

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return false;
    }
}
