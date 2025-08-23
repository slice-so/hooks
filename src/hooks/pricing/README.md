# Pricing Strategies

Pricing strategies are smart contracts that calculate dynamic prices for products on Slice. They implement the `IProductPrice` interface to provide custom pricing logic based on arbitrary factors and conditions.

## Key Interface: IProductPrice

```solidity
interface IProductPrice {
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data
    ) external view returns (uint256 ethPrice, uint256 currencyPrice);
}
```

## Base Contract: RegistryProductPrice

All pricing strategies in this directory inherit from `RegistryProductPrice`, which provides:
- Registry functionality for reusable pricing across multiple products
- Implementation of `IHookRegistry` for Slice frontend integration
- Base implementations for common patterns

## Available Strategies

- **[TieredDiscount](./TieredDiscount/TieredDiscount.sol)**: Tiered discounts based on asset ownership
- **[LinearVRGDAPrices](./VRGDA/LinearVRGDAPrices/LinearVRGDAPrices.sol)**: VRGDA with a linear issuance curve - Price library with different params for each Slice product
- **[LogisticVRGDAPrices](./VRGDA/LogisticVRGDAPrices/LogisticVRGDAPrices.sol)**: VRGDA with a logistic issuance curve - Price library with different params for each Slice product
- **[VRGDAPrices](./VRGDA/VRGDAPrices.sol)**: Variable Rate Gradual Dutch Auction

## Creating Custom Pricing Strategies

To create a custom pricing strategy:

1. **Inherit from RegistryProductPrice**:
```solidity
import {RegistryProductPrice, IProductsModule} from "@/utils/RegistryProductPrice.sol";

contract MyProductPrice is RegistryProductPrice {
    constructor(IProductsModule productsModule) 
        RegistryProductPrice(productsModule) {}
}
```

2. **Implement required functions**:
```solidity
function productPrice(...) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
    // Your pricing logic here
}

function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) 
    internal override {
    // Handle product configuration
}

function paramsSchema() external pure override returns (string memory) {
    return "uint256 basePrice,uint256 multiplier"; // Your parameter schema
}
```

## Integration with Slice

Pricing strategies that inherit from `RegistryProductPrice` are automatically compatible with Slice frontends through the `IHookRegistry` interface, enabling:
- Product configuration via `configureProduct()`
- Parameter validation via `paramsSchema()`
- Automatic discovery and integration