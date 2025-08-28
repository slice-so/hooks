// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistryProductPriceActionTest} from "@test/utils/RegistryProductPriceActionTest.sol";
import {FirstForFree} from "@/hooks/pricingActions/FirstForFree/FirstForFree.sol";
import {ProductParams} from "@/hooks/pricingActions/FirstForFree/types/ProductParams.sol";
import {TokenCondition, TokenType} from "@/hooks/pricingActions/FirstForFree/types/TokenCondition.sol";
import {ITokenERC1155} from "@/hooks/pricingActions/FirstForFree/utils/ITokenERC1155.sol";
import {MockERC721} from "@test/utils/mocks/MockERC721.sol";

import {console2} from "forge-std/console2.sol";

uint256 constant slicerId = 0;

contract MockERC1155Token is ITokenERC1155 {
    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => uint256) public mintedAmounts;

    function mintTo(address to, uint256 tokenId, string calldata, uint256 amount) external {
        balanceOf[to][tokenId] += amount;
        mintedAmounts[to] += amount;
    }

    function setBalance(address owner, uint256 tokenId, uint256 amount) external {
        balanceOf[owner][tokenId] = amount;
    }
}

contract FirstForFreeTest is RegistryProductPriceActionTest {
    FirstForFree firstForFree;
    MockERC721 mockERC721;
    MockERC1155Token mockERC1155;
    MockERC1155Token mockMintToken;

    uint256[] productIds = [1, 2, 3, 4];
    uint256 constant USDC_PRICE = 1000000; // 1 USDC (6 decimals)

    function setUp() public {
        firstForFree = new FirstForFree(PRODUCTS_MODULE);
        _setHook(address(firstForFree));

        mockERC721 = new MockERC721();
        mockERC1155 = new MockERC1155Token();
        mockMintToken = new MockERC1155Token();
    }

    function testConfigureProduct() public {
        vm.startPrank(productOwner);

        // Configure product 1: Basic free units without token conditions
        TokenCondition[] memory noConditions = new TokenCondition[](0);
        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE, // usdcPrice
                noConditions, // eligibleTokens (empty)
                address(mockMintToken), // mintToken
                uint88(1), // mintTokenId
                uint8(3) // freeUnits
            )
        );

        // Configure product 2: With ERC721 token condition
        TokenCondition[] memory erc721Conditions = new TokenCondition[](1);
        erc721Conditions[0] = TokenCondition({
            tokenAddress: address(mockERC721),
            tokenType: TokenType.ERC721,
            tokenId: 0, // Not used for ERC721
            minQuantity: 1
        });

        firstForFree.configureProduct(
            slicerId,
            productIds[1],
            abi.encode(
                USDC_PRICE * 2, // usdcPrice
                erc721Conditions, // eligibleTokens
                address(0), // mintToken (no minting)
                uint88(0), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        // Configure product 3: With ERC1155 token condition
        TokenCondition[] memory erc1155Conditions = new TokenCondition[](1);
        erc1155Conditions[0] = TokenCondition({
            tokenAddress: address(mockERC1155),
            tokenType: TokenType.ERC1155,
            tokenId: 5,
            minQuantity: 10
        });

        firstForFree.configureProduct(
            slicerId,
            productIds[2],
            abi.encode(
                USDC_PRICE / 2, // usdcPrice
                erc1155Conditions, // eligibleTokens
                address(mockMintToken), // mintToken
                uint88(2), // mintTokenId
                uint8(1) // freeUnits
            )
        );

        // Configure product 4: Multiple token conditions
        TokenCondition[] memory multipleConditions = new TokenCondition[](2);
        multipleConditions[0] =
            TokenCondition({tokenAddress: address(mockERC721), tokenType: TokenType.ERC721, tokenId: 0, minQuantity: 1});
        multipleConditions[1] = TokenCondition({
            tokenAddress: address(mockERC1155),
            tokenType: TokenType.ERC1155,
            tokenId: 3,
            minQuantity: 5
        });

        firstForFree.configureProduct(
            slicerId,
            productIds[3],
            abi.encode(
                USDC_PRICE * 3, // usdcPrice
                multipleConditions, // eligibleTokens
                address(mockMintToken), // mintToken
                uint88(3), // mintTokenId
                uint8(5) // freeUnits
            )
        );

        vm.stopPrank();

        // Verify product 1 configuration
        (uint256 usdcPrice1, address mintToken1, uint88 mintTokenId1, uint8 freeUnits1) =
            firstForFree.usdcPrices(slicerId, productIds[0]);
        assertEq(usdcPrice1, USDC_PRICE);
        assertEq(mintToken1, address(mockMintToken));
        assertEq(mintTokenId1, 1);
        assertEq(freeUnits1, 3);

        // Verify product 2 configuration
        (uint256 usdcPrice2, address mintToken2, uint88 mintTokenId2, uint8 freeUnits2) =
            firstForFree.usdcPrices(slicerId, productIds[1]);
        assertEq(usdcPrice2, USDC_PRICE * 2);
        assertEq(mintToken2, address(0));
        assertEq(mintTokenId2, 0);
        assertEq(freeUnits2, 2);

        // Verify product 3 configuration
        (uint256 usdcPrice3, address mintToken3, uint88 mintTokenId3, uint8 freeUnits3) =
            firstForFree.usdcPrices(slicerId, productIds[2]);
        assertEq(usdcPrice3, USDC_PRICE / 2);
        assertEq(mintToken3, address(mockMintToken));
        assertEq(mintTokenId3, 2);
        assertEq(freeUnits3, 1);

        // Verify product 4 configuration
        (uint256 usdcPrice4, address mintToken4, uint88 mintTokenId4, uint8 freeUnits4) =
            firstForFree.usdcPrices(slicerId, productIds[3]);
        assertEq(usdcPrice4, USDC_PRICE * 3);
        assertEq(mintToken4, address(mockMintToken));
        assertEq(mintTokenId4, 3);
        assertEq(freeUnits4, 5);
    }

    function testProductPrice_NoConditions() public {
        vm.prank(productOwner);

        // Configure product with no token conditions
        TokenCondition[] memory noConditions = new TokenCondition[](0);
        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE, // usdcPrice
                noConditions, // eligibleTokens (empty)
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        // First purchase - should be free
        (uint256 ethPrice, uint256 currencyPrice) =
            firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);

        // Second purchase - should be free
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);

        // Partial free purchase
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 2, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);

        // Purchase exceeding free units
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 3, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, USDC_PRICE); // 1 paid unit

        // Purchase after using some free units (simulate 1 purchase made)
        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], buyer, 1, "", "");

        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 2, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, USDC_PRICE); // 1 free, 1 paid

        // Purchase after using all free units (simulate 2 total purchases made)
        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], buyer, 1, "", "");

        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, USDC_PRICE); // All paid
    }

    function testProductPrice_ERC721Condition() public {
        vm.startPrank(productOwner);

        // Configure product with ERC721 condition
        TokenCondition[] memory erc721Conditions = new TokenCondition[](1);
        erc721Conditions[0] =
            TokenCondition({tokenAddress: address(mockERC721), tokenType: TokenType.ERC721, tokenId: 0, minQuantity: 1});

        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE, // usdcPrice
                erc721Conditions, // eligibleTokens
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        vm.stopPrank();

        // Buyer without required token - should pay full price
        (uint256 ethPrice, uint256 currencyPrice) =
            firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, USDC_PRICE);

        // Give buyer the required ERC721 token
        mockERC721.mint(buyer);

        // Buyer with required token - should get free units
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);

        // Second free purchase
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);

        // Purchase exceeding free units
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 3, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, USDC_PRICE); // 2 free, 1 paid
    }

    function testProductPrice_ERC1155Condition() public {
        vm.startPrank(productOwner);

        // Configure product with ERC1155 condition
        TokenCondition[] memory erc1155Conditions = new TokenCondition[](1);
        erc1155Conditions[0] = TokenCondition({
            tokenAddress: address(mockERC1155),
            tokenType: TokenType.ERC1155,
            tokenId: 5,
            minQuantity: 10
        });

        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE, // usdcPrice
                erc1155Conditions, // eligibleTokens
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(3) // freeUnits
            )
        );

        vm.stopPrank();

        // Buyer without sufficient tokens - should pay full price
        mockERC1155.setBalance(buyer, 5, 5); // Less than required
        (uint256 ethPrice, uint256 currencyPrice) =
            firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, USDC_PRICE);

        // Give buyer sufficient tokens
        mockERC1155.setBalance(buyer, 5, 15); // More than required

        // Buyer with sufficient tokens - should get free units
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 2, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);

        // Purchase exactly at minimum requirement
        mockERC1155.setBalance(buyer, 5, 10); // Exactly required amount
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);
    }

    function testProductPrice_MultipleConditions() public {
        vm.startPrank(productOwner);

        // Configure product with multiple conditions (OR logic)
        TokenCondition[] memory multipleConditions = new TokenCondition[](2);
        multipleConditions[0] =
            TokenCondition({tokenAddress: address(mockERC721), tokenType: TokenType.ERC721, tokenId: 0, minQuantity: 1});
        multipleConditions[1] = TokenCondition({
            tokenAddress: address(mockERC1155),
            tokenType: TokenType.ERC1155,
            tokenId: 3,
            minQuantity: 5
        });

        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE, // usdcPrice
                multipleConditions, // eligibleTokens
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        vm.stopPrank();

        // Buyer meets first condition only
        mockERC721.mint(buyer);
        (uint256 ethPrice, uint256 currencyPrice) =
            firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);

        // Buyer meets second condition only
        mockERC1155.setBalance(buyer2, 3, 10);
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer2, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);

        // Buyer meets both conditions
        mockERC721.mint(buyer3);
        mockERC1155.setBalance(buyer3, 3, 10);
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer3, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);

        // Buyer meets neither condition
        (ethPrice, currencyPrice) =
            firstForFree.productPrice(slicerId, productIds[0], address(0), 1, address(0x999), "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, USDC_PRICE);
    }

    function testOnProductPurchase_WithMinting() public {
        vm.startPrank(productOwner);

        TokenCondition[] memory noConditions = new TokenCondition[](0);
        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE, // usdcPrice
                noConditions, // eligibleTokens
                address(mockMintToken), // mintToken
                uint88(5), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        vm.stopPrank();

        // Test purchase tracking and minting
        assertEq(firstForFree.purchases(buyer, slicerId), 0);
        assertEq(mockMintToken.balanceOf(buyer, 5), 0);

        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], buyer, 3, "", "");

        // Check purchase tracking
        assertEq(firstForFree.purchases(buyer, slicerId), 3);
        // Check minting
        assertEq(mockMintToken.balanceOf(buyer, 5), 3);

        // Second purchase
        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], buyer, 2, "", "");

        assertEq(firstForFree.purchases(buyer, slicerId), 5);
        assertEq(mockMintToken.balanceOf(buyer, 5), 5);

        // Different buyer should have separate tracking
        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], buyer2, 1, "", "");

        assertEq(firstForFree.purchases(buyer2, slicerId), 1);
        assertEq(mockMintToken.balanceOf(buyer2, 5), 1);
        // Original buyer unchanged
        assertEq(firstForFree.purchases(buyer, slicerId), 5);
    }

    function testOnProductPurchase_WithoutMinting() public {
        vm.prank(productOwner);

        TokenCondition[] memory noConditions = new TokenCondition[](0);
        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE, // usdcPrice
                noConditions, // eligibleTokens
                address(0), // mintToken (no minting)
                uint88(0), // mintTokenId
                uint8(1) // freeUnits
            )
        );

        assertEq(firstForFree.purchases(buyer, slicerId), 0);

        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], buyer, 2, "", "");

        // Only purchase tracking, no minting
        assertEq(firstForFree.purchases(buyer, slicerId), 2);
        assertEq(mockMintToken.balanceOf(buyer, 0), 0);
    }

    function testPurchaseTracking_DifferentSlicers() public {
        vm.startPrank(productOwner);

        TokenCondition[] memory noConditions = new TokenCondition[](0);

        // Configure same product on different slicers
        firstForFree.configureProduct(
            0, // slicerId 0
            productIds[0],
            abi.encode(USDC_PRICE, noConditions, address(0), uint88(0), uint8(2))
        );

        firstForFree.configureProduct(
            1, // slicerId 1
            productIds[0],
            abi.encode(USDC_PRICE, noConditions, address(0), uint88(0), uint8(3))
        );

        vm.stopPrank();

        // Purchase on slicer 0
        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(0, productIds[0], buyer, 2, "", "");

        // Purchase on slicer 1
        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(1, productIds[0], buyer, 1, "", "");

        // Check separate tracking
        assertEq(firstForFree.purchases(buyer, 0), 2);
        assertEq(firstForFree.purchases(buyer, 1), 1);

        // Verify pricing considers separate tracking
        (uint256 ethPrice, uint256 currencyPrice) =
            firstForFree.productPrice(0, productIds[0], address(0), 1, buyer, "");
        assertEq(currencyPrice, USDC_PRICE); // No free units left on slicer 0

        (ethPrice, currencyPrice) = firstForFree.productPrice(1, productIds[0], address(0), 1, buyer, "");
        assertEq(currencyPrice, 0); // Still has free units on slicer 1
    }

    function testEdgeCases() public {
        vm.prank(productOwner);

        TokenCondition[] memory noConditions = new TokenCondition[](0);
        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE, // usdcPrice
                noConditions, // eligibleTokens
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(0) // freeUnits = 0
            )
        );

        // Zero free units - should always pay
        (uint256 ethPrice, uint256 currencyPrice) =
            firstForFree.productPrice(slicerId, productIds[0], address(0), 1, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, USDC_PRICE);

        // Zero quantity - should return zero
        (ethPrice, currencyPrice) = firstForFree.productPrice(slicerId, productIds[0], address(0), 0, buyer, "");
        assertEq(ethPrice, 0);
        assertEq(currencyPrice, 0);
    }

    function testConfigureProduct_UpdateExisting() public {
        vm.startPrank(productOwner);

        // Initial configuration
        TokenCondition[] memory initialConditions = new TokenCondition[](1);
        initialConditions[0] =
            TokenCondition({tokenAddress: address(mockERC721), tokenType: TokenType.ERC721, tokenId: 0, minQuantity: 1});

        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE, // usdcPrice
                initialConditions, // eligibleTokens
                address(mockMintToken), // mintToken
                uint88(1), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        // Update configuration
        TokenCondition[] memory newConditions = new TokenCondition[](2);
        newConditions[0] = TokenCondition({
            tokenAddress: address(mockERC1155),
            tokenType: TokenType.ERC1155,
            tokenId: 5,
            minQuantity: 10
        });
        newConditions[1] =
            TokenCondition({tokenAddress: address(mockERC721), tokenType: TokenType.ERC721, tokenId: 0, minQuantity: 2});

        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            abi.encode(
                USDC_PRICE * 2, // usdcPrice (updated)
                newConditions, // eligibleTokens (updated)
                address(0), // mintToken (updated to none)
                uint88(0), // mintTokenId
                uint8(5) // freeUnits (updated)
            )
        );

        vm.stopPrank();

        // Verify updated configuration
        (uint256 updatedPrice, address updatedMintToken, uint88 updatedMintTokenId, uint8 updatedFreeUnits) =
            firstForFree.usdcPrices(slicerId, productIds[0]);
        assertEq(updatedPrice, USDC_PRICE * 2);
        assertEq(updatedMintToken, address(0));
        assertEq(updatedMintTokenId, 0);
        assertEq(updatedFreeUnits, 5);
    }
}
