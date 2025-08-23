# Onchain Actions

Execute custom logic when products are purchased on Slice.

## Available Actions

| Action | Description |
|--------|-------------|
| **[Allowlisted](./Allowlisted/)** | Restrict purchases to allowlisted addresses |
| **[ERC20Gated](./ERC20Gated/)** | Require ERC20 token ownership |
| **[ERC20Mint](./ERC20Mint/)** | Mint ERC20 tokens to buyers |
| **[ERC721AMint](./ERC721AMint/)** | Mint ERC721A NFTs to buyers |
| **[NFTGated](./NFTGated/)** | Require NFT ownership |

## Creating Custom Actions

### 1. Inherit Base Contract

```solidity
import {RegistryProductAction, IProductsModule} from "@/utils/RegistryProductAction.sol";

contract MyAction is RegistryProductAction {
    constructor(IProductsModule productsModule) 
        RegistryProductAction(productsModule) {}
}
```

### 2. Implement Core Functions

```solidity
// Check purchase eligibility
function isPurchaseAllowed(...) public view override returns (bool) {
    // Your logic
}

// Execute on purchase
function _onProductPurchase(...) internal override {
    // Your logic
}

// Configure product
function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) 
    internal override {
    // Store configuration
}

// Define parameters
function paramsSchema() external pure override returns (string memory) {
    return "uint256 param1,address param2";
}
```

## Testing

Inherit from `RegistryProductActionTest` for testing:

```solidity
import {RegistryProductActionTest} from "@test/utils/RegistryProductActionTest.sol";

contract MyActionTest is RegistryProductActionTest {
    // Your tests
}
```