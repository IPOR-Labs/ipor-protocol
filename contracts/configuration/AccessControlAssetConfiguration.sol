// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./AccessControlRevoke.sol";

abstract contract AccessControlAssetConfiguration is AccessControlRevoke {
    bytes32 internal constant INCOME_TAX_PERCENTAGE_ROLE = keccak256("INCOME_TAX_PERCENTAGE_ROLE");


    /// @dev Add `root` to the admin role as a member.
    constructor(address root) {
        _setupRole(ADMIN_ROLE, root);
        _setRoleAdmin(INCOME_TAX_PERCENTAGE_ROLE, ADMIN_ROLE);
    }
}
