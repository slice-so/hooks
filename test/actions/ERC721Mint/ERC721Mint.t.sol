// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductActionTest} from "@test/utils/RegistryProductActionTest.sol";
import {ERC721Mint} from "@/hooks/actions/ERC721Mint/ERC721Mint.sol";
import {ERC721Data} from "@/hooks/actions/ERC721Mint/types/ERC721Data.sol";
import {ERC721Mint_BaseToken, MAX_ROYALTY} from "@/hooks/actions/ERC721Mint/utils/ERC721Mint_BaseToken.sol";

import {console2} from "forge-std/console2.sol";

uint256 constant slicerId = 0;

contract ERC721MintTest is RegistryProductActionTest {
    ERC721Mint erc721Mint;

    uint256[] productIds = [1, 2, 3, 4];

    function setUp() public {
        erc721Mint = new ERC721Mint(PRODUCTS_MODULE);
        _setHook(address(erc721Mint));
    }

    function testConfigureProduct() public {
        vm.startPrank(productOwner);

        // Configure product 1: Standard NFT with max supply and royalties
        erc721Mint.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                "Test NFT 1", // name
                "TNT1", // symbol
                productOwner, // royaltyReceiver
                500, // royaltyFraction (5%)
                "https://api.example.com/metadata/", // baseURI
                "https://api.example.com/fallback.json", // tokenURI
                true, // revertOnMaxSupplyReached
                1000 // maxSupply
            )
        );

        // Configure product 2: NFT without max supply limit
        erc721Mint.configureProduct(
            slicerId,
            productIds[1],
            abi.encode(
                "Test NFT 2", // name
                "TNT2", // symbol
                address(0), // royaltyReceiver (no royalties)
                0, // royaltyFraction
                "", // baseURI (empty)
                "https://api.example.com/single.json", // tokenURI
                false, // revertOnMaxSupplyReached
                0 // maxSupply (unlimited)
            )
        );

        // Configure product 3: NFT with revert on max supply
        erc721Mint.configureProduct(
            slicerId,
            productIds[2],
            abi.encode(
                "Test NFT 3", // name
                "TNT3", // symbol
                buyer, // royaltyReceiver
                1000, // royaltyFraction (10%)
                "ipfs://QmHash/", // baseURI
                "", // tokenURI (empty)
                true, // revertOnMaxSupplyReached
                100 // maxSupply
            )
        );

        vm.stopPrank();

        // Verify tokenData is set correctly
        (ERC721Mint_BaseToken token1, bool revertOnMaxSupply1) = erc721Mint.tokenData(slicerId, productIds[0]);
        assertEq(revertOnMaxSupply1, true);
        assertEq(token1.name(), "Test NFT 1");
        assertEq(token1.symbol(), "TNT1");
        assertEq(token1.maxSupply(), 1000);
        assertEq(token1.totalSupply(), 0);
        assertEq(token1.royaltyReceiver(), productOwner);
        assertEq(token1.royaltyFraction(), 500);
        assertEq(token1.baseURI_(), "https://api.example.com/metadata/");
        assertEq(token1.tokenURI_(), "https://api.example.com/fallback.json");

        (ERC721Mint_BaseToken token2, bool revertOnMaxSupply2) = erc721Mint.tokenData(slicerId, productIds[1]);
        assertEq(revertOnMaxSupply2, false);
        assertEq(token2.name(), "Test NFT 2");
        assertEq(token2.symbol(), "TNT2");
        assertEq(token2.maxSupply(), type(uint256).max);
        assertEq(token2.totalSupply(), 0);
        assertEq(token2.royaltyReceiver(), address(0));
        assertEq(token2.royaltyFraction(), 0);
        assertEq(token2.baseURI_(), "");
        assertEq(token2.tokenURI_(), "https://api.example.com/single.json");

        (ERC721Mint_BaseToken token3, bool revertOnMaxSupply3) = erc721Mint.tokenData(slicerId, productIds[2]);
        assertEq(revertOnMaxSupply3, true);
        assertEq(token3.maxSupply(), 100);
        assertEq(token3.royaltyReceiver(), buyer);
        assertEq(token3.royaltyFraction(), 1000);
        assertEq(token3.baseURI_(), "ipfs://QmHash/");
        assertEq(token3.tokenURI_(), "");
    }

    function testConfigureProduct_UpdateExistingToken() public {
        vm.startPrank(productOwner);

        // First configuration
        erc721Mint.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                "Test NFT", // name
                "TNT", // symbol
                productOwner, // royaltyReceiver
                250, // royaltyFraction (2.5%)
                "https://api.v1.com/", // baseURI
                "https://fallback.v1.json", // tokenURI
                true, // revertOnMaxSupplyReached
                500 // maxSupply
            )
        );

        (ERC721Mint_BaseToken token1,) = erc721Mint.tokenData(slicerId, productIds[0]);
        address tokenAddress = address(token1);

        // Second configuration - should update existing token
        erc721Mint.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                "Updated NFT", // name (ignored for existing token)
                "UNT", // symbol (ignored for existing token)
                buyer, // royaltyReceiver (updated)
                750, // royaltyFraction (updated to 7.5%)
                "https://api.v2.com/", // baseURI (updated)
                "https://fallback.v2.json", // tokenURI (updated)
                false, // revertOnMaxSupplyReached (updated)
                1000 // maxSupply (updated)
            )
        );

        (ERC721Mint_BaseToken token2, bool revertOnMaxSupply2) = erc721Mint.tokenData(slicerId, productIds[0]);

        // Token address should be the same
        assertEq(address(token2), tokenAddress);
        // Config should be updated
        assertEq(revertOnMaxSupply2, false);
        assertEq(token2.maxSupply(), 1000);
        assertEq(token2.royaltyReceiver(), buyer);
        assertEq(token2.royaltyFraction(), 750);
        assertEq(token2.baseURI_(), "https://api.v2.com/");
        assertEq(token2.tokenURI_(), "https://fallback.v2.json");
        // Original token properties remain
        assertEq(token2.name(), "Test NFT");
        assertEq(token2.symbol(), "TNT");

        vm.stopPrank();
    }

    function testRevert_configureProduct_InvalidRoyaltyFraction() public {
        vm.prank(productOwner);
        vm.expectRevert(ERC721Mint.InvalidRoyaltyFraction.selector);
        erc721Mint.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                "Test NFT", // name
                "TNT", // symbol
                productOwner, // royaltyReceiver
                MAX_ROYALTY + 1, // royaltyFraction (invalid - exceeds max)
                "https://api.example.com/", // baseURI
                "", // tokenURI
                false, // revertOnMaxSupplyReached
                1000 // maxSupply
            )
        );
    }

    function testOnProductPurchase() public {
        vm.startPrank(productOwner);

        // Configure products with different settings
        erc721Mint.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                "Test NFT 1", // name
                "TNT1", // symbol
                productOwner, // royaltyReceiver
                500, // royaltyFraction
                "https://api.example.com/", // baseURI
                "", // tokenURI
                true, // revertOnMaxSupplyReached
                1000 // maxSupply
            )
        );

        erc721Mint.configureProduct(
            slicerId,
            productIds[1],
            abi.encode(
                "Test NFT 2", // name
                "TNT2", // symbol
                address(0), // royaltyReceiver
                0, // royaltyFraction
                "", // baseURI
                "https://single.json", // tokenURI
                false, // revertOnMaxSupplyReached
                0 // maxSupply (unlimited)
            )
        );

        vm.stopPrank();

        (ERC721Mint_BaseToken token1,) = erc721Mint.tokenData(slicerId, productIds[0]);
        (ERC721Mint_BaseToken token2,) = erc721Mint.tokenData(slicerId, productIds[1]);

        // Test minting for product 1
        uint256 initialBalance1 = token1.balanceOf(buyer);
        uint256 initialSupply1 = token1.totalSupply();

        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[0], buyer, 3, "", "");

        assertEq(token1.balanceOf(buyer), initialBalance1 + 3);
        assertEq(token1.totalSupply(), initialSupply1 + 3);

        // Test minting for product 2
        uint256 initialBalance2 = token2.balanceOf(buyer2);
        uint256 initialSupply2 = token2.totalSupply();

        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[1], buyer2, 5, "", "");

        assertEq(token2.balanceOf(buyer2), initialBalance2 + 5);
        assertEq(token2.totalSupply(), initialSupply2 + 5);

        // Test multiple purchases
        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[0], buyer3, 2, "", "");
        assertEq(token1.balanceOf(buyer3), 2);
        assertEq(token1.totalSupply(), initialSupply1 + 5); // 3 + 2
    }

    function testOnProductPurchase_NoRevertOnMaxSupply() public {
        vm.prank(productOwner);

        // Configure product with max supply but revert disabled
        erc721Mint.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                "Test NFT", // name
                "TNT", // symbol
                productOwner, // royaltyReceiver
                0, // royaltyFraction
                "", // baseURI
                "", // tokenURI
                false, // revertOnMaxSupplyReached (disabled)
                5 // maxSupply (small for testing)
            )
        );

        (ERC721Mint_BaseToken token,) = erc721Mint.tokenData(slicerId, productIds[0]);

        // First purchase - should succeed
        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[0], buyer, 3, "", "");
        assertEq(token.totalSupply(), 3);

        // Second purchase - should succeed
        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[0], buyer2, 2, "", "");
        assertEq(token.totalSupply(), 5);

        // Third purchase - exceeds max supply but should not revert (mint will fail silently)
        uint256 balanceBefore = token.balanceOf(buyer3);
        uint256 supplyBefore = token.totalSupply();

        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[0], buyer3, 2, "", "");

        // Balance and supply should remain unchanged (mint failed silently)
        assertEq(token.balanceOf(buyer3), balanceBefore);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testRevert_onProductPurchase_MaxSupplyReached() public {
        vm.prank(productOwner);

        // Configure product with small max supply and revert enabled
        erc721Mint.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                "Test NFT", // name
                "TNT", // symbol
                productOwner, // royaltyReceiver
                0, // royaltyFraction
                "", // baseURI
                "", // tokenURI
                true, // revertOnMaxSupplyReached
                5 // maxSupply
            )
        );

        // First purchase - should succeed
        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[0], buyer, 3, "", "");

        (ERC721Mint_BaseToken token,) = erc721Mint.tokenData(slicerId, productIds[0]);
        assertEq(token.totalSupply(), 3);

        // Second purchase - should succeed (exactly at max supply)
        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[0], buyer2, 2, "", "");
        assertEq(token.totalSupply(), 5);

        // Third purchase - should revert (exceeds max supply)
        vm.expectRevert(ERC721Mint.MaxSupplyExceeded.selector);
        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[0], buyer3, 1, "", "");
    }

    function testTokenURI() public {
        vm.startPrank(productOwner);

        // Configure product with baseURI
        erc721Mint.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                "Test NFT", // name
                "TNT", // symbol
                address(0), // royaltyReceiver
                0, // royaltyFraction
                "https://api.example.com/metadata/", // baseURI
                "https://fallback.json", // tokenURI
                false, // revertOnMaxSupplyReached
                1000 // maxSupply
            )
        );

        // Configure product with only tokenURI (no baseURI)
        erc721Mint.configureProduct(
            slicerId,
            productIds[1],
            abi.encode(
                "Test NFT 2", // name
                "TNT2", // symbol
                address(0), // royaltyReceiver
                0, // royaltyFraction
                "", // baseURI (empty)
                "https://single-token.json", // tokenURI
                false, // revertOnMaxSupplyReached
                1000 // maxSupply
            )
        );

        vm.stopPrank();

        (ERC721Mint_BaseToken token1,) = erc721Mint.tokenData(slicerId, productIds[0]);
        (ERC721Mint_BaseToken token2,) = erc721Mint.tokenData(slicerId, productIds[1]);

        // Mint some tokens
        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[0], buyer, 2, "", "");

        vm.prank(address(PRODUCTS_MODULE));
        erc721Mint.onProductPurchase(slicerId, productIds[1], buyer, 1, "", "");

        // Test token URIs for product 1 (with baseURI)
        assertEq(token1.tokenURI(0), "https://api.example.com/metadata/0");
        assertEq(token1.tokenURI(1), "https://api.example.com/metadata/1");

        // Test token URI for product 2 (fallback tokenURI)
        assertEq(token2.tokenURI(0), "https://single-token.json");
    }

    function testRoyaltyInfo() public {
        vm.prank(productOwner);
        erc721Mint.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                "Test NFT", // name
                "TNT", // symbol
                productOwner, // royaltyReceiver
                500, // royaltyFraction (5%)
                "", // baseURI
                "", // tokenURI
                false, // revertOnMaxSupplyReached
                1000 // maxSupply
            )
        );

        (ERC721Mint_BaseToken token,) = erc721Mint.tokenData(slicerId, productIds[0]);

        // Test royalty calculation
        (address receiver, uint256 royaltyAmount) = token.royaltyInfo(0, 1000);
        assertEq(receiver, productOwner);
        assertEq(royaltyAmount, 50); // 5% of 1000

        (receiver, royaltyAmount) = token.royaltyInfo(0, 2000);
        assertEq(receiver, productOwner);
        assertEq(royaltyAmount, 100); // 5% of 2000
    }
}
