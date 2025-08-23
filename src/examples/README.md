# Product-Specific Examples

Reference implementations for custom product hooks without registry support.

## Available Examples

| Example | Type | Description |
|---------|------|-------------|
| **[BaseCafe_2](./actions/BaseCafe_2.sol)** | Action | Mints NFT on every purchase |
| **[BaseGirlsScout](./actions/BaseGirlsScout.sol)** | Action | Mints Base Girls Scout NFTs |

## Key Differences from Registry Hooks

| Registry Hooks | Product-Specific |
|----------------|------------------|
| ✓ Reusable across products | ✗ Single product only |
| ✓ Frontend auto-integration | ✗ Manual integration |
| ✓ Parameter validation | ✗ Hardcoded config |
| ✗ More complex | ✓ Simpler setup |

## Creating Product-Specific Hooks

### Action Example

```solidity
import {ProductAction, IProductsModule} from "@/utils/ProductAction.sol";

contract MyProductAction is ProductAction {
    constructor(IProductsModule productsModule, uint256 slicerId)
        ProductAction(productsModule, slicerId) {}
    
    function _onProductPurchase(...) internal override {
        // Custom logic - mint NFTs, track purchases, etc.
    }
}
```

### Pricing Example

```solidity
import {ProductPrice, IProductsModule} from "@/utils/ProductPrice.sol";

contract MyProductPrice is ProductPrice {
    constructor(IProductsModule productsModule, uint256 slicerId)
        ProductPrice(productsModule, slicerId) {}
    
    function productPrice(...) public view override 
        returns (uint256 ethPrice, uint256 currencyPrice) {
        // Custom pricing logic
    }
}
```

## When to Use

Choose product-specific hooks when:
- Building for a single product
- Need maximum customization
- Don't require frontend auto-integration
- Want simpler deployment