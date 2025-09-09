// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductPriceTest} from "@test/utils/RegistryProductPriceTest.sol";
import {console2} from "forge-std/console2.sol";
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
uint80 constant percentDiscountOne = 1000; // 10%
uint80 constant percentDiscountTwo = 2000; // 20%

contract NFTDiscountTest is RegistryProductPriceTest {
    NFTDiscount erc721GatedDiscount;
    MockERC721 nftOne = new MockERC721();
    MockERC721 nftTwo = new MockERC721();
    MockERC721 nftThree = new MockERC721();
    MockERC1155 nft1155 = new MockERC1155();

    uint256 quantity = 1;
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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        /// check product price
        Price memory price = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, 0, ETH, quantity);

        assertEq(price.eth, quantity * (basePrice.eth - (basePrice.eth * percentDiscountOne) / 1e4));
        assertEq(price.currency, 0);
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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        /// check product price
        Price memory price = erc721GatedDiscount.productPrice(slicerId, productId, 0, USDC, quantity, buyer, "");

        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, 0, USDC, quantity);

        assertEq(price.currency, quantity * (basePrice.currency - (basePrice.currency * percentDiscountOne) / 1e4));
        assertTrue(price.eth == 0);
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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        /// check product price
        Price memory price = erc721GatedDiscount.productPrice(slicerId, productId, 0, USDC, quantity, buyer, "");

        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, 0, USDC, quantity);

        assertEq(price.currency, quantity * basePrice.currency);
        assertEq(price.eth, 0);

        nft1155.mint(buyer);

        price = erc721GatedDiscount.productPrice(slicerId, productId, 0, USDC, quantity, buyer, "");

        assertEq(price.currency, quantity * (basePrice.currency - (basePrice.currency * percentDiscountOne) / 1e4));
        assertEq(price.eth, 0);
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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        /// check product price for ETH
        Price memory price = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, 0, ETH, quantity);

        assertEq(price.eth, quantity * (basePrice.eth - (basePrice.eth * percentDiscountOne) / 1e4));
        assertEq(price.currency, 0);

        nft1155.mint(buyer);

        price = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        assertEq(price.eth, quantity * (basePrice.eth - (basePrice.eth * percentDiscountTwo) / 1e4));
        assertEq(price.currency, 0);
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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        /// check product price
        Price memory price = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, 0, ETH, quantity);

        assertEq(price.eth, quantity * basePrice.eth);
        assertEq(price.currency, 0);
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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        /// check product price
        Price memory price = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, 0, ETH, quantity);

        assertEq(price.eth, quantity * basePrice.eth);
        assertEq(price.currency, 0);

        /// Buyer owns 2 NFTs, minQuantity is 2
        nftOne.mint(buyer);

        /// check product price
        Price memory secondPrice = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        assertEq(secondPrice.eth, quantity * (basePrice.eth - (basePrice.eth * percentDiscountOne) / 1e4));
        assertEq(secondPrice.currency, 0);
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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        // buy multiple products
        quantity = 6;

        /// check product price
        Price memory price = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, 0, ETH, quantity);

        assertEq(price.eth, quantity * (basePrice.eth - (basePrice.eth * percentDiscountOne) / 1e4));
        assertEq(price.currency, 0);
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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        // mint NFT 2
        nftTwo.mint(buyer);

        /// check product price
        Price memory price = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, 0, ETH, quantity);

        assertEq(price.eth, quantity * (basePrice.eth - (basePrice.eth * percentDiscountTwo) / 1e4));
        assertEq(price.currency, 0);

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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        /// check product price
        Price memory secondPrice = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        assertEq(secondPrice.eth, quantity * (basePrice.eth - (basePrice.eth * percentDiscountOne) / 1e4));
        assertEq(secondPrice.currency, 0);
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
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        /// check product price
        Price memory secondPrice = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        Price memory basePrice = PRODUCTS_MODULE.basePrice(slicerId, productId, 0, ETH, quantity);

        assertEq(secondPrice.eth, quantity * (basePrice.eth - (basePrice.eth * percentDiscountOne) / 1e4));
        assertEq(secondPrice.currency, 0);

        discountParams = new DiscountParams[](0);

        vm.prank(productOwner);
        erc721GatedDiscount.configureProduct(slicerId, productId, abi.encode(discountParams));

        /// check product price
        Price memory price = erc721GatedDiscount.productPrice(slicerId, productId, 0, ETH, quantity, buyer, "");

        assertEq(price.eth, quantity * basePrice.eth);
        assertEq(price.currency, 0);
    }
}
