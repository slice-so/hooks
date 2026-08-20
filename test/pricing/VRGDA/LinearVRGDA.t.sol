// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductPriceTest} from "@test/utils/RegistryProductPriceTest.sol";
import {wadLn, toWadUnsafe, toDaysWadUnsafe, fromDaysWadUnsafe} from "@/utils/math/SignedWadMath.sol";

import "./mocks/MockLinearVRGDAPrices.sol";
import {IProductsModule} from "@/utils/ProductPrice.sol";

uint256 constant ONE_THOUSAND_YEARS = 356 days * 1000;

uint256 constant MAX_SELLABLE = 6392;

uint256 constant slicerId = 0;
uint256 constant productId = 1;
uint256 constant variantId = 0;
uint16 constant min = 1e4;
int184 constant priceDecayPercent = 0.31e18;
int256 constant perTimeUnit = 2e18;

contract LinearVRGDATest is RegistryProductPriceTest {
    MockLinearVRGDAPrices vrgda;
    int128 targetPriceConstant =
        int128(int256(PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, address(0), 1)));
    int128 targetPriceConstant_Erc20 =
        int128(int256(PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, address(20), 1)));

    uint256 minAmount = uint256(int256(targetPriceConstant)) * min / 1e5;
    uint256 minAmount_Erc20 = uint256(int256(targetPriceConstant_Erc20)) * min / 1e5;

    function setUp() public {
        vrgda = new MockLinearVRGDAPrices(PRODUCTS_MODULE);
        _setHook(address(vrgda));

        bytes memory params = abi.encode(priceDecayPercent, min, perTimeUnit);

        vm.startPrank(productOwner);
        vrgda.configureProduct(slicerId, productId, variantId, params);
        vm.stopPrank();
    }

    function testTargetPrice() public {
        // Warp to the target sale time so that the VRGDA price equals the target price.
        vm.warp(block.timestamp + fromDaysWadUnsafe(vrgda.getTargetSaleTime(1e18, perTimeUnit)));

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);
        uint256 cost = vrgda.getVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), 0, perTimeUnit, minAmount
        );
        assertApproxEqAbs(cost, uint256(uint128(targetPriceConstant)), 5e14);
    }

    function testPricingBasic() public {
        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 120 days;
        uint256 numMint = 239;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);
        uint256 cost = vrgda.getVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint, perTimeUnit, minAmount
        );
        assertApproxEqAbs(cost, uint256(uint128(targetPriceConstant)), 5e14);
    }

    function testPricingMin() public {
        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 120 days;
        uint256 numMint = 216;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 cost = vrgda.getVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint, perTimeUnit, minAmount
        );
        assertEq(cost, minAmount);
    }

    function testPricingAdjustedByQuantity() public {
        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 120 days;
        uint256 numMint = 239;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 costProduct1 = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint, perTimeUnit, minAmount, 1
        );
        uint256 costProduct2 = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint + 1, perTimeUnit, minAmount, 1
        );
        uint256 costProduct3 = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint + 2, perTimeUnit, minAmount, 1
        );
        uint256 costMultiple = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint, perTimeUnit, minAmount, 3
        );

        assertApproxEqAbs(costMultiple, uint256(costProduct1 + costProduct2 + costProduct3), 0.00001e18);
    }

    function testAlwaystargetPriceInRightConditions(uint256 sold) public view {
        sold = bound(sold, 0, type(uint128).max);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);
        assertApproxEqAbs(
            vrgda.getVRGDAPrice(
                targetPriceConstant,
                decayConstant,
                vrgda.getTargetSaleTime(toWadUnsafe(sold + 1), perTimeUnit),
                sold,
                perTimeUnit,
                minAmount
            ),
            uint256(uint128(targetPriceConstant)),
            0.00001e18
        );
    }

    function testSetMultiplePrices() public {
        uint256 productId_ = 2;

        bytes memory params = abi.encode(priceDecayPercent, min, perTimeUnit);

        vm.startPrank(productOwner);
        vrgda.configureProduct(slicerId, productId_, variantId, params);
        vm.stopPrank();

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 0.5 days;

        vm.warp(block.timestamp + timeDelta);

        uint256 price = vrgda.productPrice(slicerId, productId_, variantId, address(0), 0, 1, address(0), "");

        assertApproxEqAbs(uint256(uint128(targetPriceConstant)), price, 0.00001e18);

        price = vrgda.productPrice(slicerId, productId_, variantId, address(20), 0, 1, address(0), "");

        assertApproxEqAbs(uint256(uint128(targetPriceConstant_Erc20)), price, 0.00001e18);
    }

    function testProductPriceEth() public {
        address ethCurrency = address(0);

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 10 days;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 cost = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), 0, perTimeUnit, minAmount, 1
        );

        uint256 price = vrgda.productPrice(slicerId, productId, variantId, ethCurrency, 0, 1, address(0), "");

        assertApproxEqAbs(cost, price, 0.00001e18);
    }

    function testProductPriceErc20() public {
        address erc20Currency = address(20);

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 10 days;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 cost = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant_Erc20,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            0,
            perTimeUnit,
            minAmount_Erc20,
            1
        );

        uint256 price = vrgda.productPrice(slicerId, productId, variantId, erc20Currency, 0, 1, address(0), "");

        assertApproxEqAbs(cost, price, 0.00001e18);
    }

    function testProductPriceMultiple() public {
        address ethCurrency = address(0);

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 10 days;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 costMultiple = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), 0, perTimeUnit, minAmount, 3
        );
        uint256 price = vrgda.productPrice(slicerId, productId, variantId, ethCurrency, 0, 3, address(0), "");

        assertApproxEqAbs(costMultiple, price, 5e14);
    }
}
