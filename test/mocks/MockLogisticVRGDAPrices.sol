// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@/pricing-strategies/VRGDA/LogisticVRGDAPrices.sol";

contract MockLogisticVRGDAPrices is LogisticVRGDAPrices {
    constructor(IProductsModule productsModule) LogisticVRGDAPrices(productsModule) {}
}
