// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistryOnchainActionTest} from "@test/utils/RegistryOnchainActionTest.sol";
import {ERC20Gated, ERC20Gate} from "@/hooks/actions/ERC20Gated/ERC20Gated.sol";
import {IERC20, MockERC20} from "@test/utils/mocks/MockERC20.sol";

uint256 constant slicerId = 0;
uint256 constant productId = 1;

contract ERC20GatedTest is RegistryOnchainActionTest {
    ERC20Gated erc20Gated;
    MockERC20 token = new MockERC20();

    function setUp() public {
        erc20Gated = new ERC20Gated(PRODUCTS_MODULE);
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
