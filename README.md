# ▼ Slice Hooks

Smart contracts for creating custom pricing strategies and onchain actions for [Slice](https://slice.so) products. 

Hooks enable dynamic pricing, purchase restrictions, rewards, integration with external protocols and other custom behaviors when products are bought.

## Repository Structure

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

## Core Concepts

Hooks are built around three main interfaces:

- **[`IOnchainAction`](./src/interfaces/IOnchainAction.sol)**: Execute custom logic during purchases (eligibility checks, rewards, etc.)
- **[`IPricingStrategy`](./src/interfaces/IPricingStrategy.sol)**: Calculate dynamic prices for products
- **[`IHookRegistry`](./src/interfaces/IHookRegistry.sol)**: Enable reusable hooks across multiple products with frontend integration

Hooks can be:

- **Product-specific**: Custom smart contracts tailored for individual products. These are integrated using the `custom` onchain action or pricing strategy in Slice.
- **Registry hooks**: Reusable contracts designed to support multiple products. Registries enable automatic integration with Slice clients.

See [Hook types](#hook-types) for more details.

## Product Purchase Lifecycle

Here's how hooks integrate into the product purchase flow:

```
  Checkout
       │
       ▼
┌─────────────────────┐
│   Price Fetching    │ ← `productPrice` called here
│   (before purchase) │   (IPricingStrategy)
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│  Purchase Execution │ ← `onProductPurchase` called here
│  (during purchase)  │   (IOnchainAction)
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

## Hook Types

### Registry Hooks (Reusable)

Deploy once, use across multiple products with frontend integration:

- **[Actions](./src/hooks/actions/)**: See available onchain actions and implementation guide
- **[Pricing](./src/hooks/pricing/)**: See available pricing strategies and implementation guide  
- **[Pricing Actions](./src/hooks/pricingActions/)**: See combined pricing + action hooks

### Product-Specific Hooks

Tailored implementations for individual products:

- **[Examples](./src/examples/)**: See real-world implementations and creation guide

## Base Contracts

The base contracts in `src/utils` are designed to be inherited, providing essential building blocks for developing custom Slice hooks efficiently.

###  Registry (Reusable):

- **`RegistryOnchainAction`**: Base for reusable onchain actions
- **`RegistryPricingStrategy`**: Base for reusable pricing strategies  
- **`RegistryPricingStrategyAction`**: Base for reusable pricing + action hooks

### Product-Specific

- **`OnchainAction`**: Base for product-specific onchain actions
- **`PricingStrategy`**: Base for product-specific pricing strategies
- **`PricingStrategyAction`**: Base for product-specific pricing + action hooks

## Quick Start

- **For reusable actions**: See detailed guides in [`/src/hooks/actions`](./src/hooks/actions)
- **For reusable pricing strategies**: See detailed guides in [`/src/hooks/pricing`](./src/hooks/pricing)
- **For reusable pricing strategy actions**: See detailed guides in [`/src/hooks/pricingActions`](./src/hooks/pricingActions)
- **For product-specific hooks**: See implementation examples in [`/src/examples/`](./src/examples/)

## Development

```bash
forge soldeer install       # Install dependencies
forge test                  # Run tests
forge build                 # Build
```

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).

### Deployment

To deploy hooks, use the deployment script:

```bash
./script/deploy.sh
```

The script will present you with a list of available contracts to deploy. Select the contract you want to deploy and follow the prompts.

### Testing

When writing tests for your hooks, inherit from the appropriate base test contract:

- **`RegistryOnchainActionTest`**: For testing `RegistryOnchainAction` contracts
- **`RegistryPricingStrategyTest`**: For testing `RegistryPricingStrategy` contracts
- **`RegistryPricingStrategyActionTest`**: For testing `RegistryPricingStrategyAction` contracts
- **`OnchainActionTest`**: For testing `OnchainAction` contracts
- **`PricingStrategyTest`**: For testing `PricingStrategy` contracts
- **`PricingStrategyActionTest`**: For testing `PricingStrategyAction` contracts

Inheriting the appropriate test contract for your hook allows you to focus your tests solely on your custom hook logic.

## Contributing

To contribute a new hook to this repository:

1. **Choose the appropriate hook type** based on your needs (registry vs product-specific)
2. **Implement your hook** following the existing patterns in the codebase
3. **Write comprehensive tests** using the appropriate test base contract
4. **Add documentation** explaining your hook's purpose and usage
5. **Submit a pull request** against this repository

Make sure your contribution follows the existing code style and includes proper documentation.