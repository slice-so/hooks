// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistryOnchainActionTest} from "@test/utils/RegistryOnchainActionTest.sol";
import {MockERC20Gated} from "./mocks/MockERC20Gated.sol";
import {ERC20Gate} from "@/hooks/actions/ERC20Gated/ERC20Gated.sol";
import {IERC20, MockERC20} from "@test/utils/mocks/MockERC20.sol";

uint256 constant slicerId = 0;
uint256 constant productId = 1;

contract ERC20GatedTest is RegistryOnchainActionTest {
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
        erc20Gated.configureProduct(slicerId, productId, abi.encode(gates));

        (IERC20 tokenAddr, uint256 amount) = erc20Gated.tokenGates(slicerId, productId, 0);
        assertTrue(address(tokenAddr) == address(token));
        assertTrue(amount == 100);
    }

    function testReconfigureProduct() public {
        ERC20Gate[] memory gates = new ERC20Gate[](2);
        gates[0] = ERC20Gate(token, 100);
        gates[1] = ERC20Gate(token2, 200);

        vm.startPrank(productOwner);
        erc20Gated.configureProduct(slicerId, productId, abi.encode(gates));

        assertEq(address(erc20Gated.gates(slicerId, productId)[0].erc20), address(token));
        assertEq(erc20Gated.gates(slicerId, productId)[0].amount, 100);
        assertEq(address(erc20Gated.gates(slicerId, productId)[1].erc20), address(token2));
        assertEq(erc20Gated.gates(slicerId, productId)[1].amount, 200);
        assertEq(erc20Gated.gates(slicerId, productId).length, 2);

        MockERC20 token3 = new MockERC20("Test3", "TST3", 18);
        gates = new ERC20Gate[](1);
        gates[0] = ERC20Gate(token3, 300);

        erc20Gated.configureProduct(slicerId, productId, abi.encode(gates));
        assertEq(address(erc20Gated.gates(slicerId, productId)[0].erc20), address(token3));
        assertEq(erc20Gated.gates(slicerId, productId)[0].amount, 300);
        assertEq(erc20Gated.gates(slicerId, productId).length, 1);

        vm.stopPrank();
    }

    function testIsPurchaseAllowed() public {
        ERC20Gate[] memory gates = new ERC20Gate[](1);
        gates[0] = ERC20Gate(token, 100);

        vm.prank(productOwner);
        erc20Gated.configureProduct(slicerId, productId, abi.encode(gates));

        assertFalse(erc20Gated.isPurchaseAllowed(slicerId, productId, buyer, 0, "", ""));

        token.mint(buyer, 100);
        assertTrue(erc20Gated.isPurchaseAllowed(slicerId, productId, buyer, 0, "", ""));
    }
}
