// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./AccessControlRevoke.sol";

abstract contract AccessControlConfiguration is AccessControlRevoke {
    bytes32 internal constant _IPOR_ASSET_CONFIGURATION_ADMIN_ROLE =
        keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE");
    bytes32 internal constant _IPOR_ASSET_CONFIGURATION_ROLE =
        keccak256("IPOR_ASSET_CONFIGURATION_ROLE");

    function _init() internal {
        _setupRole(_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(_ADMIN_ROLE, _ADMIN_ROLE);

        _setRoleAdmin(_ROLES_INFO_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_ROLES_INFO_ROLE, _ROLES_INFO_ADMIN_ROLE);

        _setRoleAdmin(_IPOR_ASSET_CONFIGURATION_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _IPOR_ASSET_CONFIGURATION_ROLE,
            _IPOR_ASSET_CONFIGURATION_ADMIN_ROLE
        );
    }
}
