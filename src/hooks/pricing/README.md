# Pricing Strategies

Calculate dynamic prices for products on Slice.

## Available Strategies

| Strategy | Description |
|----------|-------------|
| **[TieredDiscount](./TieredDiscount/)** | Tiered discounts based on asset ownership |
| **[LinearVRGDAPrices](./VRGDA/LinearVRGDAPrices/)** | Linear VRGDA curve |
| **[LogisticVRGDAPrices](./VRGDA/LogisticVRGDAPrices/)** | Logistic VRGDA curve |

## Creating Custom Pricing

### 1. Inherit Base Contract

```solidity
import {RegistryProductPrice, IProductsModule} from "@/utils/RegistryProductPrice.sol";

contract MyPricing is RegistryProductPrice {
    constructor(IProductsModule productsModule) 
        RegistryProductPrice(productsModule) {}
}
```

### 2. Implement Core Functions

```solidity
// Calculate price
function productPrice(...) public view override 
    returns (uint256 ethPrice, uint256 currencyPrice) {
    // Your pricing logic
}

// Configure product
function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) 
    internal override {
    // Store configuration
}

// Define parameters
function paramsSchema() external pure override returns (string memory) {
    return "uint256 basePrice,uint256 multiplier";
}
```

## Testing

Inherit from `RegistryProductPriceTest` for testing:

```solidity
import {RegistryProductPriceTest} from "@test/utils/RegistryProductPriceTest.sol";

contract MyPricingTest is RegistryProductPriceTest {
    // Your tests
}
```