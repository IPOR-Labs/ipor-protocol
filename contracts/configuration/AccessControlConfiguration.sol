// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AccessControlConfiguration is AccessControl {
    bytes32 internal constant IPOR_ASSETS = keccak256("IPOR_ASSETS");
    /// @dev Add `root` to the admin role as a member.
    constructor (address root)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, root);
        _setRoleAdmin(IPOR_ASSETS, DEFAULT_ADMIN_ROLE);
    }
}

