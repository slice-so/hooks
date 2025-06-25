// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@/pricing-strategies/VRGDA/LinearVRGDAPrices.sol";

contract MockLinearVRGDAPrices is LinearVRGDAPrices {
    constructor(IProductsModule productsModule) LinearVRGDAPrices(productsModule) {}
}
