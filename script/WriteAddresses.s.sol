// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {SetUpContractsList} from "./ScriptUtils.sol";

contract WriteAddressesScript is SetUpContractsList {
    constructor() SetUpContractsList("src") {}

    function run(string memory contractName) external {
        writeAddressesJson(contractName);
    }
}
