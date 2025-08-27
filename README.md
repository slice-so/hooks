# ▼ Slice Hooks

Smart contracts for creating custom pricing strategies and onchain actions for [Slice](https://slice.so) products.

Hooks enable dynamic pricing, purchase restrictions, rewards, integration with external protocols and other custom behaviors when products are bought.

## Architecture

### Core Interfaces

Hooks are built around three main interfaces:

**IProductPrice** - Calculate dynamic prices for products:
```solidity
function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address buyer,
    bytes memory data
) external view returns (uint256 ethPrice, uint256 currencyPrice);
```

**IProductAction** - Execute custom logic during purchases (eligibility checks, rewards, etc.):
```solidity
function isPurchaseAllowed(...) external view returns (bool);
function onProductPurchase(...) external payable;
```

**IHookRegistry** - Enable reusable hooks across multiple products with frontend integration:
```solidity
function configureProduct(uint256 slicerId, uint256 productId, bytes memory params) external;
function paramsSchema() external pure returns (string memory);
```

### Product Purchase Lifecycle

Here's how hooks integrate into the product purchase flow:

```
   Checkout
       │
       ▼
┌─────────────────────┐
│   Price Fetching    │ ← `IProductPrice.productPrice`
│   (before purchase) │
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│  Purchase Execution │ ← `IProductAction.onProductPurchase`
│  (during purchase)  │
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│  Purchase Complete  │
└─────────────────────┘
```

**Pricing Strategies** are called during the price fetching phase to calculate price based on buyer and custom logic

**Onchain Actions** are executed during the purchase transaction to:
- Validate purchase eligibility
- Execute custom logic (gating, minting, rewards, etc.)

### Hook Types

#### Registry Hooks (Reusable)

Reusable contracts designed to support multiple products. Registries are automatically integrated with Slice clients.

- **[Actions](./src/hooks/actions/)**: See available onchain actions and implementation guide
- **[Pricing](./src/hooks/pricing/)**: See available pricing strategies and implementation guide  
- **[Pricing Actions](./src/hooks/pricingActions/)**: See combined pricing + action hooks

#### Product-Specific Hooks

Custom smart contracts tailored for individual products. These are integrated using the `custom` onchain action or pricing strategy in Slice.

- **[Examples](./src/examples/)**: See real-world implementations and creation guide

## Get Started

### Repository Structure

```
src/
├── hooks/              # Reusable hooks with registry support
│   ├── actions/        # Onchain actions (gating, rewards, etc.)
│   ├── pricing/        # Pricing strategies (NFT discounts, VRGDA, etc.)
│   └── pricingActions/ # Combined pricing + action hooks
├── examples/           # Product-specific reference implementations
├── interfaces/         # Core hook interfaces
└── utils/              # Base contracts and utilities
```

### Registry Hooks (Reusable)
Deploy once, configure for multiple products via Slice frontend.

📁 **[Actions](./src/hooks/actions/)** - Purchase restrictions and onchain effects  
   • Allowlisting, token gating, NFT minting, rewards

📁 **[Pricing](./src/hooks/pricing/)** - Dynamic pricing strategies  
   • VRGDA curves, tiered discounts, conditional pricing

📁 **[Combined](./src/hooks/pricingActions/)** - Pricing + actions in one contract  
   • Complex behaviors like "first purchase free"

### Product-Specific Hooks
Custom implementations for individual products.

📁 **[Examples](./src/examples/)** - Reference implementations  
   • Real-world patterns and starting templates

## Base Contracts

Located in `src/utils/`, these provide essential building blocks:

**Registry bases** (for reusable hooks):
- `RegistryProductAction` - Reusable onchain actions
- `RegistryProductPrice` - Reusable pricing strategies  
- `RegistryProductPriceAction` - Combined pricing + actions

**Product-specific bases** (for custom hooks):
- `ProductAction` - Single-product actions
- `ProductPrice` - Single-product pricing
- `ProductPriceAction` - Single-product combined

## Development

### Setup

```bash
forge soldeer install   # Install dependencies
forge build             # Compile contracts
forge test              # Run test suite
```

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).

### Deployment

```bash
./script/deploy.sh      # Interactive deployment script
```

The script presents available contracts and guides through deployment.

### Testing

Inherit from the appropriate test base:
- `RegistryProductActionTest` - Test registry actions
- `RegistryProductPriceTest` - Test registry pricing
- `RegistryProductPriceActionTest` - Test combined registry hooks
- `ProductActionTest` - Test product-specific actions
- `ProductPriceTest` - Test product-specific pricing
- `ProductPriceActionTest` - Test combined product hooks

## Contributing

1. **Choose hook type** - Registry (reusable) or product-specific
2. **Inherit base contract** - Use appropriate base from `src/utils/`
3. **Implement interfaces** - Follow patterns in existing hooks
4. **Write comprehensive tests** - Use test base contracts
5. **Document your hook** - Explain purpose, parameters, and usage
6. **Submit PR** - Include tests and documentation

## Resources

- [Slice Documentation](https://docs.slice.so)
- [Hook Integration Guide](https://docs.slice.so/hooks)
- [Example Implementations](./src/examples/)