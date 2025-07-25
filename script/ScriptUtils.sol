// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {ISliceCore} from "slice/interfaces/ISliceCore.sol";
import {IProductsModule} from "slice/interfaces/IProductsModule.sol";
import {IFundsModule} from "slice/interfaces/IFundsModule.sol";

/**
 * Helper contract to enforce correct chain selection in scripts
 */
abstract contract WithChainIdValidation is Script {
    ISliceCore public immutable SLICE_CORE;
    IProductsModule public immutable PRODUCTS_MODULE;
    IFundsModule public immutable FUNDS_MODULE;

    constructor(uint256 chainId, address sliceCore, address productsModule, address fundsModule) {
        require(block.chainid == chainId, "CHAIN_ID_MISMATCH");
        SLICE_CORE = ISliceCore(sliceCore);
        PRODUCTS_MODULE = IProductsModule(productsModule);
        FUNDS_MODULE = IFundsModule(fundsModule);
    }

    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }
}

abstract contract EthereumScript is WithChainIdValidation {
    constructor()
        WithChainIdValidation(
            1,
            0x21da1b084175f95285B49b22C018889c45E1820d,
            0x689Bba0e25c259b205ECe8e6152Ee1eAcF307f5F,
            0x6bcA3Dfd6c2b146dcdd460174dE95Fd1e26960BC
        )
    {}
}

abstract contract OptimismScript is WithChainIdValidation {
    constructor()
        WithChainIdValidation(
            10,
            0xb9d5B99d5D0fA04dD7eb2b0CD7753317C2ea1a84,
            0x61bCd1ED11fC03C958A847A6687b1875f5eAcaaf,
            0x115978100953D0Aa6f2f8865d11Dc5888f728370
        )
    {}
}

abstract contract BaseScript is WithChainIdValidation {
    constructor()
        WithChainIdValidation(
            8453,
            0x5Cef0380cE0aD3DAEefef8bDb85dBDeD7965adf9,
            0xb9d5B99d5D0fA04dD7eb2b0CD7753317C2ea1a84,
            0x61bCd1ED11fC03C958A847A6687b1875f5eAcaaf
        )
    {}
}

abstract contract BaseGoerliScript is WithChainIdValidation {
    constructor()
        WithChainIdValidation(
            84531,
            0xAE38a794E839D045460839ABe288a8e5C28B0fc6,
            0x0FD0d9aa44a05Ee158DDf6F01d7dcF503388781d,
            0x5Cef0380cE0aD3DAEefef8bDb85dBDeD7965adf9
        )
    {}
}

abstract contract SetUpContractsList is Script {
    struct ContractMap {
        uint256 id;
        string path;
        string name;
    }

    struct ContractDeploymentData {
        address contractAddress;
        uint256 blockNumber;
        bytes32 transactionHash;
    }

    string constant ADDRESSES_PATH = "./deployments/addresses.json";
    string constant LAST_TX_PATH = "./broadcast/Deploy.s.sol/8453/run-latest.json";
    uint64 public constant CHAIN_ID = 8453;
    string public CONTRACT_PATH;

    ContractMap[] public contractNames;
    uint256 startId = 1;

    constructor(string memory path) {
        CONTRACT_PATH = path;
    }

    function setUp() public {
        _recordContractsOnPath(CONTRACT_PATH);
    }

    function _updateGroupJson(
        string memory existingAddresses,
        string memory firstFolder,
        string memory contractName,
        string[] memory json
    ) internal returns (string memory) {
        string memory groupKey = string.concat(".", firstFolder);
        string memory result;

        if (vm.keyExistsJson(existingAddresses, groupKey)) {
            // For each contract in contractNames, if it belongs to this group, add its array
            for (uint256 i = 0; i < contractNames.length; i++) {
                (string memory folderName,) = _getFolderName(contractNames[i].path);
                if (keccak256(bytes(folderName)) == keccak256(bytes(firstFolder))) {
                    string memory name = contractNames[i].name;
                    if (keccak256(bytes(name)) == keccak256(bytes(contractName))) {
                        // Use the new json for the contract being updated
                        result = vm.serializeString(contractName, name, json);
                    } else {
                        string memory contractKey = string.concat(".", firstFolder, ".", name);
                        if (vm.keyExistsJson(existingAddresses, contractKey)) {
                            // Use the existing array for other contracts
                            bytes memory arr = vm.parseJson(existingAddresses, contractKey);
                            ContractDeploymentData[] memory existingData = abi.decode(arr, (ContractDeploymentData[]));

                            // Convert to string array format (similar to _buildJsonArray logic)
                            string[] memory arrStrings = new string[](existingData.length);
                            for (uint256 j = 0; j < existingData.length; j++) {
                                string memory idx = vm.toString(j);
                                vm.serializeAddress(idx, "address", existingData[j].contractAddress);
                                vm.serializeUint(idx, "blockNumber", existingData[j].blockNumber);
                                arrStrings[j] =
                                    vm.serializeBytes32(idx, "transactionHash", existingData[j].transactionHash);
                            }
                            result = vm.serializeString(contractName, name, arrStrings);
                        }
                    }
                }
            }
            return result;
        } else {
            // If the group doesn't exist, just create a new entry for contractName
            return vm.serializeString(contractName, contractName, json);
        }
    }

    function writeAddressesJson(string memory contractName) public {
        string memory existingAddresses = vm.readFile(ADDRESSES_PATH);

        Receipt[] memory receipts = _readReceipts(LAST_TX_PATH);
        Tx1559[] memory transactions = _readTx1559s(LAST_TX_PATH);

        // Find the relevant transaction and receipt
        Tx1559 memory transaction;
        Receipt memory receipt;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (keccak256(bytes(transactions[i].contractName)) == keccak256(bytes(contractName))) {
                transaction = transactions[i];
                receipt = receipts[i];
                break;
            }
        }

        if (transaction.contractAddress == address(0)) {
            console.log("Transaction not found in broadcast artifacts");
            return;
        }

        ContractMap memory contractMap;
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (keccak256(bytes(contractNames[i].name)) == keccak256(bytes(contractName))) {
                contractMap = contractNames[i];
                break;
            }
        }

        // Get the first-level and last folder name
        (string memory firstFolder,) = _getFolderName(contractMap.path);

        string[] memory json =
            _buildJsonArray(existingAddresses, string.concat(".", firstFolder, ".", contractName), transaction, receipt);

        // Copy all existing top-level groups
        vm.serializeJson("addresses", existingAddresses);

        // Update the specific group with the new contract data
        string memory updatedGroupJson = _updateGroupJson(existingAddresses, firstFolder, contractName, json);

        // Write the complete JSON with the updated group
        vm.writeJson(vm.serializeString("addresses", firstFolder, updatedGroupJson), ADDRESSES_PATH);
    }

    function _buildJsonArray(
        string memory existingAddresses,
        string memory key,
        Tx1559 memory transaction,
        Receipt memory receipt
    ) internal returns (string[] memory json) {
        if (vm.keyExistsJson(existingAddresses, key)) {
            // Append new data to existingAddresses
            bytes memory contractAddressesJson = vm.parseJson(existingAddresses, key);
            ContractDeploymentData[] memory existingContractAddresses =
                abi.decode(contractAddressesJson, (ContractDeploymentData[]));

            json = new string[](existingContractAddresses.length + 1);
            vm.serializeAddress("0", "address", transaction.contractAddress);
            vm.serializeUint("0", "blockNumber", receipt.blockNumber);
            json[0] = vm.serializeBytes32("0", "transactionHash", transaction.hash);

            for (uint256 i = 0; i < existingContractAddresses.length; i++) {
                ContractDeploymentData memory existingContractAddress = existingContractAddresses[i];
                string memory index = vm.toString(i + 1);

                vm.serializeAddress(index, "address", existingContractAddress.contractAddress);
                vm.serializeUint(index, "blockNumber", existingContractAddress.blockNumber);
                json[i + 1] = vm.serializeBytes32(index, "transactionHash", existingContractAddress.transactionHash);
            }
        } else {
            json = new string[](1);
            vm.serializeAddress("0", "address", transaction.contractAddress);
            vm.serializeUint("0", "blockNumber", receipt.blockNumber);
            json[0] = vm.serializeBytes32("0", "transactionHash", transaction.hash);
        }
    }

    // Helper to check if a path is or is under a 'utils' folder
    function _isExcludedPath(string memory path) internal pure returns (bool) {
        bytes memory pathBytes = bytes(path);
        bytes memory utilsBytes = bytes("/utils");
        for (uint256 i = 0; i + utilsBytes.length <= pathBytes.length; i++) {
            bool matchFound = true;
            for (uint256 j = 0; j < utilsBytes.length; j++) {
                if (pathBytes[i + j] != utilsBytes[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) {
                uint256 afterIdx = i + utilsBytes.length;
                if (afterIdx == pathBytes.length || pathBytes[afterIdx] == 0x2f) {
                    return true;
                }
            }
        }
        return false;
    }

    // Helper to get the last segment of a path (folder or file name)
    function _getLastPathSegment(string memory path) internal pure returns (string memory) {
        bytes memory pathBytes = bytes(path);
        uint256 lastSlash = 0;
        for (uint256 i = 0; i < pathBytes.length; i++) {
            if (pathBytes[i] == 0x2f) {
                // '/'
                lastSlash = i + 1;
            }
        }
        if (lastSlash >= pathBytes.length) return "";
        bytes memory segment = new bytes(pathBytes.length - lastSlash);
        for (uint256 i = 0; i < segment.length; i++) {
            segment[i] = pathBytes[lastSlash + i];
        }
        return string(segment);
    }

    function _recordContractsOnPath(string memory path) internal {
        // Exclude any path that is or is under a 'utils' folder
        if (_isExcludedPath(path)) {
            return;
        }
        VmSafe.DirEntry[] memory files = vm.readDir(path);
        bool isTopLevel = keccak256(bytes(path)) == keccak256(bytes(CONTRACT_PATH));
        for (uint256 i = 0; i < files.length; i++) {
            VmSafe.DirEntry memory file = files[i];
            // Exclude any file or directory under a 'utils' folder
            if (_isExcludedPath(file.path)) {
                continue;
            }
            if (file.isDir) {
                if (isTopLevel) {
                    string memory folderName = _getLastPathSegment(file.path);
                    // Only include specific top-level folders
                    if (keccak256(bytes(folderName)) != keccak256(bytes("hooks"))) {
                        continue;
                    }
                }
                _recordContractsOnPath(file.path);
            } else if (_endsWith(file.path, ".sol")) {
                string memory content = vm.readFile(file.path);
                if (_containsContractKeyword(content) && !_containsAbstractContractKeyword(content)) {
                    string memory contractName = _extractContractName(content);
                    contractNames.push(
                        ContractMap({id: startId++, path: string(abi.encodePacked(file.path)), name: contractName})
                    );
                }
            }
        }
    }

    function _extractContractName(string memory content) internal pure returns (string memory) {
        bytes memory contentBytes = bytes(content);
        bytes memory keyword = bytes("contract ");
        for (uint256 i = 0; i < contentBytes.length - keyword.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < keyword.length; j++) {
                if (contentBytes[i + j] != keyword[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                // Found "contract ", now extract the name
                uint256 start = i + keyword.length;
                uint256 end = start;
                while (
                    end < contentBytes.length
                        && (
                            (contentBytes[end] >= 0x30 && contentBytes[end] <= 0x39) // 0-9
                                || (contentBytes[end] >= 0x41 && contentBytes[end] <= 0x5A) // A-Z
                                || (contentBytes[end] >= 0x61 && contentBytes[end] <= 0x7A) // a-z
                                || (contentBytes[end] == 0x5F)
                        ) // _
                ) {
                    end++;
                }
                bytes memory nameBytes = new bytes(end - start);
                for (uint256 k = 0; k < end - start; k++) {
                    nameBytes[k] = contentBytes[start + k];
                }
                return string(nameBytes);
            }
        }
        return "";
    }

    function _containsContractKeyword(string memory content) internal pure returns (bool) {
        bytes memory contentBytes = bytes(content);
        bytes memory keyword = bytes("contract ");
        for (uint256 i = 0; i <= contentBytes.length - keyword.length; i++) {
            bool matchFound = true;
            for (uint256 j = 0; j < keyword.length; j++) {
                if (contentBytes[i + j] != keyword[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) {
                return true;
            }
        }
        return false;
    }

    function _containsAbstractContractKeyword(string memory content) internal pure returns (bool) {
        bytes memory contentBytes = bytes(content);
        bytes memory keyword = bytes("abstract contract ");
        for (uint256 i = 0; i <= contentBytes.length - keyword.length; i++) {
            bool matchFound = true;
            for (uint256 j = 0; j < keyword.length; j++) {
                if (contentBytes[i + j] != keyword[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) {
                return true;
            }
        }
        return false;
    }

    // Helper to check if a string ends with a suffix
    function _endsWith(string memory str, string memory suffix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory suffixBytes = bytes(suffix);
        if (suffixBytes.length > strBytes.length) return false;
        for (uint256 i = 0; i < suffixBytes.length; i++) {
            if (strBytes[strBytes.length - suffixBytes.length + i] != suffixBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function _getFolderName(string memory path)
        internal
        view
        returns (string memory firstFolderName, string memory lastFolderName)
    {
        bytes memory pathBytes = bytes(path);
        uint256 lastSlash = 0;
        uint256 prevSlash = 0;
        uint256 srcIndex = 0;
        bool foundSrc = false;
        // Find the index of '/src/' if present
        for (uint256 i = 0; i < pathBytes.length - 3; i++) {
            if (
                pathBytes[i] == 0x2f // '/'
                    && pathBytes[i + 1] == 0x73 // 's'
                    && pathBytes[i + 2] == 0x72 // 'r'
                    && pathBytes[i + 3] == 0x63 // 'c'
                    && (i + 4 == pathBytes.length || pathBytes[i + 4] == 0x2f) // '/' or end
            ) {
                srcIndex = i + 4; // index after '/src/'
                foundSrc = true;
                break;
            }
        }
        
        // For hooks subdirectories, use the subdirectory name as the category
        if (foundSrc) {
            // Look for "hooks/" after src
            uint256 hooksStart = srcIndex;
            while (hooksStart < pathBytes.length && pathBytes[hooksStart] == 0x2f) {
                hooksStart++;
            }
            
            // Check if path starts with "hooks/"
            bytes memory hooksBytes = bytes("hooks");
            bool isHooksPath = true;
            if (hooksStart + hooksBytes.length < pathBytes.length) {
                for (uint256 i = 0; i < hooksBytes.length; i++) {
                    if (pathBytes[hooksStart + i] != hooksBytes[i]) {
                        isHooksPath = false;
                        break;
                    }
                }
                // Check for trailing slash after "hooks"
                if (isHooksPath && pathBytes[hooksStart + hooksBytes.length] != 0x2f) {
                    isHooksPath = false;
                }
            } else {
                isHooksPath = false;
            }
            
            if (isHooksPath) {
                // Find the subdirectory after "hooks/"
                uint256 subStart = hooksStart + hooksBytes.length + 1; // +1 for the slash
                while (subStart < pathBytes.length && pathBytes[subStart] == 0x2f) {
                    subStart++;
                }
                uint256 subEnd = subStart;
                while (subEnd < pathBytes.length && pathBytes[subEnd] != 0x2f) {
                    subEnd++;
                }
                
                if (subEnd > subStart) {
                    bytes memory subFolderBytes = new bytes(subEnd - subStart);
                    for (uint256 i = 0; i < subEnd - subStart; i++) {
                        subFolderBytes[i] = pathBytes[subStart + i];
                    }
                    firstFolderName = string(subFolderBytes);
                } else {
                    firstFolderName = "hooks";
                }
            } else {
                // Find the first folder after src (or after root if no src)
                uint256 start = foundSrc ? srcIndex : 0;
                // skip leading slashes
                while (start < pathBytes.length && pathBytes[start] == 0x2f) {
                    start++;
                }
                uint256 end = start;
                while (end < pathBytes.length && pathBytes[end] != 0x2f) {
                    end++;
                }
                if (end > start) {
                    bytes memory firstFolderBytes = new bytes(end - start);
                    for (uint256 i = 0; i < end - start; i++) {
                        firstFolderBytes[i] = pathBytes[start + i];
                    }
                    firstFolderName = string(firstFolderBytes);
                } else {
                    firstFolderName = CONTRACT_PATH;
                }
            }
        } else {
            firstFolderName = CONTRACT_PATH;
        }
        
        // Now get the last folder as before
        for (uint256 i = 0; i < pathBytes.length; i++) {
            if (pathBytes[i] == "/") {
                prevSlash = lastSlash;
                lastSlash = i;
            }
        }
        if (lastSlash == 0) return (firstFolderName, CONTRACT_PATH);
        uint256 lastStart = prevSlash == 0 ? 0 : prevSlash + 1;
        uint256 lastLen = lastSlash - lastStart;
        if (lastLen == 0) return (firstFolderName, CONTRACT_PATH);
        bytes memory lastFolderBytes = new bytes(lastLen);
        for (uint256 i = 0; i < lastLen; i++) {
            lastFolderBytes[i] = pathBytes[lastStart + i];
        }
        lastFolderName = string(lastFolderBytes);
    }

    // modified from `vm.readTx1559s` to read directly from broadcast artifact
    struct RawBroadcastTx1559 {
        string[] additionalContracts;
        bytes arguments;
        address contractAddress;
        string contractName;
        string functionSig;
        bytes32 hash;
        bool isFixedGasLimit;
        RawBroadcastTx1559Detail transactionDetail;
        string transactionType;
    }

    struct RawBroadcastTx1559Detail {
        uint256 chainId;
        address from;
        uint256 gas;
        bytes input;
        uint256 nonce;
        uint256 value;
    }

    function _readTx1559s(string memory path) internal view virtual returns (Tx1559[] memory) {
        string memory deployData = vm.readFile(path);
        bytes memory parsedDeployData = vm.parseJson(deployData, ".transactions");
        RawBroadcastTx1559[] memory rawTxs = abi.decode(parsedDeployData, (RawBroadcastTx1559[]));
        return _rawToConvertedEIPTx1559s(rawTxs);
    }

    function _rawToConvertedEIPTx1559s(RawBroadcastTx1559[] memory rawTxs)
        internal
        pure
        virtual
        returns (Tx1559[] memory)
    {
        Tx1559[] memory txs = new Tx1559[](rawTxs.length);
        for (uint256 i; i < rawTxs.length; i++) {
            txs[i] = _rawToConvertedEIPTx1559(rawTxs[i]);
        }
        return txs;
    }

    function _rawToConvertedEIPTx1559(RawBroadcastTx1559 memory rawTx) internal pure virtual returns (Tx1559 memory) {
        Tx1559 memory transaction;
        transaction.contractName = rawTx.contractName;
        transaction.contractAddress = rawTx.contractAddress;
        transaction.functionSig = rawTx.functionSig;
        transaction.hash = rawTx.hash;
        transaction.txDetail = _rawToConvertedEIP1559Detail(rawTx.transactionDetail);
        return transaction;
    }

    function _rawToConvertedEIP1559Detail(RawBroadcastTx1559Detail memory rawDetail)
        internal
        pure
        virtual
        returns (Tx1559Detail memory)
    {
        Tx1559Detail memory txDetail;
        txDetail.from = rawDetail.from;
        txDetail.nonce = rawDetail.nonce;
        txDetail.value = rawDetail.value;
        txDetail.gas = rawDetail.gas;
        return txDetail;
    }

    // modified from `vm.readReceipts` to read directly from broadcast artifact
    struct RawBroadcastReceipt {
        bytes32 blockHash;
        bytes blockNumber;
        address contractAddress;
        bytes cumulativeGasUsed;
        bytes effectiveGasPrice;
        address from;
        bytes gasUsed;
        bytes l1BaseFeeScalar;
        bytes l1BlobBaseFee;
        bytes l1BlobBaseFeeScalar;
        bytes l1Fee;
        bytes l1GasPrice;
        bytes l1GasUsed;
        RawReceiptLog[] logs;
        bytes logsBloom;
        bytes status;
        address to;
        bytes32 transactionHash;
        bytes transactionIndex;
        bytes typeValue;
    }

    function _readReceipts(string memory path) internal view returns (Receipt[] memory) {
        string memory receiptData = vm.readFile(path);
        bytes memory parsedReceiptData = vm.parseJson(receiptData, ".receipts");
        RawBroadcastReceipt[] memory rawReceipts = abi.decode(parsedReceiptData, (RawBroadcastReceipt[]));
        return _rawToConvertedReceipts(rawReceipts);
    }

    function _rawToConvertedReceipts(RawBroadcastReceipt[] memory rawReceipts)
        internal
        pure
        virtual
        returns (Receipt[] memory)
    {
        Receipt[] memory receipts = new Receipt[](rawReceipts.length);
        for (uint256 i; i < rawReceipts.length; i++) {
            receipts[i] = _rawToConvertedReceipt(rawReceipts[i]);
        }
        return receipts;
    }

    function _rawToConvertedReceipt(RawBroadcastReceipt memory rawReceipt)
        internal
        pure
        virtual
        returns (Receipt memory)
    {
        Receipt memory receipt;
        receipt.blockHash = rawReceipt.blockHash;
        receipt.to = rawReceipt.to;
        receipt.from = rawReceipt.from;
        receipt.contractAddress = rawReceipt.contractAddress;
        receipt.effectiveGasPrice = __bytesToUint(rawReceipt.effectiveGasPrice);
        receipt.cumulativeGasUsed = __bytesToUint(rawReceipt.cumulativeGasUsed);
        receipt.gasUsed = __bytesToUint(rawReceipt.gasUsed);
        receipt.status = __bytesToUint(rawReceipt.status);
        receipt.transactionIndex = __bytesToUint(rawReceipt.transactionIndex);
        receipt.blockNumber = __bytesToUint(rawReceipt.blockNumber);
        receipt.logs = rawToConvertedReceiptLogs(rawReceipt.logs);
        receipt.logsBloom = rawReceipt.logsBloom;
        receipt.transactionHash = rawReceipt.transactionHash;
        return receipt;
    }

    function __bytesToUint(bytes memory b) private pure returns (uint256) {
        require(b.length <= 32, "StdCheats _bytesToUint(bytes): Bytes length exceeds 32.");
        return abi.decode(abi.encodePacked(new bytes(32 - b.length), b), (uint256));
    }
}
