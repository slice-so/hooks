// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductActionTest} from "@test/utils/RegistryProductActionTest.sol";
import {MockERC20Gated} from "./mocks/MockERC20Gated.sol";
import {ERC20Gate} from "@/hooks/actions/ERC20Gated/ERC20Gated.sol";
import {IERC20, MockERC20} from "@test/utils/mocks/MockERC20.sol";

uint256 constant slicerId = 0;
uint256 constant productId = 1;
uint256 constant variantId = 0;
uint256 constant variantIdAlt = 1;

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
}
