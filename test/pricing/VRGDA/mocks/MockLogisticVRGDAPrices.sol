// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@/hooks/pricing/VRGDA/LogisticVRGDAPrices/LogisticVRGDAPrices.sol";

contract MockLogisticVRGDAPrices is LogisticVRGDAPrices {
    constructor(IProductsModule productsModule) LogisticVRGDAPrices(productsModule) {}
}
