# Product-Specific Custom Hooks

Custom product hooks tailored for individual products without registry support.

## When to Use

Choose product-specific hooks when:
- Building for a single product
- Don't want others to use the same hook for their products
- Don't require client integration
- Need immediate deployment

## Key Differences from Registry Hooks

| Registry Hooks | Product-Specific |
|----------------|------------------|
| ✓ Reusable across products | ✗ Single product only |
| ✓ Frontend auto-integration | ✗ Manual integration |
| ✓ Parameter validation | ✗ Hardcoded config |
| ✗ More complex | ✓ Simpler setup |

## Creating Product-Specific Hooks

### Quick Start with Generator Script

The easiest way to create a new product-specific hook is using the hook generator:

```bash
# From the hooks directory
./script/generate-hook.sh
```

Select:
1. Product-specific
2. The desired hook type (Action, Pricing, PricingAction)
3. Enter your contract name
4. Enter author name (optional)

### Action Example

```solidity
import {ProductAction, IProductsModule, IProductAction} from "@/utils/ProductAction.sol";

contract MyProductAction is ProductAction {
    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress, uint256 slicerId)
        ProductAction(productsModuleAddress, slicerId)
    {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductAction
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) public view override returns (bool) {
        // Your eligibility logic. Return true if eligible, false otherwise.
        return true;
    }

    /**
     * @inheritdoc ProductAction
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) internal override {
        // Your logic to be executed after product purchase.
    }
}
```

### Pricing Example

```solidity
import {ProductPrice, IProductsModule, IProductPrice} from "@/utils/ProductPrice.sol";

contract MyProductPrice is ProductPrice {
    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress, uint256 slicerId)
        ProductPrice(productsModuleAddress)
    {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductPrice
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data
    ) external view returns (uint256 ethPrice, uint256 currencyPrice) {
        // Your pricing logic. Calculate and return the total price.
    }
}
```
