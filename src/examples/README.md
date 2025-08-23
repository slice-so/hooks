# Example Implementations

This folder contains product-specific smart contract implementations that demonstrate how to use Slice hooks for real-world use cases. These examples can be used as templates for creating your own custom implementations, without focusing on reusability and integration with Slice.

## Key Interfaces

**IProductPrice**:
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

**IProductAction**:
```solidity
interface IProductAction {
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

## Base Contracts

- **ProductAction**: Add arbitrary requirements and/or custom logic after product purchase.
- **ProductPrice**: Customize product pricing logic.
- **ProductPriceAction**: Provide functionality of both Onchain Actions and Pricing Strategies

## Key Differences from Registry Hooks

Unlike the reusable hooks in `/hooks/`, these examples:
- Are tailored for specific products/projects
- Inherit directly from base contracts (`ProductAction`, `ProductPrice`)
- Don't implement `IHookRegistry` (not intended for Slice frontend integration)
- Serve as reference implementations and starting points

## Available Examples

### Actions

- **[BaseCafe_2](./actions/BaseCafe_2.sol)**: Onchain action that mints an NFT to the buyer on every purchase.
- **[BaseGirlsScout](./actions/BaseGirlsScout.sol)**: Onchain action that mints Base Girls Scout NFTs to the buyer on every purchase.

## Creating Custom Product-Specific Hooks

### Onchain Action

To create a custom product-specific onchain action:

1. **Inherit from ProductAction**:
```solidity
import {ProductAction, IProductsModule} from "@/utils/ProductAction.sol";

contract MyProductAction is ProductAction {
    constructor(IProductsModule productsModule, uint256 slicerId)
        ProductAction(productsModule, slicerId) {}
}
```

2. **Implement required functions**:
```solidity
function _onProductPurchase(
    uint256 slicerId,
    uint256 productId,
    address account,
    uint256 quantity,
    bytes memory slicerCustomData,
    bytes memory buyerCustomData
) internal override {
    // Your custom logic here - mint NFTs, track purchases, etc.
}

// Optional: Add purchase restrictions
function isPurchaseAllowed(
    uint256 slicerId,
    uint256 productId,
    address account,
    uint256 quantity,
    bytes memory slicerCustomData,
    bytes memory buyerCustomData
) public view override returns (bool) {
    // Your eligibility logic here
}
```

### Pricing Strategy

To create a custom product-specific pricing strategy:

1. **Inherit from ProductPrice**:
```solidity
import {ProductPrice, IProductsModule} from "@/utils/ProductPrice.sol";

contract MyProductAction is ProductPrice {
    constructor(IProductsModule productsModule, uint256 slicerId)
        ProductPrice(productsModule, slicerId) {}
}
```

2. **Implement required functions**:
```solidity
function productPrice(...) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
    // Your pricing logic here
}
```

## Using These Examples

These examples show common patterns for:
- Product-specific NFT minting
- Integration with external contracts
- Onchain rewards

Copy and modify these examples to create your own product-specific implementations.