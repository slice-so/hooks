# ▼ Slice Hooks

Smart contracts for creating custom pricing strategies and onchain actions for [Slice](https://slice.so) products.

Hooks enable dynamic pricing, purchase restrictions, rewards, integration with external protocols and other custom behaviors when products are bought.

**[Contribute](#contributing)** by building new hooks and have them automatically integrated across all Slice stores and clients.

## Architecture

### Product Purchase Lifecycle

Here's how hooks integrate into the product purchase flow:

```
   Checkout
       │
       ▼
┌─────────────────────┐
│  Price Fetching     │ ← `IProductPrice.productPrice()`
│  (before purchase)  │
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│  Purchase Execution │ ← `IProductAction.onProductPurchase()`
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
function isPurchaseAllowed(
   uint256 slicerId,
   uint256 productId,
   address buyer,
   uint256 quantity,
   bytes memory slicerCustomData,
   bytes memory buyerCustomData
) external view returns (bool);

function onProductPurchase(
   uint256 slicerId,
   uint256 productId,
   address buyer,
   uint256 quantity,
   bytes memory slicerCustomData,
   bytes memory buyerCustomData
) external payable;
```

**IHookRegistry** - Enable reusable hooks across multiple products with frontend integration:
```solidity
function configureProduct(uint256 slicerId, uint256 productId, bytes memory params) external;
function paramsSchema() external pure returns (string memory);
```

### Hook Types

#### Registry Hooks (Reusable)

Reusable contracts designed to support multiple products, automatically integrated with Slice clients.

- **[Actions](./src/hooks/actions/)** - Purchase restrictions and onchain effects
- **[Pricing](./src/hooks/pricing/)** - Dynamic pricing strategies  
- **[PricingActions](./src/hooks/pricingActions/)** - Pricing + actions in one contract

#### Product-Specific Hooks

Custom smart contracts tailored for individual products, integrated using the `custom` onchain action or pricing strategy in Slice.

- **[Custom](./src/custom/)**: Product-specific implementations

All hooks inherit from base contracts in `src/utils/`.

## Contributing

### Quick Start

```bash
forge soldeer install   # Install dependencies
forge build             # Compile contracts
forge test              # Run test suite
```

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).

Deploy by running `./script/deploy.sh` and following instructions

### Building a Hook

The quickest way to create a new hook is using the interactive generator:

```bash
./script/generate-hook.sh
```

This will guide you through:
1. Choosing hook scope (Registry or Product-specific)
2. Selecting hook type (Action, Pricing Strategy, or Pricing Action)
3. Naming your contract
4. Setting authorship (optional)

The script automatically:
- Creates the contract file with appropriate template
- Adds imports to aggregator contracts (for registry hooks)
- Generates test files with proper structure (for registry hooks)

Once the hook is generated, add your custom contract logic to the and write tests for it.

For more detailed information, follow the appropriate guide for your hook type:
- [Actions](./src/hooks/actions/README.md)
- [Pricing](./src/hooks/pricing/README.md)
- [PricingActions](./src/hooks/pricingActions/README.md)

### Repository Structure

```
src/
├── hooks/              # Reusable hooks with registry support
│   ├── actions/        # Onchain actions (gating, rewards, etc.)
│   ├── pricing/        # Pricing strategies (NFT discounts, VRGDA, etc.)
│   └── pricingActions/ # Combined pricing + action hooks
├── custom/             # Product-specific custom hooks
├── interfaces/         # Core hook interfaces
└── utils/              # Base contracts and utilities
```

### Resources

- [Actions Guide](./src/hooks/actions/README.md)
- [Pricing Strategies Guide](./src/hooks/pricing/README.md)
- [Pricing + Actions Guide](./src/hooks/pricingActions/README.md)
- [Custom Implementations](./src/custom/README.md)