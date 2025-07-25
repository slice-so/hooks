// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {RegistryPricingStrategyTest} from "@test/utils/RegistryPricingStrategyTest.sol";
import {wadLn, toWadUnsafe} from "@/utils/math/SignedWadMath.sol";
import {IProductsModule} from "@/utils/PricingStrategy.sol";
import {MockLinearVRGDAPrices, LinearVRGDAParams} from "../mocks/MockLinearVRGDAPrices.sol";

contract LinearVRGDACorrectnessTest is RegistryPricingStrategyTest {
    // Sample parameters for differential fuzzing campaign.
    uint256 constant maxTimeframe = 356 days * 10;
    uint256 constant maxSellable = 10000;

    uint256 constant slicerId = 0;
    uint256 constant productId = 1;
    int128 constant targetPriceConstant = 69.42e18;
    uint128 constant min = 1e18;
    int256 constant priceDecayPercent = 0.31e18;
    int256 constant perTimeUnit = 2e18;

    MockLinearVRGDAPrices vrgda;

    function setUp() public {
        vrgda = new MockLinearVRGDAPrices(PRODUCTS_MODULE);
        _setHook(address(vrgda));

        LinearVRGDAParams[] memory linearParams = new LinearVRGDAParams[](1);
        linearParams[0] = LinearVRGDAParams(address(0), targetPriceConstant, min, perTimeUnit);

        vm.prank(productOwner);
        bytes memory params = abi.encode(linearParams, priceDecayPercent);
        vrgda.configureProduct(slicerId, productId, params);
    }

    function testFFICorrectness() public {
        // 10 days in wads.
        uint256 timeSinceStart = 10e18;

        // Number sold, slightly ahead of schedule.
        uint256 numSold = 25;
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        uint256 actualPrice =
            vrgda.getVRGDAPrice(targetPriceConstant, decayConstant, int256(timeSinceStart), numSold, perTimeUnit, min);

        uint256 expectedPrice =
            calculatePrice(targetPriceConstant, priceDecayPercent, perTimeUnit, timeSinceStart, numSold);

        console.log("actual price", actualPrice);
        console.log("expected price", expectedPrice);

        // Check approximate equality.
        assertApproxEqAbs(expectedPrice, actualPrice, 0.00001e18);

        // Sanity check that prices are greater than zero.
        assertGt(actualPrice, 0);
    }

    // fuzz to test correctness against multiple inputs
    function testFFICorrectnessFuzz(uint256 timeSinceStart, uint256 numSold) public {
        // Bound fuzzer inputs to acceptable ranges.
        numSold = bound(numSold, 0, maxSellable);
        timeSinceStart = bound(timeSinceStart, 0, maxTimeframe);

        // Convert to wad days for convenience.
        timeSinceStart = (timeSinceStart * 1e18) / 1 days;
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);

        // We wrap this call in a try catch because the getVRGDAPrice is expected to
        // revert for degenerate cases. When this happens, we just continue campaign.
        try vrgda.getVRGDAPrice(targetPriceConstant, decayConstant, int256(timeSinceStart), numSold, perTimeUnit, min)
        returns (uint256 actualPrice) {
            uint256 expectedPrice =
                calculatePrice(targetPriceConstant, priceDecayPercent, perTimeUnit, timeSinceStart, numSold);

            if (expectedPrice < 0.0000001e18) return; // For really small prices, we expect divergence, so we skip.

            assertApproxEqAbs(expectedPrice, actualPrice, 0.00001e18);
        } catch {}
    }

    function calculatePrice(
        int256 _targetPrice,
        int256 _priceDecreasePercent,
        int256 _perUnitTime,
        uint256 _timeSinceStart,
        uint256 _numSold
    ) private returns (uint256) {
        string[] memory inputs = new string[](13);
        inputs[0] = "python3";
        inputs[1] = "test/correctness/python/compute_price.py";
        inputs[2] = "linear";
        inputs[3] = "--time_since_start";
        inputs[4] = vm.toString(_timeSinceStart);
        inputs[5] = "--num_sold";
        inputs[6] = vm.toString(_numSold);
        inputs[7] = "--targetPrice";
        inputs[8] = vm.toString(uint256(_targetPrice));
        inputs[9] = "--priceDecayPercent";
        inputs[10] = vm.toString(uint256(_priceDecreasePercent));
        inputs[11] = "--per_time_unit";
        inputs[12] = vm.toString(uint256(_perUnitTime));

        return abi.decode(vm.ffi(inputs), (uint256));
    }
}
