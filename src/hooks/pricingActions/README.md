# Pricing + Actions

Combine dynamic pricing with onchain actions in a single contract. These hooks implement both `IProductPrice` and `IProductAction` interfaces.

Pricing Actions are useful when:
- You want a single contract to handle both pricing and action logic
- The price logic is related to the action logic (for example, [FirstForFree](./FirstForFree/FirstForFree.sol) allows for the first item to be free for each buyer, and all future ones to be paid at a base price)

## How Combined Hooks Work

Pricing actions are called at multiple points:
1. **`productPrice`** - Calculate dynamic price before purchase
2. **`isPurchaseAllowed`** - Check eligibility before payment
3. **`onProductPurchase`** - Execute custom logic after payment

## Creating Combined Hooks

### Quick Start with Generator Script

The easiest way to create a new pricing action is using the hook generator:

```bash
# From the hooks directory
./script/generate-hook.sh
```

Select:
1. Registry (for Slice-integrated hooks)
2. Pricing Action
3. Enter your contract name
4. Enter author name (optional)

The script will create your contract file with the proper template and add it to the aggregator.

### Registry Integration

Hooks inheriting from `RegistryProductPriceAction` automatically support frontend integration through:
- **Product configuration** via `configureProduct()`
- **Parameter validation** via `paramsSchema()`

### Testing

The generator script will also create a test file for your pricing action. Customize it to your needs to test both pricing and action logic.
