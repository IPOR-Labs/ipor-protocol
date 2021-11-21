// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AccessControlConfiguration is AccessControl {
    bytes32 internal constant IPOR_ASSETS_ROLE = keccak256("IPOR_ASSETS_ROLE");
    bytes32 internal constant MILTON_ROLE = keccak256("MILTON_ROLE");
    bytes32 internal constant MILTON_STORAGE_ROLE = keccak256("MILTON_STORAGE_ROLE");
    bytes32 internal constant MILTON_UTILIZATION_STRATEGY_ROLE = keccak256("MILTON_UTILIZATION_STRATEGY_ROLE");
    bytes32 internal constant MILTON_SPREAD_STRATEGY_ROLE = keccak256("MILTON_SPREAD_STRATEGY_ROLE");
    bytes32 internal constant IPOR_CONFIGURATION_ROLE = keccak256("IPOR_CONFIGURATION_ROLE");
    bytes32 internal constant WARREN_ROLE = keccak256("WARREN_ROLE");






    /// @dev Add `root` to the admin role as a member.
    constructor (address root)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, root);
        _setRoleAdmin(IPOR_ASSETS_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MILTON_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MILTON_STORAGE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MILTON_UTILIZATION_STRATEGY_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MILTON_SPREAD_STRATEGY_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(IPOR_CONFIGURATION_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(WARREN_ROLE, DEFAULT_ADMIN_ROLE);

    }
}

