// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {
    HookRegistry,
    IProductsModule,
    RegistryAction,
    IProductAction,
    IProductTypeAction,
    ISlicerAction,
    ProductLineItem
} from "@/utils/RegistryAction.sol";
import {ProductHookRegistry, IProductHookRegistry} from "@/utils/RegistryProductAction.sol";
import {ERC20Data} from "./types/ERC20Data.sol";
import {ERC20Mint_BaseToken} from "./utils/ERC20Mint_BaseToken.sol";

/**
 * @title   ERC20Mint
 * @notice  Onchain action registry for minting ERC20 tokens on every purchase.
 * @dev     If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
 * @author  Slice <jacopo.eth>
 */
contract ERC20Mint is RegistryAction {
    /*//////////////////////////////////////////////////////////////
        ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidTokensPerUnit();

    /*//////////////////////////////////////////////////////////////
        MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 slicerId => mapping(uint256 productId => mapping(uint256 variantId => ERC20Data tokenData))) public
        tokenData;
    mapping(uint256 slicerId => mapping(uint256 productTypeId => ERC20Data tokenData)) public productTypeTokenData;
    mapping(uint256 slicerId => ERC20Data tokenData) public slicerTokenData;

    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductAction
     * @dev If `revertOnMaxSupplyReached` is set to true, returns false when max supply is exceeded.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address,
        uint256 quantity,
        bytes memory
    ) public view virtual override returns (bool isAllowed) {
        ERC20Data memory tokenData_ = tokenData[slicerId][productId][variantId];

        return handleIsPurchaseAllowed(tokenData_, quantity, false);
    }

    /**
     * @inheritdoc IProductTypeAction
     * @dev Checks if `account` owns the required amount of all ERC20 tokens.
     */
    function isProductTypePurchaseAllowed(uint256 slicerId, uint256 productTypeId, address, uint256 quantity)
        public
        view
        override
        returns (bool)
    {
        ERC20Data memory tokenData_ = productTypeTokenData[slicerId][productTypeId];

        return handleIsPurchaseAllowed(tokenData_, quantity, false);
    }

    /**
     * @inheritdoc ISlicerAction
     * @dev Checks if `account` owns the required amount of all ERC20 tokens.
     */
    function isSlicerPurchaseAllowed(uint256 slicerId, address, ProductLineItem[] memory productLineItems)
        public
        view
        override
        returns (bool)
    {
        ERC20Data memory tokenData_ = slicerTokenData[slicerId];

        uint256 quantity;
        for (uint256 i = 0; i < productLineItems.length;) {
            quantity += productLineItems[i].quantity;

            unchecked {
                ++i;
            }
        }

        return handleIsPurchaseAllowed(tokenData_, quantity, true);
    }

    /**
     * @inheritdoc RegistryAction
     * @notice Mint tokens to the buyer.
     * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        uint256 variantId,
        address buyer,
        uint256 quantity,
        bytes memory
    ) internal override {
        ERC20Data memory tokenData_ = tokenData[slicerId][productId][variantId];

        handleOnProductPurchase(tokenData_, buyer, quantity);
    }

    /**
     * @inheritdoc RegistryAction
     * @notice Mint tokens to the buyer.
     * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
     */
    function _onProductTypePurchase(uint256 slicerId, uint256 productTypeId, address buyer, uint256 quantity)
        internal
        override
    {
        ERC20Data memory tokenData_ = productTypeTokenData[slicerId][productTypeId];
        handleOnProductPurchase(tokenData_, buyer, quantity);
    }

    /**
     * @inheritdoc RegistryAction
     * @notice Mint tokens to the buyer.
     * @dev If `revertOnMaxSupplyReached` is set to true, reverts when max supply is exceeded.
     */
    function _onSlicerPurchase(uint256 slicerId, address buyer, ProductLineItem[] memory productLineItems)
        internal
        override
    {
        ERC20Data memory tokenData_ = slicerTokenData[slicerId];

        uint256 quantity;
        for (uint256 i = 0; i < productLineItems.length;) {
            quantity += productLineItems[i].quantity;

            unchecked {
                ++i;
            }
        }

        handleOnProductPurchase(tokenData_, buyer, quantity);
    }

    /**
     * @inheritdoc ProductHookRegistry
     * @dev Set the ERC20 data for a product.
     */
    function _configureProduct(uint256 slicerId, uint256 productId, uint256 variantId, bytes memory params)
        internal
        override
    {
        handleConfigure(tokenData[slicerId][productId][variantId], params);
    }

    /**
     * @inheritdoc HookRegistry
     * @dev Set the ERC20 data for a product type.
     */
    function _configureProductType(uint256 slicerId, uint256 productTypeId, bytes memory params) internal override {
        handleConfigure(productTypeTokenData[slicerId][productTypeId], params);
    }

    /**
     * @inheritdoc HookRegistry
     * @dev Set the ERC20 data for a slicer.
     */
    function _configureSlicer(uint256 slicerId, bytes memory params) internal override {
        handleConfigure(slicerTokenData[slicerId], params);
    }

    /**
     * @inheritdoc IProductHookRegistry
     */
    function configureProductSchema() public pure override returns (string memory) {
        return
        "string name,string symbol,uint256 premintAmount,address premintReceiver,bool revertOnMaxSupplyReached,uint256 maxSupply,uint256 tokensPerUnit";
    }

    /*//////////////////////////////////////////////////////////////
        INTERNAL
    //////////////////////////////////////////////////////////////*/

    function handleConfigure(ERC20Data storage tokenDataStorage, bytes memory params) internal {
        (
            string memory name,
            string memory symbol,
            uint256 premintAmount,
            address premintReceiver,
            bool revertOnMaxSupplyReached,
            uint256 maxSupply,
            uint256 tokensPerUnit
        ) = abi.decode(params, (string, string, uint256, address, bool, uint256, uint256));

        if (tokensPerUnit == 0) revert InvalidTokensPerUnit();

        ERC20Mint_BaseToken token = tokenDataStorage.token;
        if (address(token) == address(0)) {
            token = new ERC20Mint_BaseToken(name, symbol, maxSupply);

            if (premintAmount != 0) {
                token.mint(premintReceiver, premintAmount);
            }
        } else {
            token.setMaxSupply(maxSupply);
        }

        tokenDataStorage.token = token;
        tokenDataStorage.revertOnMaxSupplyReached = revertOnMaxSupplyReached;
        tokenDataStorage.tokensPerUnit = tokensPerUnit;
    }

    function handleIsPurchaseAllowed(ERC20Data memory tokenData_, uint256 quantity, bool isSlicerAction)
        internal
        view
        returns (bool)
    {
        if (!isSlicerAction && tokenData_.revertOnMaxSupplyReached) {
            return
                tokenData_.token.totalSupply() + (quantity * tokenData_.tokensPerUnit) <= tokenData_.token.maxSupply();
        }

        return true;
    }

    function handleOnProductPurchase(ERC20Data memory tokenData_, address buyer, uint256 quantity) internal {
        uint256 tokensToMint = quantity * tokenData_.tokensPerUnit;

        (bool success,) =
            address(tokenData_.token).call(abi.encodeWithSelector(tokenData_.token.mint.selector, buyer, tokensToMint));

        if (success) {
            // Do nothing, just silence the warning
        }
    }
}
