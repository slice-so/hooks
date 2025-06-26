// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {BaseScript, SetUpContractsList} from "./ScriptUtils.sol";

contract DeployScript is BaseScript, SetUpContractsList {
    constructor() SetUpContractsList("src") {}

    function run(string memory contractName) public broadcast returns (address contractAddress) {
        contractAddress = deployCode(contractName, abi.encode(PRODUCTS_MODULE));
    }

    function run() external returns (address contractAddress, string memory contractName) {
        contractName = _promptContractName();
        contractAddress = run(contractName);
    }

    function _promptContractName() internal returns (string memory contractName) {
        string memory prompt = "\nContracts available to deploy:\n";
        string memory lastTopFolder = "";
        for (uint256 i = 0; i < contractNames.length; i++) {
            (string memory topFolderName,) = _getFolderName(contractNames[i].path);
            // Print top-level folder if changed
            if (i == 0 || keccak256(bytes(topFolderName)) != keccak256(bytes(lastTopFolder))) {
                prompt = string.concat(prompt, "\n", topFolderName, "\n");
                lastTopFolder = topFolderName;
            }
            prompt = string.concat(prompt, "    ", vm.toString(contractNames[i].id), ") ", contractNames[i].name, "\n");
        }
        prompt = string.concat(prompt, "\nEnter the number of the contract to deploy");

        uint256 contractId = vm.promptUint(prompt);
        contractName = contractNames[contractId - 1].name;
        require(bytes(contractName).length > 0, "Invalid ID");
    }
}
