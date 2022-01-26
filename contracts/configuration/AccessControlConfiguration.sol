// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./AccessControlRevoke.sol";

abstract contract AccessControlConfiguration is AccessControlRevoke {
    bytes32 internal constant _IPOR_ASSETS_ADMIN_ROLE =
        keccak256("IPOR_ASSETS_ADMIN_ROLE");
    bytes32 internal constant _IPOR_ASSETS_ROLE = keccak256("IPOR_ASSETS_ROLE");

    bytes32 internal constant _IPOR_ASSET_CONFIGURATION_ADMIN_ROLE =
        keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE");
    bytes32 internal constant _IPOR_ASSET_CONFIGURATION_ROLE =
        keccak256("IPOR_ASSET_CONFIGURATION_ROLE");

    bytes32 internal constant _WARREN_ADMIN_ROLE =
        keccak256("WARREN_ADMIN_ROLE");
    bytes32 internal constant _WARREN_ROLE = keccak256("WARREN_ROLE");

    bytes32 internal constant _WARREN_STORAGE_ADMIN_ROLE =
        keccak256("WARREN_STORAGE_ADMIN_ROLE");
    bytes32 internal constant _WARREN_STORAGE_ROLE =
        keccak256("WARREN_STORAGE_ROLE");

    bytes32 internal constant _MILTON_SPREAD_MODEL_ADMIN_ROLE =
        keccak256("MILTON_SPREAD_MODEL_ADMIN_ROLE");
    bytes32 internal constant _MILTON_SPREAD_MODEL_ROLE =
        keccak256("MILTON_SPREAD_MODEL_ROLE");

    bytes32 internal constant _MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE =
        keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE");
    bytes32 internal constant _MILTON_LP_UTILIZATION_STRATEGY_ROLE =
        keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE");

    bytes32 internal constant _MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE =
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE");
    bytes32 internal constant _MILTON_PUBLICATION_FEE_TRANSFERER_ROLE =
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE");

    constructor(address root) {
        _setupRole(_ADMIN_ROLE, root);
        _setRoleAdmin(_ADMIN_ROLE, _ADMIN_ROLE);

        _setRoleAdmin(_ROLES_INFO_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_ROLES_INFO_ROLE, _ROLES_INFO_ADMIN_ROLE);

        _setRoleAdmin(_IPOR_ASSETS_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_IPOR_ASSETS_ROLE, _IPOR_ASSETS_ADMIN_ROLE);        

        _setRoleAdmin(_MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _MILTON_LP_UTILIZATION_STRATEGY_ROLE,
            _MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE
        );

        _setRoleAdmin(_MILTON_SPREAD_MODEL_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _MILTON_SPREAD_MODEL_ROLE,
            _MILTON_SPREAD_MODEL_ADMIN_ROLE
        );

        _setRoleAdmin(_IPOR_ASSET_CONFIGURATION_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _IPOR_ASSET_CONFIGURATION_ROLE,
            _IPOR_ASSET_CONFIGURATION_ADMIN_ROLE
        );

        _setRoleAdmin(_WARREN_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_WARREN_ROLE, _WARREN_ADMIN_ROLE);

        _setRoleAdmin(_WARREN_STORAGE_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_WARREN_STORAGE_ROLE, _WARREN_STORAGE_ADMIN_ROLE);        

        _setRoleAdmin(
            _MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE,
            _ADMIN_ROLE
        );
        _setRoleAdmin(
            _MILTON_PUBLICATION_FEE_TRANSFERER_ROLE,
            _MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE
        );
    }
}
