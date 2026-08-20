// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductAction, RegistryProductActionTest} from "@test/utils/RegistryProductActionTest.sol";
import {ERC20Mint} from "@/hooks/actions/ERC20Mint/ERC20Mint.sol";
import {ERC20Data} from "@/hooks/actions/ERC20Mint/types/ERC20Data.sol";
import {ERC20Mint_BaseToken} from "@/hooks/actions/ERC20Mint/utils/ERC20Mint_BaseToken.sol";
import {HookRegistry, ProductLineItem} from "@/utils/RegistryAction.sol";
import {SliceContext} from "@/utils/RegistryProductAction.sol";

uint256 constant slicerId = 0;
uint256 constant variantId = 0;
uint256 constant variantIdAlt = 1;
uint256 constant productTypeId = 2;

contract ERC20MintTest is RegistryProductActionTest {
    ERC20Mint erc20Mint;

    uint256[] productIds = [1, 2, 3, 4];

    function setUp() public {
        erc20Mint = new ERC20Mint(PRODUCTS_MODULE);
        _setHook(address(erc20Mint));
    }

    function testConfigureProduct() public {
        vm.startPrank(productOwner);

        // Configure product 1: Standard token with max supply
        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                "Test Token 1", // name
                "TT1", // symbol
                1000, // premintAmount
                productOwner, // premintReceiver
                true, // revertOnMaxSupplyReached
                10000, // maxSupply
                100 // tokensPerUnit
            )
        );

        // Configure product 2: Token without max supply limit
        erc20Mint.configureProduct(
            slicerId,
            productIds[1],
            variantId,
            abi.encode(
                "Test Token 2", // name
                "TT2", // symbol
                0, // premintAmount (no premint)
                address(0), // premintReceiver
                false, // revertOnMaxSupplyReached
                0, // maxSupply (unlimited)
                50 // tokensPerUnit
            )
        );

        // Configure product 3: Token with revert on max supply
        erc20Mint.configureProduct(
            slicerId,
            productIds[2],
            variantId,
            abi.encode(
                "Test Token 3", // name
                "TT3", // symbol
                500, // premintAmount
                buyer, // premintReceiver
                true, // revertOnMaxSupplyReached
                1000, // maxSupply
                1 // tokensPerUnit
            )
        );

        vm.stopPrank();

        // Verify tokenData is set correctly
        (ERC20Mint_BaseToken token1, bool revertOnMaxSupply1, uint256 tokensPerUnit1) =
            erc20Mint.tokenData(slicerId, productIds[0], variantId);
        assertEq(revertOnMaxSupply1, true);
        assertEq(tokensPerUnit1, 100);
        assertEq(token1.name(), "Test Token 1");
        assertEq(token1.symbol(), "TT1");
        assertEq(token1.maxSupply(), 10000);
        assertEq(token1.totalSupply(), 1000); // premint amount
        assertEq(token1.balanceOf(productOwner), 1000);

        (ERC20Mint_BaseToken token2, bool revertOnMaxSupply2, uint256 tokensPerUnit2) =
            erc20Mint.tokenData(slicerId, productIds[1], variantId);
        assertEq(revertOnMaxSupply2, false);
        assertEq(tokensPerUnit2, 50);
        assertEq(token2.name(), "Test Token 2");
        assertEq(token2.symbol(), "TT2");
        assertEq(token2.maxSupply(), type(uint256).max);
        assertEq(token2.totalSupply(), 0); // no premint

        (ERC20Mint_BaseToken token3, bool revertOnMaxSupply3, uint256 tokensPerUnit3) =
            erc20Mint.tokenData(slicerId, productIds[2], variantId);
        assertEq(revertOnMaxSupply3, true);
        assertEq(tokensPerUnit3, 1);
        assertEq(token3.totalSupply(), 500); // premint amount
        assertEq(token3.balanceOf(buyer), 500);
    }

    function testConfigureProduct_UpdateExistingToken() public {
        vm.startPrank(productOwner);

        // First configuration
        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                100, // premintAmount
                productOwner, // premintReceiver
                true, // revertOnMaxSupplyReached
                1000, // maxSupply
                10 // tokensPerUnit
            )
        );

        (ERC20Mint_BaseToken token1,,) = erc20Mint.tokenData(slicerId, productIds[0], variantId);
        address tokenAddress = address(token1);

        // Second configuration - should update existing token
        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                "Updated Token", // name (ignored for existing token)
                "UT", // symbol (ignored for existing token)
                0, // premintAmount
                address(0), // premintReceiver
                false, // revertOnMaxSupplyReached
                2000, // maxSupply (updated)
                20 // tokensPerUnit (updated)
            )
        );

        (ERC20Mint_BaseToken token2, bool revertOnMaxSupply2, uint256 tokensPerUnit2) =
            erc20Mint.tokenData(slicerId, productIds[0], variantId);

        // Token address should be the same
        assertEq(address(token2), tokenAddress);
        // Config should be updated
        assertEq(revertOnMaxSupply2, false);
        assertEq(tokensPerUnit2, 20);
        assertEq(token2.maxSupply(), 2000);
        // Original token properties remain
        assertEq(token2.name(), "Test Token");
        assertEq(token2.symbol(), "TT");

        vm.stopPrank();
    }

    function testRevert_configureProduct_InvalidTokensPerUnit() public {
        vm.startPrank(productOwner);

        vm.expectRevert(ERC20Mint.InvalidTokensPerUnit.selector);
        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                false, // revertOnMaxSupplyReached
                1000, // maxSupply
                0 // tokensPerUnit (invalid)
            )
        );

        vm.stopPrank();
    }

    function testIsPurchaseAllowed() public {
        vm.startPrank(productOwner);

        // Configure product with max supply and revert enabled
        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                800, // premintAmount
                productOwner, // premintReceiver
                true, // revertOnMaxSupplyReached
                1000, // maxSupply
                10 // tokensPerUnit
            )
        );

        // Configure product without max supply limit
        erc20Mint.configureProduct(
            slicerId,
            productIds[1],
            variantId,
            abi.encode(
                "Test Token 2", // name
                "TT2", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                false, // revertOnMaxSupplyReached
                0, // maxSupply (unlimited)
                50 // tokensPerUnit
            )
        );

        vm.stopPrank();

        // Test product 1 (with max supply limit)
        // Current supply: 800, max supply: 1000
        // Available: 200 tokens, with 10 tokens per unit = 20 units max

        assertTrue(erc20Mint.isPurchaseAllowed(slicerId, productIds[0], 0, buyer, 1, "")); // 10 tokens needed
        assertTrue(erc20Mint.isPurchaseAllowed(slicerId, productIds[0], 0, buyer, 10, "")); // 100 tokens needed
        assertTrue(erc20Mint.isPurchaseAllowed(slicerId, productIds[0], 0, buyer, 20, "")); // 200 tokens needed (exactly at limit)
        assertFalse(erc20Mint.isPurchaseAllowed(slicerId, productIds[0], 0, buyer, 21, "")); // 210 tokens needed (exceeds limit)

        // Test product 2 (unlimited supply)
        assertTrue(erc20Mint.isPurchaseAllowed(slicerId, productIds[1], 0, buyer, 1, ""));
        assertTrue(erc20Mint.isPurchaseAllowed(slicerId, productIds[1], 0, buyer, 1000, ""));
        assertTrue(erc20Mint.isPurchaseAllowed(slicerId, productIds[1], 0, buyer, type(uint256).max, ""));
    }

    function testOnProductPurchase() public {
        vm.startPrank(productOwner);

        // Configure products with different settings
        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                "Test Token 1", // name
                "TT1", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                true, // revertOnMaxSupplyReached
                1000, // maxSupply
                100 // tokensPerUnit
            )
        );

        erc20Mint.configureProduct(
            slicerId,
            productIds[1],
            variantId,
            abi.encode(
                "Test Token 2", // name
                "TT2", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                false, // revertOnMaxSupplyReached
                0, // maxSupply (unlimited)
                50 // tokensPerUnit
            )
        );

        vm.stopPrank();

        (ERC20Mint_BaseToken token1,,) = erc20Mint.tokenData(slicerId, productIds[0], variantId);
        (ERC20Mint_BaseToken token2,,) = erc20Mint.tokenData(slicerId, productIds[1], variantId);

        // Test minting for product 1
        uint256 initialBalance1 = token1.balanceOf(buyer);
        uint256 initialSupply1 = token1.totalSupply();

        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onProductPurchase(slicerId, productIds[0], variantId, buyer, 3, "");

        assertEq(token1.balanceOf(buyer), initialBalance1 + 300); // 3 * 100
        assertEq(token1.totalSupply(), initialSupply1 + 300);

        // Test minting for product 2
        uint256 initialBalance2 = token2.balanceOf(buyer2);
        uint256 initialSupply2 = token2.totalSupply();

        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onProductPurchase(slicerId, productIds[1], variantId, buyer2, 5, "");

        assertEq(token2.balanceOf(buyer2), initialBalance2 + 250); // 5 * 50
        assertEq(token2.totalSupply(), initialSupply2 + 250);

        // Test multiple purchases
        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onProductPurchase(slicerId, productIds[0], variantId, buyer3, 2, "");
        assertEq(token1.balanceOf(buyer3), 200); // 2 * 100
        assertEq(token1.totalSupply(), initialSupply1 + 500); // 300 + 200
    }

    function testOnProductPurchase_NoRevertOnMaxSupply() public {
        vm.startPrank(productOwner);

        // Configure product with max supply but revert disabled
        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                990, // premintAmount (close to max)
                productOwner, // premintReceiver
                false, // revertOnMaxSupplyReached (disabled)
                1000, // maxSupply
                10 // tokensPerUnit
            )
        );

        vm.stopPrank();

        // This should succeed but not mint tokens (exceeds max supply)
        (ERC20Mint_BaseToken token,,) = erc20Mint.tokenData(slicerId, productIds[0], variantId);
        uint256 initialBalance = token.balanceOf(buyer);
        uint256 initialSupply = token.totalSupply();

        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onProductPurchase(slicerId, productIds[0], variantId, buyer, 2, "");

        // Balance and supply should remain unchanged (mint failed silently)
        assertEq(token.balanceOf(buyer), initialBalance);
        assertEq(token.totalSupply(), initialSupply);
    }

    function testRevert_onProductPurchase_MaxSupplyReached() public {
        vm.startPrank(productOwner);

        // Configure product with small max supply and revert enabled
        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                950, // premintAmount (close to max)
                productOwner, // premintReceiver
                true, // revertOnMaxSupplyReached
                1000, // maxSupply
                10 // tokensPerUnit
            )
        );

        vm.stopPrank();

        // This should succeed (50 tokens available, need 50)
        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onProductPurchase(slicerId, productIds[0], 0, buyer, 5, "");

        (ERC20Mint_BaseToken token,,) = erc20Mint.tokenData(slicerId, productIds[0], variantId);
        assertEq(token.totalSupply(), 1000); // at max supply

        // This should revert (no tokens available)
        vm.expectRevert(RegistryProductAction.NotAllowed.selector);
        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onProductPurchase(slicerId, productIds[0], variantId, buyer, 1, "");
    }

    function testVariantSpecificTokenConfiguration() public {
        vm.startPrank(productOwner);

        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantId,
            abi.encode(
                "Product Token", // name
                "PT0", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                true, // revertOnMaxSupplyReached
                1000, // maxSupply
                10 // tokensPerUnit
            )
        );

        erc20Mint.configureProduct(
            slicerId,
            productIds[0],
            variantIdAlt,
            abi.encode(
                "Variant Token", // name
                "VT1", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                false, // revertOnMaxSupplyReached
                0, // maxSupply (unlimited)
                5 // tokensPerUnit
            )
        );

        vm.stopPrank();

        (ERC20Mint_BaseToken productToken, bool revertProduct, uint256 tokensPerUnitProduct) =
            erc20Mint.tokenData(slicerId, productIds[0], variantId);
        (ERC20Mint_BaseToken variantToken, bool revertVariant, uint256 tokensPerUnitVariant) =
            erc20Mint.tokenData(slicerId, productIds[0], variantIdAlt);

        assertTrue(address(productToken) != address(variantToken));
        assertTrue(revertProduct);
        assertFalse(revertVariant);
        assertEq(tokensPerUnitProduct, 10);
        assertEq(tokensPerUnitVariant, 5);

        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onProductPurchase(slicerId, productIds[0], variantId, buyer, 2, "");

        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onProductPurchase(slicerId, productIds[0], variantIdAlt, buyer2, 3, "");

        assertEq(productToken.balanceOf(buyer), 20);
        assertEq(variantToken.balanceOf(buyer2), 15);
        assertEq(variantToken.balanceOf(buyer), 0);
    }

    /*//////////////////////////////////////////////////////////////
        PRODUCT TYPE TESTS
    //////////////////////////////////////////////////////////////*/

    function testConfigureProductType() public {
        bytes memory params = abi.encode(
            "ProductType Token", // name
            "PTT", // symbol
            1000, // premintAmount
            productOwner, // premintReceiver
            true, // revertOnMaxSupplyReached
            10000, // maxSupply
            100 // tokensPerUnit
        );

        vm.expectEmit(true, true, true, true, address(erc20Mint));
        emit HookRegistry.ProductTypeConfigured(slicerId, productTypeId, params);

        vm.prank(productOwner);
        erc20Mint.configureProductType(slicerId, productTypeId, params);

        (ERC20Mint_BaseToken token, bool revertOnMaxSupply, uint256 tokensPerUnit) =
            erc20Mint.productTypeTokenData(slicerId, productTypeId);
        assertEq(revertOnMaxSupply, true);
        assertEq(tokensPerUnit, 100);
        assertEq(token.name(), "ProductType Token");
        assertEq(token.symbol(), "PTT");
        assertEq(token.maxSupply(), 10000);
        assertEq(token.totalSupply(), 1000); // premint amount
        assertEq(token.balanceOf(productOwner), 1000);
    }

    function testConfigureProductType_AccessControl() public {
        vm.expectRevert(abi.encodeWithSelector(SliceContext.NotAuthorized.selector, bytes32(uint256(1 << 1 | 1 << 3))));

        erc20Mint.configureProductType(slicerId, productTypeId, "");
    }

    function testConfigureProductTypeSchema() public view {
        string memory schema = erc20Mint.configureProductTypeSchema();

        assertEq(schema, erc20Mint.configureProductSchema());
        assertTrue(bytes(schema).length > 0);
    }

    function testIsProductTypePurchaseAllowed() public {
        vm.prank(productOwner);
        erc20Mint.configureProductType(
            slicerId,
            productTypeId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                800, // premintAmount
                productOwner, // premintReceiver
                true, // revertOnMaxSupplyReached
                1000, // maxSupply
                10 // tokensPerUnit
            )
        );

        // Current supply: 800, max supply: 1000
        // Available: 200 tokens, with 10 tokens per unit = 20 units max
        assertTrue(erc20Mint.isProductTypePurchaseAllowed(slicerId, productTypeId, buyer, 1)); // 10 tokens needed
        assertTrue(erc20Mint.isProductTypePurchaseAllowed(slicerId, productTypeId, buyer, 20)); // 200 tokens needed (exactly at limit)
        assertFalse(erc20Mint.isProductTypePurchaseAllowed(slicerId, productTypeId, buyer, 21)); // 210 tokens needed (exceeds limit)
    }

    function testOnProductTypePurchase() public {
        vm.prank(productOwner);
        erc20Mint.configureProductType(
            slicerId,
            productTypeId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                true, // revertOnMaxSupplyReached
                1000, // maxSupply
                100 // tokensPerUnit
            )
        );

        (ERC20Mint_BaseToken token,,) = erc20Mint.productTypeTokenData(slicerId, productTypeId);
        uint256 initialBalance = token.balanceOf(buyer);
        uint256 initialSupply = token.totalSupply();

        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onProductTypePurchase(slicerId, productTypeId, buyer, 3);

        assertEq(token.balanceOf(buyer), initialBalance + 300); // 3 * 100
        assertEq(token.totalSupply(), initialSupply + 300);
    }

    function testRevert_OnProductTypePurchase_NotPurchase() public {
        vm.prank(productOwner);
        erc20Mint.configureProductType(
            slicerId,
            productTypeId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                true, // revertOnMaxSupplyReached
                1000, // maxSupply
                100 // tokensPerUnit
            )
        );

        vm.expectRevert();
        erc20Mint.onProductTypePurchase(slicerId, productTypeId, buyer, 1);
    }

    /*//////////////////////////////////////////////////////////////
        SLICER TESTS
    //////////////////////////////////////////////////////////////*/

    function testConfigureSlicer() public {
        bytes memory params = abi.encode(
            "Slicer Token", // name
            "ST", // symbol
            500, // premintAmount
            buyer, // premintReceiver
            false, // revertOnMaxSupplyReached
            0, // maxSupply (unlimited)
            50 // tokensPerUnit
        );

        vm.expectEmit(true, true, true, true, address(erc20Mint));
        emit HookRegistry.SlicerConfigured(slicerId, params);

        vm.prank(productOwner);
        erc20Mint.configureSlicer(slicerId, params);

        (ERC20Mint_BaseToken token, bool revertOnMaxSupply, uint256 tokensPerUnit) = erc20Mint.slicerTokenData(slicerId);
        assertEq(revertOnMaxSupply, false);
        assertEq(tokensPerUnit, 50);
        assertEq(token.name(), "Slicer Token");
        assertEq(token.symbol(), "ST");
        assertEq(token.maxSupply(), type(uint256).max);
        assertEq(token.totalSupply(), 500); // premint amount
        assertEq(token.balanceOf(buyer), 500);
    }

    function testConfigureSlicer_AccessControl() public {
        vm.expectRevert(abi.encodeWithSelector(SliceContext.NotAuthorized.selector, bytes32(uint256(1 << 1 | 1 << 3))));

        erc20Mint.configureSlicer(slicerId, "");
    }

    function testConfigureSlicerSchema() public view {
        string memory schema = erc20Mint.configureSlicerSchema();

        assertEq(schema, erc20Mint.configureProductSchema());
        assertTrue(bytes(schema).length > 0);
    }

    function testIsSlicerPurchaseAllowed() public {
        vm.prank(productOwner);
        erc20Mint.configureSlicer(
            slicerId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                false, // revertOnMaxSupplyReached
                0, // maxSupply (unlimited)
                50 // tokensPerUnit
            )
        );

        ProductLineItem[] memory productLineItems = new ProductLineItem[](2);
        productLineItems[0] =
            ProductLineItem({productId: uint32(productIds[0]), variantId: uint32(variantId), quantity: uint32(5)});
        productLineItems[1] =
            ProductLineItem({productId: uint32(productIds[1]), variantId: uint32(variantId), quantity: uint32(3)});
        // Total quantity: 8, tokens needed: 8 * 50 = 400

        // Unlimited supply, so should always return true
        assertTrue(erc20Mint.isSlicerPurchaseAllowed(slicerId, buyer, productLineItems));
    }

    function testOnSlicerPurchase() public {
        vm.prank(productOwner);
        erc20Mint.configureSlicer(
            slicerId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                false, // revertOnMaxSupplyReached
                0, // maxSupply (unlimited)
                50 // tokensPerUnit
            )
        );

        ProductLineItem[] memory productLineItems = new ProductLineItem[](2);
        productLineItems[0] =
            ProductLineItem({productId: uint32(productIds[0]), variantId: uint32(variantId), quantity: uint32(2)});
        productLineItems[1] =
            ProductLineItem({productId: uint32(productIds[1]), variantId: uint32(variantId), quantity: uint32(3)});
        // Total quantity: 5, tokens to mint: 5 * 50 = 250

        (ERC20Mint_BaseToken token,,) = erc20Mint.slicerTokenData(slicerId);
        uint256 initialBalance = token.balanceOf(buyer);
        uint256 initialSupply = token.totalSupply();

        vm.prank(address(PRODUCTS_MODULE));
        erc20Mint.onSlicerPurchase(slicerId, buyer, productLineItems);

        assertEq(token.balanceOf(buyer), initialBalance + 250); // 5 * 50
        assertEq(token.totalSupply(), initialSupply + 250);
    }

    function testRevert_OnSlicerPurchase_NotPurchase() public {
        vm.prank(productOwner);
        erc20Mint.configureSlicer(
            slicerId,
            abi.encode(
                "Test Token", // name
                "TT", // symbol
                0, // premintAmount
                address(0), // premintReceiver
                false, // revertOnMaxSupplyReached
                0, // maxSupply (unlimited)
                50 // tokensPerUnit
            )
        );

        ProductLineItem[] memory productLineItems = new ProductLineItem[](1);
        productLineItems[0] =
            ProductLineItem({productId: uint32(productIds[0]), variantId: uint32(variantId), quantity: uint32(5)});

        vm.expectRevert();
        erc20Mint.onSlicerPurchase(slicerId, buyer, productLineItems);
    }
}
