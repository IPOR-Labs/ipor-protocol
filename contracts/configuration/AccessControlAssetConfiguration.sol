// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./AccessControlRevoke.sol";

abstract contract AccessControlAssetConfiguration is AccessControlRevoke {
    bytes32 internal constant _MILTON_ADMIN_ROLE =
        keccak256("MILTON_ADMIN_ROLE");
    bytes32 internal constant _MILTON_ROLE = keccak256("MILTON_ROLE");

    bytes32 internal constant _MILTON_STORAGE_ADMIN_ROLE =
        keccak256("MILTON_STORAGE_ADMIN_ROLE");
    bytes32 internal constant _MILTON_STORAGE_ROLE =
        keccak256("MILTON_STORAGE_ROLE");

    bytes32 internal constant _JOSEPH_ADMIN_ROLE =
        keccak256("JOSEPH_ADMIN_ROLE");
    bytes32 internal constant _JOSEPH_ROLE = keccak256("JOSEPH_ROLE");

    bytes32 internal constant _ASSET_MANAGEMENT_VAULT_ADMIN_ROLE =
        keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE");
    bytes32 internal constant _ASSET_MANAGEMENT_VAULT_ROLE =
        keccak256("ASSET_MANAGEMENT_VAULT_ROLE");

    function _init() internal {
        _setupRole(_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(_ADMIN_ROLE, _ADMIN_ROLE);

        _setRoleAdmin(_ROLES_INFO_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_ROLES_INFO_ROLE, _ROLES_INFO_ADMIN_ROLE);

        _setRoleAdmin(_MILTON_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_MILTON_ROLE, _MILTON_ADMIN_ROLE);

        _setRoleAdmin(_MILTON_STORAGE_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_MILTON_STORAGE_ROLE, _MILTON_STORAGE_ADMIN_ROLE);

        _setRoleAdmin(_JOSEPH_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_JOSEPH_ROLE, _JOSEPH_ADMIN_ROLE);

        _setRoleAdmin(_ASSET_MANAGEMENT_VAULT_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _ASSET_MANAGEMENT_VAULT_ROLE,
            _ASSET_MANAGEMENT_VAULT_ADMIN_ROLE
        );
    }
}
