// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Contracts} from "slice/utils/Contracts.sol";
import {Allowlisted, ERC20Gated, ERC20Mint, ERC721Mint, NFTGated} from "../src/hooks/actions/actions.sol";
import {NFTDiscount, LinearVRGDAPrices, LogisticVRGDAPrices} from "../src/hooks/pricing/pricing.sol";
import {FirstForFree} from "../src/hooks/pricingActions/pricingActions.sol";

// Script to seed the hooks contracts

contract SeedHooksScript is Script {
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

        string memory json = vm.readFile("./deployments/addresses.json");
        Hook[] memory hooks = new Hook[](9);
        hooks[0] = Hook({
            hookAddress: vm.parseJsonAddress(json, ".actions.Allowlisted.[0].address"),
            code: address(new Allowlisted(Contracts.PRODUCTS_MODULE)).code
        });
        hooks[1] = Hook({
            hookAddress: vm.parseJsonAddress(json, ".actions.ERC20Gated.[0].address"),
            code: address(new ERC20Gated(Contracts.PRODUCTS_MODULE)).code
        });
        hooks[2] = Hook({
            hookAddress: vm.parseJsonAddress(json, ".actions.ERC20Mint.[0].address"),
            code: address(new ERC20Mint(Contracts.PRODUCTS_MODULE)).code
        });
        hooks[3] = Hook({
            hookAddress: vm.parseJsonAddress(json, ".actions.ERC721Mint.[0].address"),
            code: address(new ERC721Mint(Contracts.PRODUCTS_MODULE)).code
        });
        hooks[4] = Hook({
            hookAddress: vm.parseJsonAddress(json, ".actions.NFTGated.[0].address"),
            code: address(new NFTGated(Contracts.PRODUCTS_MODULE)).code
        });
        hooks[5] = Hook({
            hookAddress: vm.parseJsonAddress(json, ".pricing.NFTDiscount.[0].address"),
            code: address(new NFTDiscount(Contracts.PRODUCTS_MODULE)).code
        });
        hooks[6] = Hook({
            hookAddress: vm.parseJsonAddress(json, ".pricing.LinearVRGDAPrices.[0].address"),
            code: address(new LinearVRGDAPrices(Contracts.PRODUCTS_MODULE)).code
        });
        hooks[7] = Hook({
            hookAddress: vm.parseJsonAddress(json, ".pricing.LogisticVRGDAPrices.[0].address"),
            code: address(new LogisticVRGDAPrices(Contracts.PRODUCTS_MODULE)).code
        });
        hooks[8] = Hook({
            hookAddress: vm.parseJsonAddress(json, ".pricingActions.FirstForFree.[0].address"),
            code: address(new FirstForFree(Contracts.PRODUCTS_MODULE)).code
        });

        // Deploy hooks
        for (uint256 i = 0; i < hooks.length; i++) {
            _setCode(hooks[i].hookAddress, hooks[i].code);
        }

        vm.stopBroadcast();
    }
}
