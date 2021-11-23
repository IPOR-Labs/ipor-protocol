// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./AccessControlRevoke.sol";

abstract contract AccessControlAssetConfiguration is AccessControlRevoke {
    bytes32 internal constant INCOME_TAX_PERCENTAGE_ROLE = keccak256("INCOME_TAX_PERCENTAGE_ROLE");
    bytes32 internal constant OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE = keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE");

    constructor(address root) {
        _setupRole(ADMIN_ROLE, root);
        _setRoleAdmin(INCOME_TAX_PERCENTAGE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE, ADMIN_ROLE);
    }
}
