// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@/hooks/pricing/VRGDA/LinearVRGDAPrices/LinearVRGDAPrices.sol";

contract MockLinearVRGDAPrices is LinearVRGDAPrices {
    constructor(IProductsModule productsModule) LinearVRGDAPrices(productsModule) {}
}
