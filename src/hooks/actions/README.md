# Onchain Actions

Execute custom logic when products are purchased on Slice. Actions implement the `IProductAction` interface to control purchase eligibility and perform operations during transactions.

## How Actions Work

Actions are called at two points during purchase:

1. **`isPurchaseAllowed`** - Before payment, checks if buyer can purchase
2. **`onProductPurchase`** - After payment, executes custom logic

## Creating Custom Actions

### Quick Start with Generator Script

The easiest way to create a new action is using the hook generator:

```bash
# From the hooks directory
./script/generate-hook.sh
```

Select:
1. Registry (for Slice-integrated hooks)
2. Onchain Action
3. Enter your contract name
4. Enter author name (optional)

The script will create your contract file with the proper template and add it to the aggregator.

### Registry Integration

Actions inheriting from `RegistryProductAction` automatically support frontend integration through:
- **Product configuration** via `configureProduct()`
- **Parameter validation** via `paramsSchema()`

### Testing

The generator script will also create a test file for your action. Customize it to your needs to test your action.

## Best Practices

- Add all your requirements for purchase in `isPurchaseAllowed`, and all the additional logic in `onProductPurchase`.
- Don't add functions you don't need. For example, if you don't need to gate the purchase, don't add the `isPurchaseAllowed` function.