#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Slice Hook Generator ===${NC}"
echo

# Prompt for hook scope
echo -e "${YELLOW}Choose hook scope:${NC}"
echo "1) Registry (integrated, multi-product hook)"
echo "2) Product-specific (custom, single product hook)"
read -p "Enter your choice (1 or 2): " scope_choice

case $scope_choice in
    1)
        SCOPE="registry"
        echo -e "${GREEN} Selected: Registry hook${NC}"
        ;;
    2)
        SCOPE="product"
        echo -e "${GREEN} Selected: Product-specific hook${NC}"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo

# Prompt for hook type
echo -e "${YELLOW}Choose hook type:${NC}"
echo "1) Onchain Action"
echo "2) Pricing Strategy"
echo "3) Pricing Action"
read -p "Enter your choice (1, 2, or 3): " type_choice

case $type_choice in
    1)
        TYPE="action"
        TYPE_DISPLAY="Action"
        echo -e "${GREEN} Selected: Onchain Action${NC}"
        ;;
    2)
        TYPE="pricing-strategy"
        TYPE_DISPLAY="Pricing Strategy"
        echo -e "${GREEN} Selected: Pricing Strategy${NC}"
        ;;
    3)
        TYPE="pricing-action"
        TYPE_DISPLAY="Pricing Action"
        echo -e "${GREEN} Selected: Pricing Action${NC}"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo

# Prompt for contract name
read -p "Enter contract name (e.g., MyAction): " CONTRACT_NAME

if [ -z "$CONTRACT_NAME" ]; then
    echo "Contract name cannot be empty. Exiting."
    exit 1
fi

# Capitalize first letter of contract name
CONTRACT_NAME=$(echo "$CONTRACT_NAME" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

echo -e "${GREEN}✓ Contract name: ${CONTRACT_NAME}${NC}"

# Check for duplicate hook names
EXISTING_DIRS=""
case $TYPE in
    "action")
        EXISTING_DIRS="src/hooks/actions/${CONTRACT_NAME}"
        ;;
    "pricing-strategy")
        EXISTING_DIRS="src/hooks/pricing/${CONTRACT_NAME}"
        ;;
    "pricing-action")
        EXISTING_DIRS="src/hooks/pricingActions/${CONTRACT_NAME}"
        ;;
esac

if [ -d "$EXISTING_DIRS" ]; then
    echo -e "${RED}✗ Error: Hook '${CONTRACT_NAME}' already exists at ${EXISTING_DIRS}${NC}"
    echo "Please choose a different name."
    exit 1
fi

echo

# Optional prompt for authorship
read -p "Enter author name (optional, press Enter to use 'Slice'): " AUTHOR
if [ -z "$AUTHOR" ]; then
    AUTHOR="Slice"
fi
echo -e "${GREEN}✓ Author: ${AUTHOR}${NC}"
echo

# Set directory based on type
case $TYPE in
    "action")
        DIR="src/hooks/actions/${CONTRACT_NAME}"
        ;;
    "pricing-strategy")
        DIR="src/hooks/pricing/${CONTRACT_NAME}"
        ;;
    "pricing-action")
        DIR="src/hooks/pricingActions/${CONTRACT_NAME}"
        ;;
esac

# Create directory
mkdir -p "$DIR"

# Generate file path
FILE_PATH="${DIR}/${CONTRACT_NAME}.sol"

echo -e "${BLUE}Generating contract at: ${FILE_PATH}${NC}"

# Generate contract content based on scope and type
if [ "$SCOPE" = "registry" ] && [ "$TYPE" = "action" ]; then
    cat > "$FILE_PATH" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    RegistryProductAction,
    HookRegistry,
    IProductsModule,
    IProductAction,
    IHookRegistry
} from "@/utils/RegistryProductAction.sol";

/**
 * @title   CONTRACT_NAME
 * @notice  Onchain action registry contract.
 * @author  AUTHOR
 */
contract CONTRACT_NAME is RegistryProductAction {
    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryProductAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductAction
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) public view override returns (bool) {
        // Your eligibility logic. Return true if eligible, false otherwise.
        // Returns true by default.

        return true;
    }

    /**
     * @inheritdoc RegistryProductAction
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) internal override {
        // Your logic to be executed after product purchase.
    }

    /**
     * @inheritdoc HookRegistry
     */
    function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        // Decode params according to `paramsSchema` and store any data required for your logic.
    }

    /**
     * @inheritdoc IHookRegistry
     */
    function paramsSchema() external pure override returns (string memory) {
        // Define the schema for the parameters that will be passed to `_configureProduct`.
        return "";
    }
}
EOF

elif [ "$SCOPE" = "product" ] && [ "$TYPE" = "action" ]; then
    cat > "$FILE_PATH" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ProductAction, IProductsModule, IProductAction} from "@/utils/ProductAction.sol";

/**
 * @title   CONTRACT_NAME
 * @notice  Custom onchain action.
 * @author  AUTHOR
 */
contract CONTRACT_NAME is ProductAction {
    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress, uint256 slicerId)
        ProductAction(productsModuleAddress, slicerId)
    {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductAction
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) public view override returns (bool) {
        // Your eligibility logic. Return true if eligible, false otherwise.
        return true;
    }

    /**
     * @inheritdoc ProductAction
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) internal override {
        // Your logic to be executed after product purchase.
    }
}
EOF

elif [ "$SCOPE" = "registry" ] && [ "$TYPE" = "pricing-strategy" ]; then
    cat > "$FILE_PATH" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    RegistryProductPrice,
    HookRegistry,
    IProductsModule,
    IProductPrice,
    IHookRegistry
} from "@/utils/RegistryProductPrice.sol";

/**
 * @title   CONTRACT_NAME
 * @notice  Pricing strategy registry contract.
 * @author  AUTHOR
 */
contract CONTRACT_NAME is RegistryProductPrice {
    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryProductPrice(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductPrice
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data
    ) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
        // Your pricing logic. Calculate and return the total price, depending on the passed quantity.
    }

    /**
     * @inheritdoc HookRegistry
     */
    function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        // Decode params according to `paramsSchema` and store any data required for your pricing logic.
    }

    /**
     * @inheritdoc IHookRegistry
     */
    function paramsSchema() external pure override returns (string memory) {
        // Define the schema for the parameters that will be passed to `_configureProduct`.
        return "";
    }
}
EOF

elif [ "$SCOPE" = "product" ] && [ "$TYPE" = "pricing-strategy" ]; then
    cat > "$FILE_PATH" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ProductPrice, IProductsModule, IProductPrice} from "@/utils/ProductPrice.sol";

/**
 * @title   CONTRACT_NAME
 * @notice  Custom pricing strategy.
 * @author  AUTHOR
 */
contract CONTRACT_NAME is ProductPrice {
    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress, uint256 slicerId)
        ProductPrice(productsModuleAddress)
    {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductPrice
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data
    ) external view returns (uint256 ethPrice, uint256 currencyPrice) {
        // Your pricing logic. Calculate and return the total price.
    }
}
EOF

elif [ "$SCOPE" = "registry" ] && [ "$TYPE" = "pricing-action" ]; then
    cat > "$FILE_PATH" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    RegistryProductPriceAction,
    RegistryProductAction,
    HookRegistry,
    IProductsModule,
    IProductAction,
    IProductPrice,
    IHookRegistry
} from "@/utils/RegistryProductPriceAction.sol";

/**
 * @title   CONTRACT_NAME
 * @notice  Pricing action registry contract.
 * @author  AUTHOR
 */
contract CONTRACT_NAME is RegistryProductPriceAction {
    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress) RegistryProductPriceAction(productsModuleAddress) {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductPrice
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data
    ) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
        // Your pricing logic. Calculate and return the total price, depending on the passed quantity.
    }

    /**
     * @inheritdoc IProductAction
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) public view override returns (bool) {
        // Your eligibility logic. Return true if eligible, false otherwise.
        // Returns true by default.

        return true;
    }

    /**
     * @inheritdoc RegistryProductAction
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) internal override {
        // Your logic to be executed after product purchase.
    }

    /**
     * @inheritdoc HookRegistry
     */
    function _configureProduct(uint256 slicerId, uint256 productId, bytes memory params) internal override {
        // Decode params according to `paramsSchema` and store any data required for your logic.
    }

    /**
     * @inheritdoc IHookRegistry
     */
    function paramsSchema() external pure override returns (string memory) {
        // Define the schema for the parameters that will be passed to `_configureProduct`.
        return "";
    }
}
EOF

elif [ "$SCOPE" = "product" ] && [ "$TYPE" = "pricing-action" ]; then
    cat > "$FILE_PATH" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ProductPriceAction,
    ProductAction,
    IProductsModule,
    IProductAction,
    IProductPrice
} from "@/utils/ProductPriceAction.sol";

/**
 * @title   CONTRACT_NAME
 * @notice  Custom pricing action.
 * @author  AUTHOR
 */
contract CONTRACT_NAME is ProductPriceAction {
    /*//////////////////////////////////////////////////////////////
        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(IProductsModule productsModuleAddress, uint256 slicerId)
        ProductPriceAction(productsModuleAddress, slicerId)
    {}

    /*//////////////////////////////////////////////////////////////
        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IProductPrice
     */
    function productPrice(
        uint256 slicerId,
        uint256 productId,
        address currency,
        uint256 quantity,
        address buyer,
        bytes memory data
    ) external view returns (uint256 ethPrice, uint256 currencyPrice) {
        // Your pricing logic. Calculate and return the total price.
    }

    /**
     * @inheritdoc IProductAction
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) public view override returns (bool) {
        // Your eligibility logic. Return true if eligible, false otherwise.
        return true;
    }

    /**
     * @inheritdoc ProductAction
     */
    function _onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address buyer,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) internal override {
        // Your logic to be executed after product purchase.
    }
}
EOF

else
    echo "Error: Unsupported combination of scope and type."
    exit 1
fi

# Replace placeholders with actual values
sed -i.bak "s/CONTRACT_NAME/${CONTRACT_NAME}/g" "$FILE_PATH" && rm "${FILE_PATH}.bak"
sed -i.bak "s/AUTHOR/${AUTHOR}/g" "$FILE_PATH" && rm "${FILE_PATH}.bak"

echo -e "${GREEN}✅ Successfully generated ${CONTRACT_NAME}.sol${NC}"

# Add to aggregator contract (only for registry hooks)
if [ "$SCOPE" = "registry" ]; then
    AGGREGATOR_FILE=""
    case $TYPE in
        "action")
            AGGREGATOR_FILE="src/hooks/actions/actions.sol"
            ;;
        "pricing-strategy")
            AGGREGATOR_FILE="src/hooks/pricing/pricing.sol"
            ;;
        "pricing-action")
            AGGREGATOR_FILE="src/hooks/pricingActions/pricingActions.sol"
            ;;
    esac

    if [ -f "$AGGREGATOR_FILE" ]; then
    # Check if import already exists
    if ! grep -q "import {${CONTRACT_NAME}}" "$AGGREGATOR_FILE"; then
        # Construct the import path based on type
        case $TYPE in
            "action")
                IMPORT_LINE="import {${CONTRACT_NAME}} from \"./${CONTRACT_NAME}/${CONTRACT_NAME}.sol\";"
                ;;
            "pricing-strategy")
                IMPORT_LINE="import {${CONTRACT_NAME}} from \"./${CONTRACT_NAME}/${CONTRACT_NAME}.sol\";"
                ;;
            "pricing-action")
                IMPORT_LINE="import {${CONTRACT_NAME}} from \"./${CONTRACT_NAME}/${CONTRACT_NAME}.sol\";"
                ;;
        esac
        
        # Find where to insert the import alphabetically
        # Create temporary file with all imports including the new one
        TEMP_FILE=$(mktemp)
        
        # Extract existing imports
        grep "^import {" "$AGGREGATOR_FILE" > "$TEMP_FILE"
        
        # Add new import to temp file
        echo "$IMPORT_LINE" >> "$TEMP_FILE"
        
        # Sort imports alphabetically
        SORTED_IMPORTS=$(sort "$TEMP_FILE")
        
        # Find line number where imports start and end
        FIRST_IMPORT=$(grep -n "^import {" "$AGGREGATOR_FILE" | head -1 | cut -d: -f1)
        LAST_IMPORT=$(grep -n "^import {" "$AGGREGATOR_FILE" | tail -1 | cut -d: -f1)
        
        # Create new file with sorted imports
        head -n $((FIRST_IMPORT - 1)) "$AGGREGATOR_FILE" > "${AGGREGATOR_FILE}.tmp"
        echo "$SORTED_IMPORTS" >> "${AGGREGATOR_FILE}.tmp"
        tail -n +$((LAST_IMPORT + 1)) "$AGGREGATOR_FILE" >> "${AGGREGATOR_FILE}.tmp"
        
        # Replace original file
        mv "${AGGREGATOR_FILE}.tmp" "$AGGREGATOR_FILE"
        
        # Clean up temp file
        rm "$TEMP_FILE"
        
        echo -e "${GREEN}✅ Added import to aggregator: ${AGGREGATOR_FILE}${NC}"
    else
        echo -e "${YELLOW}⚠️  Import already exists in aggregator${NC}"
    fi
    fi
fi

# Generate test file for registry hooks
if [ "$SCOPE" = "registry" ]; then
    TEST_DIR=""
    case $TYPE in
        "action")
            TEST_DIR="test/actions/${CONTRACT_NAME}"
            ;;
        "pricing-strategy")
            TEST_DIR="test/pricing/${CONTRACT_NAME}"
            ;;
        "pricing-action")
            TEST_DIR="test/pricingActions/${CONTRACT_NAME}"
            ;;
    esac
    
    mkdir -p "$TEST_DIR"
    TEST_FILE="${TEST_DIR}/${CONTRACT_NAME}.t.sol"
    
    echo -e "${BLUE}Generating test file at: ${TEST_FILE}${NC}"
    
    # Generate test content based on type
    if [ "$TYPE" = "action" ]; then
        cat > "$TEST_FILE" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistryProductAction, RegistryProductActionTest} from "@test/utils/RegistryProductActionTest.sol";
import {CONTRACT_NAME} from "@/hooks/actions/CONTRACT_NAME/CONTRACT_NAME.sol";

contract CONTRACT_NAMETest is RegistryProductActionTest {
    CONTRACT_NAME CONTRACT_VAR;
    uint256 slicerId = 1;
    uint256 productId = 1;

    function setUp() public {
        CONTRACT_VAR = new CONTRACT_NAME(PRODUCTS_MODULE);
        _setHook(address(CONTRACT_VAR));
    }

    function testConfigureProduct() public {
        vm.startPrank(productOwner);

        // Configure product
        CONTRACT_VAR.configureProduct(
            slicerId,
            productId,
            abi.encode(
                // Your params here
            )
        );

        vm.stopPrank();

        // Verify product is configured correctly
    }

    function testIsPurchaseAllowed() public {
        vm.startPrank(productOwner);

        // Configure product
        CONTRACT_VAR.configureProduct(
            slicerId,
            productId,
            abi.encode(
                // Your params here
            )
        );

        vm.stopPrank();

        bool isAllowed = CONTRACT_VAR.isPurchaseAllowed(slicerId, productId, buyer, 1, "", "");
    
        // Verify isAllowed value based on conditions
    }

    function testOnProductPurchase() public {
        vm.startPrank(productOwner);

        // Configure product
        CONTRACT_VAR.configureProduct(
            slicerId,
            productId,
            abi.encode(
                // Your params here
            )
        );

        vm.stopPrank();

        vm.prank(address(PRODUCTS_MODULE));
        CONTRACT_VAR.onProductPurchase(slicerId, productId, buyer, 1, "", "");

        // Verify after purchase logic
    }
}
EOF
    elif [ "$TYPE" = "pricing-strategy" ]; then
        cat > "$TEST_FILE" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistryProductPrice, RegistryProductPriceTest} from "@test/utils/RegistryProductPriceTest.sol";
import {CONTRACT_NAME} from "@/hooks/pricing/CONTRACT_NAME/CONTRACT_NAME.sol";

contract CONTRACT_NAMETest is RegistryProductPriceTest {
    CONTRACT_NAME CONTRACT_VAR;
    uint256 slicerId = 1;
    uint256 productId = 1;

    function setUp() public {
        CONTRACT_VAR = new CONTRACT_NAME(PRODUCTS_MODULE);
        _setHook(address(CONTRACT_VAR));
    }

    function testConfigureProduct() public {
        vm.startPrank(productOwner);

        // Configure product
        CONTRACT_VAR.configureProduct(
            slicerId,
            productId,
            abi.encode(
                // Your params here
            )
        );

        vm.stopPrank();

        // Verify product is configured correctly
    }

    function testProductPrice() public {
        vm.startPrank(productOwner);

        // Configure product
        CONTRACT_VAR.configureProduct(
            slicerId,
            productId,
            abi.encode(
                // Your params here
            )
        );

        vm.stopPrank();

        (uint256 ethPrice, uint256 currencyPrice) = CONTRACT_VAR.productPrice(slicerId, productId, ETH, 1, buyer, "");

        // Verify product price
    }
}
EOF
    elif [ "$TYPE" = "pricing-action" ]; then
        cat > "$TEST_FILE" << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistryProductPriceAction, RegistryProductPriceActionTest} from "@test/utils/RegistryProductPriceActionTest.sol";
import {CONTRACT_NAME} from "@/hooks/pricingActions/CONTRACT_NAME/CONTRACT_NAME.sol";

contract CONTRACT_NAMETest is RegistryProductPriceActionTest {
    CONTRACT_NAME CONTRACT_VAR;
    uint256 slicerId = 1;
    uint256 productId = 1;

    function setUp() public {
        CONTRACT_VAR = new CONTRACT_NAME(PRODUCTS_MODULE);
        _setHook(address(CONTRACT_VAR));
    }

    function testConfigureProduct() public {
        vm.startPrank(productOwner);

        // Configure product
        CONTRACT_VAR.configureProduct(
            slicerId,
            productId,
            abi.encode(
                // Your params here
            )
        );

        vm.stopPrank();

        // Verify product is configured correctly
    }

    function testProductPrice() public {
        vm.startPrank(productOwner);

        // Configure product
        CONTRACT_VAR.configureProduct(
            slicerId,
            productId,
            abi.encode(
                // Your params here
            )
        );

        vm.stopPrank();

        (uint256 ethPrice, uint256 currencyPrice) = CONTRACT_VAR.productPrice(slicerId, productId, ETH, 1, buyer, "");

        // Verify product price
    }

    function testIsPurchaseAllowed() public {
        vm.startPrank(productOwner);

        // Configure product
        CONTRACT_VAR.configureProduct(
            slicerId,
            productId,
            abi.encode(
                // Your params here
            )
        );

        vm.stopPrank();

        bool isAllowed = CONTRACT_VAR.isPurchaseAllowed(slicerId, productId, buyer, 1, "", "");
    
        // Verify isAllowed value based on conditions
    }

    function testOnProductPurchase() public {
        vm.startPrank(productOwner);

        // Configure product
        CONTRACT_VAR.configureProduct(
            slicerId,
            productId,
            abi.encode(
                // Your params here
            )
        );

        vm.stopPrank();

        vm.prank(address(PRODUCTS_MODULE));
        CONTRACT_VAR.onProductPurchase(slicerId, productId, buyer, 1, "", "");

        // Verify after purchase logic
    }
}
EOF
    fi
    
    # Replace placeholders
    CONTRACT_VAR=$(echo "$CONTRACT_NAME" | awk '{print tolower(substr($0,1,1)) substr($0,2)}')
    sed -i.bak "s/CONTRACT_NAME/${CONTRACT_NAME}/g" "$TEST_FILE" && rm "${TEST_FILE}.bak"
    sed -i.bak "s/CONTRACT_VAR/${CONTRACT_VAR}/g" "$TEST_FILE" && rm "${TEST_FILE}.bak"
    
    echo -e "${GREEN}✅ Generated test file: ${TEST_FILE}${NC}"
fi

echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review and customize the generated contract"
echo "2. Implement your specific contract logic"
echo "3. Update the test file with your test cases"
echo "4. Run tests with 'forge test'"
echo "5. Deploy using the deployment scripts"