// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductActionTest} from "@test/utils/RegistryProductActionTest.sol";
import {MockERC20Gated} from "./mocks/MockERC20Gated.sol";
import {ERC20Gate} from "@/hooks/actions/ERC20Gated/ERC20Gated.sol";
import {IERC20, MockERC20} from "@test/utils/mocks/MockERC20.sol";
import {HookRegistry, ProductLineItem} from "@/utils/RegistryAction.sol";
import {SliceContext} from "@/utils/RegistryProductAction.sol";

uint256 constant slicerId = 0;
uint256 constant productId = 1;
uint256 constant variantId = 0;
uint256 constant variantIdAlt = 1;
uint256 constant productTypeId = 2;

contract ERC20GatedTest is RegistryProductActionTest {
    MockERC20Gated erc20Gated;
    MockERC20 token = new MockERC20("Test", "TST", 18);
    MockERC20 token2 = new MockERC20("Test2", "TST2", 18);

    function setUp() public {
        erc20Gated = new MockERC20Gated(PRODUCTS_MODULE);
        _setHook(address(erc20Gated));
    }

    function testConfigureProduct() public {
        ERC20Gate[] memory gates = new ERC20Gate[](1);
        gates[0] = ERC20Gate(token, 100);

        vm.prank(productOwner);
        erc20Gated.configureProduct(slicerId, productId, variantId, abi.encode(gates));

        (IERC20 tokenAddr, uint256 amount) = erc20Gated.tokenGates(slicerId, productId, variantId, 0);
        assertTrue(address(tokenAddr) == address(token));
        assertTrue(amount == 100);
    }

    function testReconfigureProduct() public {
        ERC20Gate[] memory gates = new ERC20Gate[](2);
        gates[0] = ERC20Gate(token, 100);
        gates[1] = ERC20Gate(token2, 200);

        vm.startPrank(productOwner);
        erc20Gated.configureProduct(slicerId, productId, variantId, abi.encode(gates));

        assertEq(address(erc20Gated.gates(slicerId, productId, variantId)[0].erc20), address(token));
        assertEq(erc20Gated.gates(slicerId, productId, variantId)[0].amount, 100);
        assertEq(address(erc20Gated.gates(slicerId, productId, variantId)[1].erc20), address(token2));
        assertEq(erc20Gated.gates(slicerId, productId, variantId)[1].amount, 200);
        assertEq(erc20Gated.gates(slicerId, productId, variantId).length, 2);

        MockERC20 token3 = new MockERC20("Test3", "TST3", 18);
        gates = new ERC20Gate[](1);
        gates[0] = ERC20Gate(token3, 300);

        erc20Gated.configureProduct(slicerId, productId, variantId, abi.encode(gates));
        assertEq(address(erc20Gated.gates(slicerId, productId, variantId)[0].erc20), address(token3));
        assertEq(erc20Gated.gates(slicerId, productId, variantId)[0].amount, 300);
        assertEq(erc20Gated.gates(slicerId, productId, variantId).length, 1);

        vm.stopPrank();
    }

    function testIsPurchaseAllowed() public {
        ERC20Gate[] memory gates = new ERC20Gate[](1);
        gates[0] = ERC20Gate(token, 100);

        vm.prank(productOwner);
        erc20Gated.configureProduct(slicerId, productId, variantId, abi.encode(gates));

        assertFalse(erc20Gated.isPurchaseAllowed(slicerId, productId, variantId, buyer, 0, ""));

        token.mint(buyer, 100);
        assertTrue(erc20Gated.isPurchaseAllowed(slicerId, productId, variantId, buyer, 0, ""));
    }

    function testIsPurchaseAllowed_variantSpecificConfiguration() public {
        ERC20Gate[] memory productGates = new ERC20Gate[](1);
        productGates[0] = ERC20Gate(token, 100);

        ERC20Gate[] memory variantGates = new ERC20Gate[](1);
        variantGates[0] = ERC20Gate(token2, 200);

        vm.startPrank(productOwner);
        erc20Gated.configureProduct(slicerId, productId, variantId, abi.encode(productGates));
        erc20Gated.configureProduct(slicerId, productId, variantIdAlt, abi.encode(variantGates));
        vm.stopPrank();

        assertFalse(erc20Gated.isPurchaseAllowed(slicerId, productId, variantId, buyer, 0, ""));
        assertFalse(erc20Gated.isPurchaseAllowed(slicerId, productId, variantIdAlt, buyer, 0, ""));

        token.mint(buyer, 100);
        assertTrue(erc20Gated.isPurchaseAllowed(slicerId, productId, variantId, buyer, 0, ""));
        // Variant gate still unmet as it requires a different token
        assertFalse(erc20Gated.isPurchaseAllowed(slicerId, productId, variantIdAlt, buyer, 0, ""));

        token2.mint(buyer, 200);
        assertTrue(erc20Gated.isPurchaseAllowed(slicerId, productId, variantIdAlt, buyer, 0, ""));

        (IERC20 tokenAddrDefault, uint256 amountDefault) = erc20Gated.tokenGates(slicerId, productId, variantId, 0);
        (IERC20 tokenAddrVariant, uint256 amountVariant) = erc20Gated.tokenGates(slicerId, productId, variantIdAlt, 0);

        assertEq(address(tokenAddrDefault), address(token));
        assertEq(amountDefault, 100);
        assertEq(address(tokenAddrVariant), address(token2));
        assertEq(amountVariant, 200);
    }

    /*//////////////////////////////////////////////////////////////
        PRODUCT TYPE TESTS
    //////////////////////////////////////////////////////////////*/

    function testConfigureProductType() public {
        ERC20Gate[] memory gates = new ERC20Gate[](2);
        gates[0] = ERC20Gate(token2, 200);
        gates[1] = ERC20Gate(token, 100);

        bytes memory params = abi.encode(gates);

        vm.expectEmit(true, true, true, true, address(erc20Gated));
        emit HookRegistry.ProductTypeConfigured(slicerId, productTypeId, params);

        vm.prank(productOwner);
        erc20Gated.configureProductType(slicerId, productTypeId, params);

        assertEq(address(erc20Gated.productTypeGates(slicerId, productTypeId)[0].erc20), address(token2));
        assertEq(erc20Gated.productTypeGates(slicerId, productTypeId)[0].amount, 200);
        assertEq(address(erc20Gated.productTypeGates(slicerId, productTypeId)[1].erc20), address(token));
        assertEq(erc20Gated.productTypeGates(slicerId, productTypeId)[1].amount, 100);
        assertEq(erc20Gated.productTypeGates(slicerId, productTypeId).length, 2);

        // Buyer doesn't have tokens yet
        assertFalse(erc20Gated.isProductTypePurchaseAllowed(slicerId, productTypeId, buyer, 0));

        // Buyer has token but not token2
        token.mint(buyer, 100);
        assertFalse(erc20Gated.isProductTypePurchaseAllowed(slicerId, productTypeId, buyer, 0));

        // Buyer has both tokens
        token2.mint(buyer, 200);
        assertTrue(erc20Gated.isProductTypePurchaseAllowed(slicerId, productTypeId, buyer, 0));
    }

    function testConfigureProductType_AccessControl() public {
        vm.expectRevert(abi.encodeWithSelector(SliceContext.NotAuthorized.selector, bytes32(uint256(1 << 1 | 1 << 3))));

        erc20Gated.configureProductType(slicerId, productTypeId, "");
    }

    function testConfigureProductTypeSchema() public view {
        string memory schema = erc20Gated.configureProductTypeSchema();

        assertEq(schema, erc20Gated.configureProductSchema());
        assertTrue(bytes(schema).length > 0);
    }

    function testIsProductTypePurchaseAllowed_NoGates() public {
        vm.prank(productOwner);
        erc20Gated.configureProductType(slicerId, productTypeId, abi.encode(new ERC20Gate[](0)));

        assertTrue(erc20Gated.isProductTypePurchaseAllowed(slicerId, productTypeId, buyer2, 0));
    }

    function testConfigureProductType__Edit_Remove() public {
        ERC20Gate[] memory gates = new ERC20Gate[](2);
        gates[0] = ERC20Gate(token2, 200);
        gates[1] = ERC20Gate(token, 100);

        vm.prank(productOwner);
        erc20Gated.configureProductType(slicerId, productTypeId, abi.encode(gates));

        token.mint(buyer, 100);
        token2.mint(buyer, 200);
        assertTrue(erc20Gated.isProductTypePurchaseAllowed(slicerId, productTypeId, buyer, 0));

        // Remove gates
        vm.prank(productOwner);
        erc20Gated.configureProductType(slicerId, productTypeId, abi.encode(new ERC20Gate[](0)));

        assertTrue(erc20Gated.isProductTypePurchaseAllowed(slicerId, productTypeId, buyer, 0));
        assertEq(erc20Gated.productTypeGates(slicerId, productTypeId).length, 0);
    }

    function testOnProductTypePurchase() public {
        ERC20Gate[] memory gates = new ERC20Gate[](1);
        gates[0] = ERC20Gate(token, 100);

        vm.prank(productOwner);
        erc20Gated.configureProductType(slicerId, productTypeId, abi.encode(gates));

        // Buyer doesn't have tokens - should revert
        vm.expectRevert();
        vm.prank(address(PRODUCTS_MODULE));
        erc20Gated.onProductTypePurchase(slicerId, productTypeId, buyer, 1);

        // Buyer has tokens - should succeed
        token.mint(buyer, 100);
        vm.prank(address(PRODUCTS_MODULE));
        erc20Gated.onProductTypePurchase(slicerId, productTypeId, buyer, 1);
    }

    function testRevert_OnProductTypePurchase_NotPurchase() public {
        ERC20Gate[] memory gates = new ERC20Gate[](1);
        gates[0] = ERC20Gate(token, 100);

        vm.prank(productOwner);
        erc20Gated.configureProductType(slicerId, productTypeId, abi.encode(gates));

        token.mint(buyer, 100);

        vm.expectRevert();
        erc20Gated.onProductTypePurchase(slicerId, productTypeId, buyer, 1);
    }

    /*//////////////////////////////////////////////////////////////
        SLICER TESTS
    //////////////////////////////////////////////////////////////*/

    function testConfigureSlicer() public {
        ERC20Gate[] memory gates = new ERC20Gate[](2);
        gates[0] = ERC20Gate(token2, 200);
        gates[1] = ERC20Gate(token, 100);

        bytes memory params = abi.encode(gates);

        vm.expectEmit(true, true, true, true, address(erc20Gated));
        emit HookRegistry.SlicerConfigured(slicerId, params);

        vm.prank(productOwner);
        erc20Gated.configureSlicer(slicerId, params);

        assertEq(address(erc20Gated.slicerGates(slicerId)[0].erc20), address(token2));
        assertEq(erc20Gated.slicerGates(slicerId)[0].amount, 200);
        assertEq(address(erc20Gated.slicerGates(slicerId)[1].erc20), address(token));
        assertEq(erc20Gated.slicerGates(slicerId)[1].amount, 100);
        assertEq(erc20Gated.slicerGates(slicerId).length, 2);

        // Buyer doesn't have tokens yet
        ProductLineItem[] memory productLineItems = new ProductLineItem[](1);
        productLineItems[0] =
            ProductLineItem({productId: uint32(productId), variantId: uint32(variantId), quantity: uint32(5)});
        assertFalse(erc20Gated.isSlicerPurchaseAllowed(slicerId, buyer, productLineItems));

        // Buyer has token but not token2
        token.mint(buyer, 100);
        assertFalse(erc20Gated.isSlicerPurchaseAllowed(slicerId, buyer, productLineItems));

        // Buyer has both tokens
        token2.mint(buyer, 200);
        assertTrue(erc20Gated.isSlicerPurchaseAllowed(slicerId, buyer, productLineItems));
    }

    function testConfigureSlicer_AccessControl() public {
        vm.expectRevert(abi.encodeWithSelector(SliceContext.NotAuthorized.selector, bytes32(uint256(1 << 1 | 1 << 3))));

        erc20Gated.configureSlicer(slicerId, "");
    }

    function testConfigureSlicerSchema() public view {
        string memory schema = erc20Gated.configureSlicerSchema();

        assertEq(schema, erc20Gated.configureProductSchema());
        assertTrue(bytes(schema).length > 0);
    }

    function testIsSlicerPurchaseAllowed_NoGates() public {
        vm.prank(productOwner);
        erc20Gated.configureSlicer(slicerId, abi.encode(new ERC20Gate[](0)));

        ProductLineItem[] memory productLineItems = new ProductLineItem[](1);
        productLineItems[0] =
            ProductLineItem({productId: uint32(productId), variantId: uint32(variantId), quantity: uint32(5)});
        assertTrue(erc20Gated.isSlicerPurchaseAllowed(slicerId, buyer3, productLineItems));
    }

    function testConfigureSlicer__Edit_Remove() public {
        ERC20Gate[] memory gates = new ERC20Gate[](2);
        gates[0] = ERC20Gate(token2, 200);
        gates[1] = ERC20Gate(token, 100);

        vm.prank(productOwner);
        erc20Gated.configureSlicer(slicerId, abi.encode(gates));

        token.mint(buyer, 100);
        token2.mint(buyer, 200);

        ProductLineItem[] memory productLineItems = new ProductLineItem[](1);
        productLineItems[0] =
            ProductLineItem({productId: uint32(productId), variantId: uint32(variantId), quantity: uint32(5)});
        assertTrue(erc20Gated.isSlicerPurchaseAllowed(slicerId, buyer, productLineItems));

        // Remove gates
        vm.prank(productOwner);
        erc20Gated.configureSlicer(slicerId, abi.encode(new ERC20Gate[](0)));

        assertTrue(erc20Gated.isSlicerPurchaseAllowed(slicerId, buyer, productLineItems));
        assertEq(erc20Gated.slicerGates(slicerId).length, 0);
    }

    function testOnSlicerPurchase() public {
        ERC20Gate[] memory gates = new ERC20Gate[](1);
        gates[0] = ERC20Gate(token, 100);

        vm.prank(productOwner);
        erc20Gated.configureSlicer(slicerId, abi.encode(gates));

        ProductLineItem[] memory productLineItems = new ProductLineItem[](1);
        productLineItems[0] =
            ProductLineItem({productId: uint32(productId), variantId: uint32(variantId), quantity: uint32(5)});

        // Buyer doesn't have tokens - should revert
        vm.expectRevert();
        vm.prank(address(PRODUCTS_MODULE));
        erc20Gated.onSlicerPurchase(slicerId, buyer, productLineItems);

        // Buyer has tokens - should succeed
        token.mint(buyer, 100);
        vm.prank(address(PRODUCTS_MODULE));
        erc20Gated.onSlicerPurchase(slicerId, buyer, productLineItems);
    }

    function testRevert_OnSlicerPurchase_NotPurchase() public {
        ERC20Gate[] memory gates = new ERC20Gate[](1);
        gates[0] = ERC20Gate(token, 100);

        vm.prank(productOwner);
        erc20Gated.configureSlicer(slicerId, abi.encode(gates));

        token.mint(buyer, 100);

        ProductLineItem[] memory productLineItems = new ProductLineItem[](1);
        productLineItems[0] =
            ProductLineItem({productId: uint32(productId), variantId: uint32(variantId), quantity: uint32(5)});

        vm.expectRevert();
        erc20Gated.onSlicerPurchase(slicerId, buyer, productLineItems);
    }
}
