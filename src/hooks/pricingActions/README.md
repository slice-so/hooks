# Pricing + Actions

Combine dynamic pricing with onchain actions in a single contract.

## Available Hooks

| Hook | Description |
|------|-------------|
| **[FirstForFree](./FirstForFree/)** | First purchase free based on conditions |

## Creating Combined Hooks

### 1. Inherit Base Contract

```solidity
import {RegistryProductPriceAction, IProductsModule} from "@/utils/RegistryProductPriceAction.sol";

contract MyHook is RegistryProductPriceAction {
    constructor(IProductsModule productsModule) 
        RegistryProductPriceAction(productsModule) {}
}
```

### 2. Implement All Functions

```solidity
// Pricing logic
function productPrice(...) public view override 
    returns (uint256 ethPrice, uint256 currencyPrice) {
    // Calculate price
}

// Purchase eligibility
function isPurchaseAllowed(...) public view override returns (bool) {
    // Check eligibility
}

// Purchase action
function _onProductPurchase(...) internal override {
    // Execute action
}

// Configuration
function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) 
    internal override {
    // Store config
}

// Parameters
function paramsSchema() external pure override returns (string memory) {
    return "uint256 discount,address token";
}
```

## Testing

Inherit from `RegistryProductPriceActionTest` for testing:

```solidity
import {RegistryProductPriceActionTest} from "@test/utils/RegistryProductPriceActionTest.sol";

contract MyHookTest is RegistryProductPriceActionTest {
    // Your tests
}
```