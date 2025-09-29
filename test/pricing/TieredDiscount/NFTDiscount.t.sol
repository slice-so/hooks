// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductPriceTest} from "@test/utils/RegistryProductPriceTest.sol";
import {
    IProductsModule,
    NFTDiscount,
    Price,
    DiscountParams,
    NFTType
} from "@/hooks/pricing/TieredDiscount/NFTDiscount/NFTDiscount.sol";
import {MockERC721} from "@test/utils/mocks/MockERC721.sol";
import {MockERC1155} from "@test/utils/mocks/MockERC1155.sol";

address constant USDC = address(1);
uint256 constant slicerId = 0;
uint256 constant productId = 1;
uint256 constant variantId = 0;
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
