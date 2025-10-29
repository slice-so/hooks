// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductPriceTest} from "@test/utils/RegistryProductPriceTest.sol";
import {
    IProductsModule,
    HookRegistry,
    NFTDiscount,
    DiscountParams,
    NFTType
} from "@/hooks/pricing/TieredDiscount/NFTDiscount/NFTDiscount.sol";
import {
    ProductLineItem
} from "@/hooks/pricing/TieredDiscount/TieredDiscount.sol";
import {SliceContext} from "slice/utils/SliceContext.sol";
import {MockERC721} from "@test/utils/mocks/MockERC721.sol";
import {MockERC1155} from "@test/utils/mocks/MockERC1155.sol";

address constant USDC = address(1);
uint256 constant slicerId = 0;
uint256 constant productId = 1;
uint256 constant variantId = 0;
uint256 constant productTypeId = 2;
uint80 constant percentDiscountOne = 1000; // 10%
uint80 constant percentDiscountTwo = 2000; // 20%

contract NFTDiscountTest is RegistryProductPriceTest {
    NFTDiscount erc721GatedDiscount;
    MockERC721 nftOne = new MockERC721();
    MockERC721 nftTwo = new MockERC721();
    MockERC721 nftThree = new MockERC721();
    MockERC1155 nft1155 = new MockERC1155();

    uint256 quantity = 5;
    uint8 minNftQuantity = 1;

    function setUp() public {
        erc721GatedDiscount = new NFTDiscount(PRODUCTS_MODULE);
        _setHook(address(erc721GatedDiscount));

        nftOne.mint(buyer);
    }

    function testConfigureProductType() public {
        DiscountParams[] memory discountParams = new DiscountParams[](2);

        discountParams[0] = DiscountParams({
            nft: address(nftTwo),
            discount: percentDiscountTwo,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });
        discountParams[1] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        bytes memory params = abi.encode(discountParams);

        vm.expectEmit(true, true, true, true, address(erc721GatedDiscount));
        emit HookRegistry.ProductTypeConfigured(slicerId, productTypeId, params);

        vm.prank(productOwner);
        erc721GatedDiscount.configureProductType(slicerId, productTypeId, params);

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        uint256 price =
            erc721GatedDiscount.productTypePrice(slicerId, productTypeId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, (basePrice - (basePrice * percentDiscountOne) / 1e4));

        nftTwo.mint(buyer);

        uint256 priceWithHigherDiscount =
            erc721GatedDiscount.productTypePrice(slicerId, productTypeId, ETH, basePrice, quantity, buyer, "");

        assertEq(priceWithHigherDiscount, (basePrice - (basePrice * percentDiscountTwo) / 1e4));
    }

    function testConfigureProductType_AccessControl() public {
        vm.expectRevert(abi.encodeWithSelector(SliceContext.NotAuthorized.selector, bytes32(uint256(1 << 1 | 1 << 3))));

        erc721GatedDiscount.configureProductType(slicerId, productTypeId, "");
    }

    function testConfigureProductTypeSchema() public view {
        string memory schema = erc721GatedDiscount.configureProductTypeSchema();

        assertEq(schema, erc721GatedDiscount.configureProductSchema());
        assertTrue(bytes(schema).length > 0);
    }

    function testProductTypePriceSchema() public view {
        string memory schema = erc721GatedDiscount.productTypePriceSchema();

        assertEq(schema, erc721GatedDiscount.productPriceSchema());
    }

    function testProductTypePrice_NoDiscount() public {
        vm.prank(productOwner);
        erc721GatedDiscount.configureProductType(slicerId, productTypeId, abi.encode(new DiscountParams[](0)));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);
        uint256 price =
            erc721GatedDiscount.productTypePrice(slicerId, productTypeId, ETH, basePrice, quantity, buyer2, "");

        assertEq(price, basePrice);
    }

    function testConfigureProductType__Edit_Remove() public {
        DiscountParams[] memory discountParams = new DiscountParams[](2);

        discountParams[0] = DiscountParams({
            nft: address(nftTwo),
            discount: percentDiscountTwo,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });
        discountParams[1] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProductType(slicerId, productTypeId, abi.encode(discountParams));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        uint256 price =
            erc721GatedDiscount.productTypePrice(slicerId, productTypeId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, (basePrice - (basePrice * percentDiscountOne) / 1e4));

        vm.prank(productOwner);
        erc721GatedDiscount.configureProductType(slicerId, productTypeId, abi.encode(new DiscountParams[](0)));

        uint256 resetPrice =
            erc721GatedDiscount.productTypePrice(slicerId, productTypeId, ETH, basePrice, quantity, buyer, "");

        assertEq(resetPrice, basePrice);
    }

    function testConfigureSlicer() public {
        DiscountParams[] memory discountParams = new DiscountParams[](2);

        discountParams[0] = DiscountParams({
            nft: address(nftTwo),
            discount: percentDiscountTwo,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });
        discountParams[1] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        bytes memory params = abi.encode(discountParams);

        vm.expectEmit(true, true, true, true, address(erc721GatedDiscount));
        emit HookRegistry.SlicerConfigured(slicerId, params);

        vm.prank(productOwner);
        erc721GatedDiscount.configureSlicer(slicerId, params);

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        ProductLineItem[] memory productLineItems = new ProductLineItem[](1);
        productLineItems[0] = ProductLineItem({
            productId:uint32(productId),
            variantId:uint32(variantId),
            quantity:uint32( quantity)}
        );
        uint256[] memory basePrices = new uint256[](1);
        basePrices[0] = basePrice;
        uint256[] memory newBasePrices = erc721GatedDiscount.slicerProductPrice(slicerId, ETH,buyer, productLineItems, basePrices);

        assertEq(newBasePrices[0], (basePrice - (basePrice * percentDiscountOne) / 1e4));

        nftTwo.mint(buyer);

        newBasePrices =
            erc721GatedDiscount.slicerProductPrice(slicerId, ETH,buyer, productLineItems, basePrices);

        assertEq(newBasePrices[0], (basePrice - (basePrice * percentDiscountTwo) / 1e4));
    }

    function testConfigureSlicer_AccessControl() public {
        vm.expectRevert(abi.encodeWithSelector(SliceContext.NotAuthorized.selector, bytes32(uint256(1 << 1 | 1 << 3))));

        erc721GatedDiscount.configureSlicer(slicerId, "");
    }

    function testConfigureSlicerSchema() public view {
        string memory schema = erc721GatedDiscount.configureSlicerSchema();

        assertEq(schema, erc721GatedDiscount.configureProductSchema());
        assertTrue(bytes(schema).length > 0);
    }

    function testSlicerProductPriceSchema() public view {
        string memory schema = erc721GatedDiscount.slicerProductPriceSchema();

        assertEq(schema, erc721GatedDiscount.productPriceSchema());
    }

    function testSlicerProductPrice_NoDiscount() public {
        vm.prank(productOwner);
        erc721GatedDiscount.configureSlicer(slicerId, abi.encode(new DiscountParams[](0)));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);


        ProductLineItem[] memory productLineItems = new ProductLineItem[](1);
        productLineItems[0] = ProductLineItem({
            productId:uint32(productId),
            variantId:uint32(variantId),
            quantity:uint32( quantity)}
        );
        uint256[] memory basePrices = new uint256[](1);
        basePrices[0] = basePrice;
        uint256[] memory newBasePrices = erc721GatedDiscount.slicerProductPrice(slicerId, ETH,buyer3, productLineItems, basePrices);

        assertEq(newBasePrices[0], basePrice);
    }

    function testConfigureSlicer__Edit_Remove() public {
        DiscountParams[] memory discountParams = new DiscountParams[](2);

        discountParams[0] = DiscountParams({
            nft: address(nftTwo),
            discount: percentDiscountTwo,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });
        discountParams[1] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureSlicer(slicerId, abi.encode(discountParams));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        ProductLineItem[] memory productLineItems = new ProductLineItem[](1);
        productLineItems[0] = ProductLineItem({
            productId:uint32(productId),
            variantId:uint32(variantId),
            quantity:uint32( quantity)}
        );
        uint256[] memory basePrices = new uint256[](1);
        basePrices[0] = basePrice;
        uint256[] memory newBasePrices = erc721GatedDiscount.slicerProductPrice(slicerId, ETH,buyer, productLineItems, basePrices);

        assertEq(newBasePrices[0], (basePrice - (basePrice * percentDiscountOne) / 1e4));

        vm.prank(productOwner);
        erc721GatedDiscount.configureSlicer(slicerId, abi.encode(new DiscountParams[](0)));

        newBasePrices = erc721GatedDiscount.slicerProductPrice(slicerId, ETH,buyer, productLineItems, basePrices);
        
        assertEq(newBasePrices[0], basePrice);
    }

    function testConfigureProduct__ETH() public {
        DiscountParams[] memory discountParams = new DiscountParams[](1);

        /// set product price with additional custom inputs
        discountParams[0] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        /// check product price
        uint256 price =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, (basePrice - (basePrice * percentDiscountOne) / 1e4));
    }

    function testConfigureProduct__ERC20() public {
        DiscountParams[] memory discountParams = new DiscountParams[](1);

        /// set product price with additional custom inputs
        discountParams[0] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, USDC, quantity);

        /// check product price
        uint256 price =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, USDC, basePrice, quantity, buyer, "");

        assertEq(price, (basePrice - (basePrice * percentDiscountOne) / 1e4));
    }

    function testConfigureProduct__ERC1155() public {
        DiscountParams[] memory discountParams = new DiscountParams[](1);

        /// set product price with additional custom inputs
        discountParams[0] = DiscountParams({
            nft: address(nft1155),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC1155,
            tokenId: 1
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, USDC, quantity);

        /// check product price
        uint256 price =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, USDC, basePrice, quantity, buyer, "");

        assertEq(price, basePrice);

        nft1155.mint(buyer);

        price = erc721GatedDiscount.productPrice(slicerId, productId, variantId, USDC, basePrice, quantity, buyer, "");

        assertEq(price, (basePrice - (basePrice * percentDiscountOne) / 1e4));
    }

    function testConfigureProduct__HigherDiscount() public {
        DiscountParams[] memory discountParams = new DiscountParams[](2);

        discountParams[0] = DiscountParams({
            nft: address(nft1155),
            discount: percentDiscountTwo,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC1155,
            tokenId: 1
        });
        discountParams[1] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        /// check product price for ETH
        uint256 price =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, (basePrice - (basePrice * percentDiscountOne) / 1e4));

        nft1155.mint(buyer);

        price = erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, (basePrice - (basePrice * percentDiscountTwo) / 1e4));
    }

    function testRevert_ProductPrice__NotNFTOwner() public {
        DiscountParams[] memory discountParams = new DiscountParams[](1);

        /// set product price for NFT that is not owned by buyer
        discountParams[0] = DiscountParams({
            nft: address(nftTwo),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        /// check product price
        uint256 price =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, basePrice);
    }

    function testProductPrice__MinQuantity() public {
        DiscountParams[] memory discountParams = new DiscountParams[](1);

        /// Buyer owns 1 NFT, but minQuantity is 2
        discountParams[0] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity + 1,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        /// check product price
        uint256 price =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, basePrice);

        /// Buyer owns 2 NFTs, minQuantity is 2
        nftOne.mint(buyer);

        /// check product price
        uint256 secondPrice =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(secondPrice, (basePrice - (basePrice * percentDiscountOne) / 1e4));
    }

    function testProductPrice__MultipleBoughtQuantity() public {
        DiscountParams[] memory discountParams = new DiscountParams[](1);

        discountParams[0] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        // buy multiple products
        quantity = 6;

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        /// check product price
        uint256 price =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, (basePrice - (basePrice * percentDiscountOne) / 1e4));
    }

    function testConfigureProduct__Edit_Add() public {
        DiscountParams[] memory discountParams = new DiscountParams[](1);

        discountParams[0] = DiscountParams({
            nft: address(nftTwo),
            discount: percentDiscountTwo,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        // mint NFT 2
        nftTwo.mint(buyer);

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        /// check product price
        uint256 price =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, (basePrice - (basePrice * percentDiscountTwo) / 1e4));

        discountParams = new DiscountParams[](2);

        /// edit product price, with more NFTs and first NFT has higher discount but buyer owns only the second
        discountParams[0] = DiscountParams({
            nft: address(nftThree),
            discount: percentDiscountOne + 10,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        discountParams[1] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        /// check product price
        uint256 secondPrice =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(secondPrice, (basePrice - (basePrice * percentDiscountOne) / 1e4));
    }

    function testConfigureProduct__Edit_Remove() public {
        DiscountParams[] memory discountParams = new DiscountParams[](2);

        // mint NFT 2
        nftTwo.mint(buyer);

        /// edit product price, with more NFTs and first NFT has higher discount but buyer owns only the second
        discountParams[0] = DiscountParams({
            nft: address(nftThree),
            discount: percentDiscountOne + 10,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        discountParams[1] = DiscountParams({
            nft: address(nftOne),
            discount: percentDiscountOne,
            minQuantity: minNftQuantity,
            nftType: NFTType.ERC721,
            tokenId: 0
        });

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        uint256 basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, ETH, quantity);

        /// check product price
        uint256 secondPrice =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(secondPrice, (basePrice - (basePrice * percentDiscountOne) / 1e4));

        discountParams = new DiscountParams[](0);

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, variantId, abi.encode(discountParams));

        /// check product price
        uint256 price =
            erc721GatedDiscount.productPrice(slicerId, productId, variantId, ETH, basePrice, quantity, buyer, "");

        assertEq(price, basePrice);
    }
}
