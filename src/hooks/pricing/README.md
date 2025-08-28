# Pricing Strategies

Calculate dynamic prices for products on Slice. Pricing strategies implement the `IProductPrice` interface to provide custom pricing logic based on various factors.

## How Pricing Works

The `productPrice` function is called before purchase to determine:
- **ETH price** - Price in native currency
- **Currency price** - Price in ERC20 tokens (if applicable)

## Creating Custom Pricing

### Quick Start with Generator Script

The easiest way to create a new pricing strategy is using the hook generator:

```bash
# From the hooks directory
./script/generate-hook.sh
```

Select:
1. Registry (for Slice-integrated hooks)
2. Pricing Strategy
3. Enter your contract name
4. Enter author name (optional)

The script will create your contract file with the proper template and add it to the aggregator.

### Registry Integration

Strategies inheriting from `RegistryProductPrice` automatically support frontend integration through:
- **Product configuration** via `configureProduct()`
- **Parameter validation** via `paramsSchema()`

### Testing

The generator script will also create a test file for your pricing strategy. Customize it to your needs to test your pricing logic.

## Best Practices

- Ensure the returned price adapts based on the quantity.
- Typically either ETH or currency price is returned, but you can return both if needed.