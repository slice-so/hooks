// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {CommonStorage} from "slice/utils/CommonStorage.sol";
import {Allowlisted, ERC20Gated, ERC20Mint, ERC721Mint, NFTGated} from "../src/hooks/actions/actions.sol";
import {NFTDiscount, LinearVRGDAPrices, LogisticVRGDAPrices} from "../src/hooks/pricing/pricing.sol";
import {FirstForFree} from "../src/hooks/pricingActions/pricingActions.sol";

// Script to seed the hooks contracts

contract SeedHooksScript is Script, CommonStorage {
    struct Hook {
        address hookAddress;
        bytes code;
    }

    function _setCode(address target, bytes memory bytecode) internal {
        string memory params = string.concat('["', vm.toString(target), '","', vm.toString(bytecode), '"]');
        vm.rpc("anvil_setCode", params);
    }

    function run() external {
        vm.startBroadcast();

        Hook[] memory hooks = new Hook[](9);
        hooks[0] = Hook({
            hookAddress: 0x157428DD791E03c20880D22C3dA2B66A36B5cF26,
            code: address(new Allowlisted(PRODUCTS_MODULE())).code
        });
        hooks[1] = Hook({
            hookAddress: 0x26A1C86B555013995Fc72864D261fDe984752E7c,
            code: address(new ERC20Gated(PRODUCTS_MODULE())).code
        });
        hooks[2] = Hook({
            hookAddress: 0x67f9799FaC1D53C63217BEE47f553150F5BB0836,
            code: address(new ERC20Mint(PRODUCTS_MODULE())).code
        });
        hooks[3] = Hook({
            hookAddress: 0x2b6488115FAa50142E140172CbCd60e6370675F7,
            code: address(new ERC721Mint(PRODUCTS_MODULE())).code
        });
        hooks[4] = Hook({
            hookAddress: 0xD4eF7A46bF4c58036eaCA886119F5230e5a2C25d,
            code: address(new NFTGated(PRODUCTS_MODULE())).code
        });
        hooks[5] = Hook({
            hookAddress: 0xb830a457d2f51d4cA1136b97FB30DF6366CFe2f5,
            code: address(new NFTDiscount(PRODUCTS_MODULE())).code
        });
        hooks[6] = Hook({
            hookAddress: 0xEC68E30182F4298b7032400B7ce809da613e4449,
            code: address(new LinearVRGDAPrices(PRODUCTS_MODULE())).code
        });
        hooks[7] = Hook({
            hookAddress: 0x2b02cC8528EF18abf8185543CEC29A94F0542c8F,
            code: address(new LogisticVRGDAPrices(PRODUCTS_MODULE())).code
        });
        hooks[8] = Hook({
            hookAddress: 0xEC68E30182F4298b7032400B7ce809da613e4449,
            code: address(new FirstForFree(PRODUCTS_MODULE())).code
        });

        // Deploy hooks
        for (uint256 i = 0; i < hooks.length; i++) {
            _setCode(hooks[i].hookAddress, hooks[i].code);
        }

        vm.stopBroadcast();
    }
}
