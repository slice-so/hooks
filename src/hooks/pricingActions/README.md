# Pricing Strategy Actions

Pricing strategy actions combine both pricing strategies and onchain actions in a single contract. They implement both `IPricingStrategy` and `IOnchainAction` interfaces, allowing them to calculate dynamic prices AND execute custom logic during purchases.

## Key Interfaces

**IPricingStrategy**:
```solidity
interface IPricingStrategy {
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

**IOnchainAction**:
```solidity
interface IOnchainAction {
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external view returns (bool);

    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external payable;
}
```

## Base Contract: RegistryPricingStrategyAction

All pricing strategy actions inherit from `RegistryPricingStrategyAction`, which provides:
- Combined functionality of both pricing strategies and onchain actions
- Registry functionality for reusable hooks across multiple products
- Implementation of `IHookRegistry` for Slice frontend integration

## Available Pricing Strategy Actions

- **[FirstForFree](./FirstForFree/FirstForFree.sol)**: Discounts the first purchase of a product for free, based on conditions.

## Creating Custom Pricing Strategy Actions

To create a custom pricing strategy action:

1. **Inherit from RegistryPricingStrategyAction**:
```solidity
import {RegistryPricingStrategyAction, IProductsModule} from "@/utils/RegistryPricingStrategyAction.sol";

contract MyPricingStrategyAction is RegistryPricingStrategyAction {
    constructor(IProductsModule productsModule) 
        RegistryPricingStrategyAction(productsModule) {}
}
```

2. **Implement required functions**:
```solidity
function productPrice(...) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
    // Your pricing logic here
}

function isPurchaseAllowed(...) public view override returns (bool) {
    // Your eligibility logic here
}

function _onProductPurchase(...) internal override {
    // Custom logic to execute on purchase
}

function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) 
    internal override {
    // Handle product configuration
}

function paramsSchema() external pure override returns (string memory) {
    return "uint256 param1,address param2"; // Your parameter schema
}
```

## Integration with Slice

Pricing strategy actions that inherit from `RegistryPricingStrategyAction` are automatically compatible with Slice frontends through the `IHookRegistry` interface, enabling:
- Product configuration via `configureProduct()`
- Parameter validation via `paramsSchema()`
- Automatic discovery and integration