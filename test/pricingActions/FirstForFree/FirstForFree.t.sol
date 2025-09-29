// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductPriceActionTest} from "@test/utils/RegistryProductPriceActionTest.sol";
import {Price, FirstForFree} from "@/hooks/pricingActions/FirstForFree/FirstForFree.sol";
import {ProductParams} from "@/hooks/pricingActions/FirstForFree/types/ProductParams.sol";
import {TokenCondition, TokenType} from "@/hooks/pricingActions/FirstForFree/types/TokenCondition.sol";
import {ITokenERC1155} from "@/hooks/pricingActions/FirstForFree/utils/ITokenERC1155.sol";
import {MockERC721} from "@test/utils/mocks/MockERC721.sol";

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

    uint256 slicerId = 0;
    uint256[] productIds = [1, 2, 3, 4];
    uint256 constant variantId = 0;
    uint256 constant variantIdAlt = 1;

    function _basePrice(uint256 slicerId_, uint256 productId_, uint256 quantity) internal view returns (uint256) {
        return _basePriceForVariant(slicerId_, productId_, variantId, quantity);
    }

    function _basePriceForVariant(uint256 slicerId_, uint256 productId_, uint256 variantId_, uint256 quantity)
        internal
        view
        returns (uint256)
    {
        return PRODUCTS_MODULE.basePrice(slicerId_, productId_, variantId_, ETH, quantity);
    }

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
            variantId,
            abi.encode(
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
            variantId,
            abi.encode(
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
            variantId,
            abi.encode(
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
            variantId,
            abi.encode(
                multipleConditions, // eligibleTokens
                address(mockMintToken), // mintToken
                uint88(3), // mintTokenId
                uint8(5) // freeUnits
            )
        );

        vm.stopPrank();

        // Verify product 1 configuration
        (address mintToken1, uint88 mintTokenId1, uint8 freeUnits1) =
            firstForFree.productParams(slicerId, productIds[0], variantId);
        assertEq(mintToken1, address(mockMintToken));
        assertEq(mintTokenId1, 1);
        assertEq(freeUnits1, 3);

        // Verify product 2 configuration
        (address mintToken2, uint88 mintTokenId2, uint8 freeUnits2) =
            firstForFree.productParams(slicerId, productIds[1], variantId);
        assertEq(mintToken2, address(0));
        assertEq(mintTokenId2, 0);
        assertEq(freeUnits2, 2);

        // Verify product 3 configuration
        (address mintToken3, uint88 mintTokenId3, uint8 freeUnits3) =
            firstForFree.productParams(slicerId, productIds[2], variantId);
        assertEq(mintToken3, address(mockMintToken));
        assertEq(mintTokenId3, 2);
        assertEq(freeUnits3, 1);

        // Verify product 4 configuration
        (address mintToken4, uint88 mintTokenId4, uint8 freeUnits4) =
            firstForFree.productParams(slicerId, productIds[3], variantId);
        assertEq(mintToken4, address(mockMintToken));
        assertEq(mintTokenId4, 3);
        assertEq(freeUnits4, 5);
    }

    function testConfigureProduct_variantSpecific() public {
        TokenCondition[] memory noConditions = new TokenCondition[](0);

        vm.startPrank(productOwner);
        firstForFree.configureProduct(
            slicerId, productIds[0], variantId, abi.encode(noConditions, address(0), uint88(0), uint8(1))
        );
        firstForFree.configureProduct(
            slicerId, productIds[0], variantIdAlt, abi.encode(noConditions, address(mockMintToken), uint88(7), uint8(2))
        );
        vm.stopPrank();

        (address mintTokenBase, uint88 mintTokenIdBase, uint8 freeUnitsBase) =
            firstForFree.productParams(slicerId, productIds[0], variantId);
        assertEq(mintTokenBase, address(0));
        assertEq(mintTokenIdBase, 0);
        assertEq(freeUnitsBase, 1);

        (address mintTokenAlt, uint88 mintTokenIdAlt, uint8 freeUnitsAlt) =
            firstForFree.productParams(slicerId, productIds[0], variantIdAlt);
        assertEq(mintTokenAlt, address(mockMintToken));
        assertEq(mintTokenIdAlt, 7);
        assertEq(freeUnitsAlt, 2);
    }

    function testProductPrice_NoConditions() public {
        vm.prank(productOwner);

        // Configure product with no token conditions
        TokenCondition[] memory noConditions = new TokenCondition[](0);
        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                noConditions, // eligibleTokens (empty)
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        // First purchase - should be free
        uint256 basePrice = _basePrice(slicerId, productIds[0], 1);
        uint256 price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, 0);

        // Second purchase - should be free
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, 0);

        // Partial free purchase
        uint256 twoUnitBasePrice = _basePrice(slicerId, productIds[0], 2);
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, twoUnitBasePrice, 2, buyer, "");
        assertEq(price, 0);

        // Purchase exceeding free units
        uint256 threeUnitBasePrice = _basePrice(slicerId, productIds[0], 3);
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, threeUnitBasePrice, 3, buyer, "");
        assertEq(price, _basePrice(slicerId, productIds[0], 1));

        // Purchase after using some free units (simulate 1 purchase made)
        vm.mockCall(
            address(PRODUCTS_MODULE),
            abi.encodeWithSelector(PRODUCTS_MODULE.getPurchases.selector, buyer, slicerId, productIds[0], variantId),
            abi.encode(1, "")
        );
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, twoUnitBasePrice, 2, buyer, "");
        assertEq(price, _basePrice(slicerId, productIds[0], 1));

        vm.mockCall(
            address(PRODUCTS_MODULE),
            abi.encodeWithSelector(PRODUCTS_MODULE.getPurchases.selector, buyer, slicerId, productIds[0], variantId),
            abi.encode(2, "")
        );
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, basePrice);
    }

    function testProductPrice_variantSpecificConfiguration() public {
        TokenCondition[] memory noConditions = new TokenCondition[](0);

        vm.startPrank(productOwner);
        firstForFree.configureProduct(
            slicerId, productIds[0], variantId, abi.encode(noConditions, address(0), uint88(0), uint8(1))
        );
        firstForFree.configureProduct(
            slicerId, productIds[0], variantIdAlt, abi.encode(noConditions, address(0), uint88(0), uint8(2))
        );
        vm.stopPrank();

        uint256 basePriceVariant0 = _basePrice(slicerId, productIds[0], 1);
        uint256 priceVariant0 =
            firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePriceVariant0, 1, buyer, "");
        assertEq(priceVariant0, 0);

        vm.mockCall(
            address(PRODUCTS_MODULE),
            abi.encodeWithSelector(PRODUCTS_MODULE.getPurchases.selector, buyer, slicerId, productIds[0], variantId),
            abi.encode(1, "")
        );
        priceVariant0 =
            firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePriceVariant0, 1, buyer, "");
        assertEq(priceVariant0, basePriceVariant0);

        uint256 basePriceVariantAlt = _basePriceForVariant(slicerId, productIds[0], variantIdAlt, 1);
        uint256 priceVariantAlt =
            firstForFree.productPrice(slicerId, productIds[0], variantIdAlt, ETH, basePriceVariantAlt, 1, buyer, "");
        assertEq(priceVariantAlt, 0);

        uint256 twoUnitBasePriceAlt = _basePriceForVariant(slicerId, productIds[0], variantIdAlt, 2);
        priceVariantAlt =
            firstForFree.productPrice(slicerId, productIds[0], variantIdAlt, ETH, twoUnitBasePriceAlt, 2, buyer, "");
        assertEq(priceVariantAlt, 0);

        vm.mockCall(
            address(PRODUCTS_MODULE),
            abi.encodeWithSelector(PRODUCTS_MODULE.getPurchases.selector, buyer, slicerId, productIds[0], variantIdAlt),
            abi.encode(2, "")
        );
        priceVariantAlt =
            firstForFree.productPrice(slicerId, productIds[0], variantIdAlt, ETH, basePriceVariantAlt, 1, buyer, "");
        assertEq(priceVariantAlt, basePriceVariantAlt);
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
            variantId,
            abi.encode(
                erc721Conditions, // eligibleTokens
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        vm.stopPrank();

        // Buyer without required token - should pay full price
        uint256 basePrice = _basePrice(slicerId, productIds[0], 1);
        uint256 price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, basePrice);

        // Give buyer the required ERC721 token
        mockERC721.mint(buyer);

        // Buyer with required token - should get free units
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, 0);

        // Second free purchase
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, 0);

        // Purchase exceeding free units
        uint256 threeUnitBasePrice = _basePrice(slicerId, productIds[0], 3);
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, threeUnitBasePrice, 3, buyer, "");
        assertEq(price, _basePrice(slicerId, productIds[0], 1)); // 2 free, 1 paid
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
            variantId,
            abi.encode(
                erc1155Conditions, // eligibleTokens
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(3) // freeUnits
            )
        );

        vm.stopPrank();

        // Buyer without sufficient tokens - should pay full price
        mockERC1155.setBalance(buyer, 5, 5); // Less than required
        uint256 basePrice = _basePrice(slicerId, productIds[0], 1);
        uint256 price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, basePrice);

        // Give buyer sufficient tokens
        mockERC1155.setBalance(buyer, 5, 15); // More than required

        // Buyer with sufficient tokens - should get free units
        uint256 twoUnitBasePrice = _basePrice(slicerId, productIds[0], 2);
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, twoUnitBasePrice, 2, buyer, "");
        assertEq(price, 0);

        // Purchase exactly at minimum requirement
        mockERC1155.setBalance(buyer, 5, 10); // Exactly required amount
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, 0);
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
            variantId,
            abi.encode(
                multipleConditions, // eligibleTokens
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        vm.stopPrank();

        uint256 basePrice = _basePrice(slicerId, productIds[0], 1);

        // Buyer meets first condition only
        mockERC721.mint(buyer);
        uint256 price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, 0);

        // Buyer meets second condition only
        mockERC1155.setBalance(buyer2, 3, 10);
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer2, "");
        assertEq(price, 0);

        // Buyer meets both conditions
        mockERC721.mint(buyer3);
        mockERC1155.setBalance(buyer3, 3, 10);
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer3, "");
        assertEq(price, 0);

        // Buyer meets neither condition
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, address(0x999), "");
        assertEq(price, basePrice);
    }

    function testOnProductPurchase_WithMinting() public {
        vm.startPrank(productOwner);

        TokenCondition[] memory noConditions = new TokenCondition[](0);
        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                noConditions, // eligibleTokens
                address(mockMintToken), // mintToken
                uint88(5), // mintTokenId
                uint8(2) // freeUnits
            )
        );

        vm.stopPrank();

        // Test minting
        assertEq(mockMintToken.balanceOf(buyer, 5), 0);

        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], variantId, buyer, 3, "");

        // Check minting
        assertEq(mockMintToken.balanceOf(buyer, 5), 3);

        // Second purchase
        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], variantId, buyer, 2, "");

        assertEq(mockMintToken.balanceOf(buyer, 5), 5);

        // Different buyer should have separate tracking
        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], variantId, buyer2, 1, "");

        assertEq(mockMintToken.balanceOf(buyer2, 5), 1);
    }

    function testOnProductPurchase_WithoutMinting() public {
        vm.prank(productOwner);

        TokenCondition[] memory noConditions = new TokenCondition[](0);
        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                noConditions, // eligibleTokens
                address(0), // mintToken (no minting)
                uint88(0), // mintTokenId
                uint8(1) // freeUnits
            )
        );

        vm.prank(address(PRODUCTS_MODULE));
        firstForFree.onProductPurchase(slicerId, productIds[0], variantId, buyer, 2, "");

        // Check no minting
        assertEq(mockMintToken.balanceOf(buyer, 0), 0);
    }

    function testPurchaseTracking_DifferentSlicers() public {
        vm.startPrank(productOwner);

        TokenCondition[] memory noConditions = new TokenCondition[](0);

        // Configure same product on different slicers
        firstForFree.configureProduct(
            0, // slicerId 0
            productIds[0],
            variantId,
            abi.encode(noConditions, address(0), uint88(0), uint8(2))
        );

        firstForFree.configureProduct(
            1, // slicerId 1
            productIds[0],
            variantId,
            abi.encode(noConditions, address(0), uint88(0), uint8(3))
        );

        vm.stopPrank();

        // Verify pricing considers separate tracking
        uint256 basePriceSlicer0 = _basePrice(0, productIds[0], 1);
        vm.mockCall(
            address(PRODUCTS_MODULE),
            abi.encodeWithSelector(PRODUCTS_MODULE.getPurchases.selector, buyer, 0, productIds[0], variantId),
            abi.encode(2, "")
        );
        uint256 price = firstForFree.productPrice(0, productIds[0], variantId, ETH, basePriceSlicer0, 1, buyer, "");
        assertEq(price, basePriceSlicer0); // No free units left on slicer 0

        uint256 basePriceSlicer1 = _basePrice(1, productIds[0], 1);
        vm.mockCall(
            address(PRODUCTS_MODULE),
            abi.encodeWithSelector(PRODUCTS_MODULE.getPurchases.selector, buyer, 1, productIds[0], variantId),
            abi.encode(1, "")
        );
        price = firstForFree.productPrice(1, productIds[0], variantId, ETH, basePriceSlicer1, 1, buyer, "");
        assertEq(price, 0); // Still has free units on slicer 1
    }

    function testEdgeCases() public {
        vm.prank(productOwner);

        TokenCondition[] memory noConditions = new TokenCondition[](0);
        firstForFree.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                noConditions, // eligibleTokens
                address(0), // mintToken
                uint88(0), // mintTokenId
                uint8(0) // freeUnits = 0
            )
        );

        // Zero free units - should always pay
        uint256 basePrice = _basePrice(slicerId, productIds[0], 1);
        uint256 price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, basePrice, 1, buyer, "");
        assertEq(price, basePrice);

        // Zero quantity - should return zero
        price = firstForFree.productPrice(slicerId, productIds[0], variantId, ETH, 0, 0, buyer, "");
        assertEq(price, 0);
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
            variantId,
            abi.encode(
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
            variantId,
            abi.encode(
                newConditions, // eligibleTokens (updated)
                address(0), // mintToken (updated to none)
                uint88(0), // mintTokenId
                uint8(5) // freeUnits (updated)
            )
        );

        vm.stopPrank();

        // Verify updated configuration
        (address updatedMintToken, uint88 updatedMintTokenId, uint8 updatedFreeUnits) =
            firstForFree.productParams(slicerId, productIds[0], variantId);
        assertEq(updatedMintToken, address(0));
        assertEq(updatedMintTokenId, 0);
        assertEq(updatedFreeUnits, 5);
    }
}
