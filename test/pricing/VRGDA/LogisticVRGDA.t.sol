// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {RegistryProductPriceTest} from "@test/utils/RegistryProductPriceTest.sol";
import {unsafeDiv, wadLn, toWadUnsafe, toDaysWadUnsafe, fromDaysWadUnsafe} from "@/utils/math/SignedWadMath.sol";
import "./mocks/MockLogisticVRGDAPrices.sol";

uint256 constant ONE_THOUSAND_YEARS = 356 days * 1000;

uint256 constant MAX_SELLABLE = 6392;

uint256 constant slicerId = 0;
uint256 constant productId = 1;
uint256 constant variantId = 0;
uint16 constant min = 1e4;
int184 constant priceDecayPercent = 0.31e18;
int256 constant timeScale = 0.0023e18;
int256 constant logisticLimitAdjusted = int256((MAX_SELLABLE + 1) * 2e18);
int256 constant logisticLimitDoubled = int256((MAX_SELLABLE + 1e18) * 2e18);

contract LogisticVRGDATest is RegistryProductPriceTest {
    MockLogisticVRGDAPrices vrgda;
    int128 targetPriceConstant =
        int128(int256(PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, address(0), 1)));
    int128 targetPriceConstant_Erc20 =
        int128(int256(PRODUCTS_MODULE.basePrice(slicerId, productId, variantId, address(20), 1)));

    uint256 minAmount = uint256(int256(targetPriceConstant)) * min / 1e5;
    uint256 minAmount_Erc20 = uint256(int256(targetPriceConstant_Erc20)) * min / 1e5;

    function setUp() public {
        vrgda = new MockLogisticVRGDAPrices(PRODUCTS_MODULE);
        _setHook(address(vrgda));

        bytes memory params = abi.encode(priceDecayPercent, min, timeScale);

        vm.startPrank(productOwner);
        vrgda.configureProduct(slicerId, productId, variantId, params);
        vm.stopPrank();
    }

    function testTargetPrice() public {
        uint256 sold = 0;
        int256 logisticLimit = toWadUnsafe(MAX_SELLABLE + 1);
        int256 logisticFactor = unsafeDiv(logisticLimit * 2e18, toWadUnsafe(sold + 1) + logisticLimit);
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        // Warp to the target sale time so that the VRGDA price equals the target price.
        vm.warp(block.timestamp + fromDaysWadUnsafe(vrgda.getTargetSaleTime(logisticFactor, timeScale)));

        uint256 cost = vrgda.getVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            logisticLimit,
            logisticLimit * 2e18,
            sold,
            timeScale,
            minAmount
        );
        assertApproxEqAbs(cost, uint256(uint128(targetPriceConstant)), 1e13);
    }

    function testPricingBasic() public {
        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 120 days;
        uint256 numMint = 876;
        int256 logisticLimit = toWadUnsafe(MAX_SELLABLE + 1);
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        vm.warp(block.timestamp + timeDelta);

        uint256 cost = vrgda.getVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            logisticLimit,
            logisticLimit * 2e18,
            numMint,
            timeScale,
            minAmount
        );

        // Equal within 2 percent since num mint is rounded from true decimal amount.
        assertApproxEqRel(cost, uint256(uint128(targetPriceConstant)), 0.02e18);
    }

    function testPricingMin() public {
        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 120 days;
        uint256 numMint = 793;
        int256 logisticLimit = toWadUnsafe(MAX_SELLABLE + 1);
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        vm.warp(block.timestamp + timeDelta);

        uint256 cost = vrgda.getVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            logisticLimit,
            logisticLimit * 2e18,
            numMint,
            timeScale,
            minAmount
        );
        assertEq(cost, minAmount);
    }

    function testPricingAdjustedByQuantity() public {
        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 120 days;
        uint256 numMint = 876;
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        vm.warp(block.timestamp + timeDelta);

        uint256 costProduct1 = vrgda.getAdjustedVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            toWadUnsafe(MAX_SELLABLE + 1),
            numMint,
            timeScale,
            minAmount,
            1
        );
        uint256 costProduct2 = vrgda.getAdjustedVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            toWadUnsafe(MAX_SELLABLE + 1),
            numMint + 1,
            timeScale,
            minAmount,
            1
        );
        uint256 costProduct3 = vrgda.getAdjustedVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            toWadUnsafe(MAX_SELLABLE + 1),
            numMint + 2,
            timeScale,
            minAmount,
            1
        );
        uint256 costMultiple = vrgda.getAdjustedVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            toWadUnsafe(MAX_SELLABLE + 1),
            numMint,
            timeScale,
            minAmount,
            3
        );

        assertApproxEqAbs(costMultiple, uint256(costProduct1 + costProduct2 + costProduct3), 0.00001e18);
    }

    function testSetMultiplePrices() public {
        // uint256 targetPriceTest = 7.3013e18;
        uint256 productIdTest = 2;

        bytes memory params = abi.encode(priceDecayPercent, min, timeScale);

        vm.startPrank(productOwner);
        vrgda.configureProduct(slicerId, productIdTest, variantId, params);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 days);

        uint256 price = vrgda.productPrice(slicerId, productIdTest, variantId, address(0), 0, 1, address(0), "");

        // assertApproxEqAbs(uint256(targetPriceTest), ethPrice, 1e18);
        assertNotEq(price, 0);

        uint256 price2 = vrgda.productPrice(slicerId, productId, variantId, address(20), 0, 1, address(0), "");

        assertNotEq(price2, 0);
    }

    function testProductPriceEth() public {
        address ethCurrency = address(0);

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 10 days;
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        vm.warp(block.timestamp + timeDelta);

        uint256 cost = vrgda.getAdjustedVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            toWadUnsafe(MAX_SELLABLE + 1),
            0,
            timeScale,
            minAmount,
            1
        );

        uint256 price = vrgda.productPrice(slicerId, productId, variantId, ethCurrency, 0, 1, address(0), "");

        assertApproxEqAbs(cost, price, 0.00001e18);
    }

    function testProductPriceErc20() public {
        address erc20Currency = address(20);

        // Our VRGDA targets this number of mints at given time.
        uint256 timeDelta = 10 days;
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        vm.warp(block.timestamp + timeDelta);

        uint256 cost = vrgda.getAdjustedVRGDALogisticPrice(
            targetPriceConstant_Erc20,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            toWadUnsafe(MAX_SELLABLE + 1),
            0,
            timeScale,
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
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        vm.warp(block.timestamp + timeDelta);

        uint256 costMultiple = vrgda.getAdjustedVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            toDaysWadUnsafe(block.timestamp),
            toWadUnsafe(MAX_SELLABLE + 1),
            0,
            timeScale,
            minAmount,
            3
        );
        uint256 price = vrgda.productPrice(slicerId, productId, variantId, ethCurrency, 0, 3, address(0), "");

        assertApproxEqAbs(costMultiple, price, 5e14);
    }

    function testGetTargetSaleTimeDoesNotRevertEarly() public view {
        int256 logisticLimit = toWadUnsafe(MAX_SELLABLE + 1);
        int256 logisticFactor = unsafeDiv(logisticLimit * 2e18, toWadUnsafe(MAX_SELLABLE) + logisticLimit);

        vrgda.getTargetSaleTime(logisticFactor, timeScale);
    }

    function testGetTargetSaleTimeRevertsWhenExpected() public {
        int256 logisticLimit = toWadUnsafe(MAX_SELLABLE + 1);
        int256 logisticFactor = unsafeDiv(logisticLimit * 2e18, toWadUnsafe(MAX_SELLABLE + 1) + logisticLimit);

        vm.expectRevert("UNDEFINED");
        vrgda.getTargetSaleTime(logisticFactor, timeScale);
    }

    function testNoOverflowForMostTokens(uint256 timeSinceStart, uint256 sold) public view {
        int256 logisticLimit = toWadUnsafe(MAX_SELLABLE + 1);
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        vrgda.getVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            int256(bound(timeSinceStart, 0 days, ONE_THOUSAND_YEARS * 1e18)),
            logisticLimit,
            logisticLimit * 2e18,
            bound(sold, 0, 1730),
            timeScale,
            minAmount
        );
    }

    function testNoOverflowForAllTokens(uint256 timeSinceStart, uint256 sold) public view {
        int256 logisticLimit = toWadUnsafe(MAX_SELLABLE + 1);
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        vrgda.getVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            int256(bound(timeSinceStart, 3870 days * 1e18, ONE_THOUSAND_YEARS * 1e18)),
            logisticLimit,
            logisticLimit * 2e18,
            bound(sold, 0, 6391),
            timeScale,
            minAmount
        );
    }

    function testRevert_OverflowBeyondLimitTokens(uint256 timeSinceStart, uint256 sold) public {
        int256 logisticLimit = toWadUnsafe(MAX_SELLABLE + 1);
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        vm.expectRevert();
        vrgda.getVRGDALogisticPrice(
            targetPriceConstant,
            decayConstant,
            int256(bound(timeSinceStart, 0, ONE_THOUSAND_YEARS * 1e18)),
            logisticLimit,
            logisticLimit * 2e18,
            bound(sold, 6392, type(uint128).max),
            timeScale,
            minAmount
        );
    }

    function testAlwaysTargetPriceInRightConditions(uint256 sold) public view {
        sold = bound(sold, 0, MAX_SELLABLE - 1);
        int256 logisticLimit = toWadUnsafe(MAX_SELLABLE + 1);
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);
        int256 logisticFactor = unsafeDiv(logisticLimit * 2e18, toWadUnsafe(sold + 1) + logisticLimit);

        assertApproxEqAbs(
            vrgda.getVRGDALogisticPrice(
                targetPriceConstant,
                decayConstant,
                vrgda.getTargetSaleTime(logisticFactor, timeScale),
                logisticLimit,
                logisticLimit * 2e18,
                sold,
                timeScale,
                minAmount
            ),
            uint256(uint128(targetPriceConstant)),
            0.00001e18
        );
    }
}
