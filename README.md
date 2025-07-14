# Slice Hooks

Smart contracts for creating custom pricing strategies and onchain actions for [Slice](https://slice.so) products. Hooks enable dynamic pricing, purchase restrictions, rewards, and other custom behaviors when products are bought.

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

Slice hooks are built around three main interfaces:

- **[`IOnchainAction`](./src/interfaces/IOnchainAction.sol)**: Execute custom logic during purchases (eligibility checks, rewards, etc.)
- **[`IPricingStrategy`](./src/interfaces/IPricingStrategy.sol)**: Calculate dynamic prices for products
- **[`IHookRegistry`](./src/interfaces/IHookRegistry.sol)**: Enable reusable hooks across multiple products with frontend integration

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

###  Registry (Reusable):

- **`RegistryOnchainAction`**: Base for reusable onchain actions
- **`RegistryPricingStrategy`**: Base for reusable pricing strategies  
- **`RegistryPricingStrategyAction`**: Base for combined pricing + action hooks

### Product-Specific

- **`OnchainAction`**: Base for simple onchain actions
- **`PricingStrategy`**: Base for simple pricing strategies
- **`PricingStrategyAction`**: Base for combined hooks

## Quick Start

**For reusable actions**: See detailed guides in [`/src/hooks/actions`](./src/hooks/actions)
**For reusable pricing strategies**: See detailed guides in [`/src/hooks/pricing`](./src/hooks/pricing)
**For reusable pricing strategy actions**: See detailed guides in [`/src/hooks/pricingActions`](./src/hooks/pricingActions)
**For product-specific hooks**: See implementation examples in [`/src/examples/`](./src/examples/)

## Development

```bash
forge soldeer install       # Install dependencies
forge test                  # Run tests
forge build                 # Build
```

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).

## Integration

Registry hooks automatically integrate with Slice frontends through the `IHookRegistry` interface.

Product-specific can be attached via the `custom` pricing strategy / onchain action, by passing the deployment address.