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
int128 constant targetPriceConstant = 69.42e18;
uint128 constant min = 1e18;
int256 constant priceDecayPercent = 0.31e18;
int256 constant perTimeUnit = 2e18;

contract LinearVRGDATest is RegistryProductPriceTest {
    MockLinearVRGDAPrices vrgda;

    function setUp() public {
        vrgda = new MockLinearVRGDAPrices(PRODUCTS_MODULE);
        _setHook(address(vrgda));

        LinearVRGDAParams[] memory linearParams = new LinearVRGDAParams[](2);
        linearParams[0] = LinearVRGDAParams(address(0), targetPriceConstant, min, perTimeUnit);
        linearParams[1] = LinearVRGDAParams(address(20), targetPriceConstant, min, perTimeUnit);

        bytes memory params = abi.encode(linearParams, priceDecayPercent);

        vm.startPrank(productOwner);
        vrgda.configureProduct(slicerId, productId, params);
        vm.stopPrank();
    }

    function testTargetPrice() public {
        // Warp to the target sale time so that the VRGDA price equals the target price.
        vm.warp(block.timestamp + fromDaysWadUnsafe(vrgda.getTargetSaleTime(1e18, perTimeUnit)));

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);
        uint256 cost = vrgda.getVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), 0, perTimeUnit, min
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
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint, perTimeUnit, min
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
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint, perTimeUnit, min
        );
        assertEq(cost, min);
    }

    function testPricingAdjustedByQuantity() public {
        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 120 days;
        uint256 numMint = 239;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 costProduct1 = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint, perTimeUnit, min, 1
        );
        uint256 costProduct2 = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint + 1, perTimeUnit, min, 1
        );
        uint256 costProduct3 = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint + 2, perTimeUnit, min, 1
        );
        uint256 costMultiple = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), numMint, perTimeUnit, min, 3
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
                min
            ),
            uint256(uint128(targetPriceConstant)),
            0.00001e18
        );
    }

    function testSetMultiplePrices() public {
        uint256 productId_ = 2;
        LinearVRGDAParams[] memory linearParams = new LinearVRGDAParams[](2);
        linearParams[0] = LinearVRGDAParams(address(0), targetPriceConstant, min, perTimeUnit);
        linearParams[1] = LinearVRGDAParams(address(20), targetPriceConstant, min, perTimeUnit);

        bytes memory params = abi.encode(linearParams, priceDecayPercent);

        vm.startPrank(productOwner);
        vrgda.configureProduct(slicerId, productId_, params);
        vm.stopPrank();

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 0.5 days;

        vm.warp(block.timestamp + timeDelta);

        Price memory price = vrgda.productPrice(slicerId, productId_, 0, address(0), 1, address(0), "");

        assertApproxEqAbs(uint256(uint128(targetPriceConstant)), price.eth, 0.00001e18);
        assertEq(price.currency, 0);

        Price memory price2 = vrgda.productPrice(slicerId, productId_, 0, address(20), 1, address(0), "");

        assertEq(price2.eth, 0);
        assertApproxEqAbs(uint256(uint128(targetPriceConstant)), price2.currency, 0.00001e18);
    }

    function testProductPriceEth() public {
        address ethCurrency = address(0);

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 10 days;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 cost = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), 0, perTimeUnit, min, 1
        );

        Price memory price = vrgda.productPrice(slicerId, productId, 0, ethCurrency, 1, address(0), "");

        assertApproxEqAbs(cost, price.eth, 0.00001e18);
        assertEq(price.currency, 0);
    }

    function testProductPriceErc20() public {
        address erc20Currency = address(20);

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 10 days;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 cost = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), 0, perTimeUnit, min, 1
        );

        Price memory price = vrgda.productPrice(slicerId, productId, 0, erc20Currency, 1, address(0), "");

        assertApproxEqAbs(cost, price.currency, 0.00001e18);
        assertEq(price.eth, 0);
    }

    function testProductPriceMultiple() public {
        address ethCurrency = address(0);

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 10 days;

        vm.warp(block.timestamp + timeDelta);

        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 costMultiple = vrgda.getAdjustedVRGDAPrice(
            targetPriceConstant, decayConstant, toDaysWadUnsafe(block.timestamp), 0, perTimeUnit, min, 3
        );
        Price memory price = vrgda.productPrice(slicerId, productId, 0, ethCurrency, 3, address(0), "");

        assertApproxEqAbs(costMultiple, price.eth, 5e14);
    }
}
