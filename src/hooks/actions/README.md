# Onchain Actions

Onchain actions are smart contracts that execute custom logic when products are purchased on Slice. They implement the `IProductAction` interface and can control purchase eligibility and perform actions after purchases.

## Key Interface: IProductAction

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

## Base Contract: RegistryProductAction

All actions in this directory inherit from `RegistryProductAction`, which provides:
- Registry functionality for reusable hooks across multiple products
- Implementation of `IHookRegistry` for Slice frontend integration
- Base implementations for common patterns

## Available Actions

- **[Allowlisted](./Allowlisted/Allowlisted.sol)**: Onchain action registry for allowlist requirement.
- **[ERC20Gated](./ERC20Gated/ERC20Gated.sol)**: Onchain action registry for ERC20 token gating.
- **[ERC20Mint](./ERC20Mint/ERC20Mint.sol)**: Onchain action registry that mints ERC20 tokens to buyers.
- **[ERC721AMint](./ERC721AMint/ERC721Mint.sol)**: Onchain action registry that mints ERC721A tokens to buyers.
- **[NFTGated](./NFTGated/NFTGated.sol)**: Onchain action registry for NFT gating.

## Creating Custom Actions

To create a custom onchain action:

1. **Inherit from RegistryProductAction**:
```solidity
import {RegistryProductAction, IProductsModule} from "@/utils/RegistryProductAction.sol";

contract MyAction is RegistryProductAction {
    constructor(IProductsModule productsModule) 
        RegistryProductAction(productsModule) {}
}
```

2. **Implement required functions**:
```solidity
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

Actions that inherit from `RegistryProductAction` are automatically compatible with Slice frontends through the `IHookRegistry` interface, enabling:
- Product configuration via `configureProduct()`
- Parameter validation via `paramsSchema()`
- Automatic discovery and integration