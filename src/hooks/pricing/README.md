# Pricing Strategies

Calculate dynamic prices for products on Slice. Pricing strategies implement the `IProductPrice` interface to provide custom pricing logic based on various factors.

## Available Strategies

| Strategy | Description | Use Cases |
|----------|-------------|-----------|
| **[TieredDiscount](./TieredDiscount/)** | Tiered discounts based on asset ownership | NFT holder discounts, token-based tiers |
| **[LinearVRGDAPrices](./VRGDA/LinearVRGDAPrices/)** | Linear VRGDA curve | Steady price increases over time |
| **[LogisticVRGDAPrices](./VRGDA/LogisticVRGDAPrices/)** | Logistic VRGDA curve | S-curve pricing, slow start/end |

### VRGDA (Variable Rate Gradual Dutch Auction)

VRGDA dynamically adjusts prices to maintain a target sales rate:
- Price increases when sales exceed target rate
- Price decreases when sales lag behind target
- Helps achieve predictable revenue over time

## How Pricing Works

The `productPrice` function is called before purchase to determine:
- **ETH price** - Price in native currency
- **Currency price** - Price in ERC20 tokens (if applicable)

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
// Calculate product price
function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address buyer,
    bytes memory data
) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
    // Your pricing logic
    // Can factor in:
    // - Buyer's token/NFT holdings
    // - Time since launch
    // - Total sales volume
    // - Custom parameters
    
    uint256 basePrice = getBasePrice(slicerId, productId);
    uint256 discount = calculateDiscount(buyer);
    
    ethPrice = (basePrice * quantity * (100 - discount)) / 100;
    currencyPrice = 0; // Or calculate if accepting ERC20
}

// Configure product pricing
function _configureProduct(
    uint256 slicerId,
    uint256 productId,
    bytes memory params
) internal override {
    // Decode and store pricing parameters
    (uint256 basePrice, uint256 discountRate) = abi.decode(params, (uint256, uint256));
    // Store configuration for this product
}

// Define configuration schema
function paramsSchema() external pure override returns (string memory) {
    // Schema for frontend integration
    return "uint256 basePrice,uint256 discountRate";
}
```

## Advanced Patterns

### Time-Based Pricing
```solidity
uint256 elapsed = block.timestamp - launchTime;
uint256 price = basePrice * (100 + elapsed / 1 days) / 100;
```

### Volume Discounts
```solidity
if (quantity >= 10) price = basePrice * 90 / 100;  // 10% off
if (quantity >= 50) price = basePrice * 80 / 100;  // 20% off
```

### NFT Holder Pricing
```solidity
if (IERC721(nftContract).balanceOf(buyer) > 0) {
    price = basePrice * 50 / 100;  // 50% discount
}
```

## Registry Integration

Strategies inheriting from `RegistryProductPrice` automatically support:
- **Product configuration** via `configureProduct()`
- **Parameter validation** via `paramsSchema()`
- **Frontend discovery** through `IHookRegistry`

## Testing

```solidity
import {RegistryProductPriceTest} from "@test/utils/RegistryProductPriceTest.sol";

contract MyPricingTest is RegistryProductPriceTest {
    function setUp() public override {
        super.setUp();
        // Your setup
    }
    
    function test_pricing() public {
        // Test different pricing scenarios
    }
}
```

## Best Practices

- Keep calculations gas-efficient (view function)
- Consider overflow/underflow protection
- Test edge cases (quantity = 0, max uint256)
- Document pricing algorithm clearly
- Emit events if storing state (in configure)
- Consider price stability mechanisms