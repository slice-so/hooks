# Onchain Actions

Execute custom logic when products are purchased on Slice. Actions implement the `IProductAction` interface to control purchase eligibility and perform operations during transactions.

## Available Actions

| Action | Description | Key Features |
|--------|-------------|--------------|
| **[Allowlisted](./Allowlisted/)** | Restrict purchases to allowlisted addresses | Merkle tree verification, gas-efficient |
| **[ERC20Gated](./ERC20Gated/)** | Require ERC20 token ownership | Minimum balance checks |
| **[ERC20Mint](./ERC20Mint/)** | Mint ERC20 tokens to buyers | Configurable amounts per purchase |
| **[ERC721AMint](./ERC721AMint/)** | Mint ERC721A NFTs efficiently | Gas-optimized batch minting |
| **[NFTGated](./NFTGated/)** | Require NFT ownership | ERC721/1155 support |

## How Actions Work

Actions are called at two points during purchase:

1. **`isPurchaseAllowed`** - Before payment, checks if buyer can purchase
2. **`onProductPurchase`** - After payment, executes custom logic

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
// Check if purchase is allowed (called before payment)
function isPurchaseAllowed(
    uint256 slicerId,
    uint256 productId,
    address account,
    uint256 quantity,
    bytes memory slicerCustomData,
    bytes memory buyerCustomData
) public view override returns (bool) {
    // Your eligibility logic
    // Example: check NFT ownership, allowlist, etc.
    return isEligible;
}

// Execute action (called after payment)
function _onProductPurchase(
    uint256 slicerId,
    uint256 productId,
    address account,
    uint256 quantity,
    bytes memory slicerCustomData,
    bytes memory buyerCustomData
) internal override {
    // Your action logic
    // Example: mint NFTs, distribute rewards, update state
}

// Configure product (called when setting up)
function _configureProduct(
    uint256 slicerId,
    uint256 productId,
    bytes memory params
) internal override {
    // Decode and store configuration
    // This enables reusability across products
}

// Define configuration parameters
function paramsSchema() external pure override returns (string memory) {
    // Schema for frontend integration
    return "address token,uint256 amount";
}
```

## Registry Integration

Actions inheriting from `RegistryProductAction` automatically support:
- **Product configuration** via `configureProduct()`
- **Parameter validation** via `paramsSchema()`
- **Frontend discovery** through `IHookRegistry`

## Testing

```solidity
import {RegistryProductActionTest} from "@test/utils/RegistryProductActionTest.sol";

contract MyActionTest is RegistryProductActionTest {
    function setUp() public override {
        super.setUp();
        // Your setup
    }
    
    function test_myAction() public {
        // Your tests
    }
}
```

## Best Practices

- Keep `isPurchaseAllowed` gas-efficient (it's a view function)
- Validate all inputs in `_onProductPurchase`
- Use `slicerCustomData` for seller configuration
- Use `buyerCustomData` for buyer-specific parameters
- Emit events for important state changes
- Consider reentrancy protection if interacting with external contracts