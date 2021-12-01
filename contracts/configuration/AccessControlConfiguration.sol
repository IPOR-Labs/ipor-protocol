// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./AccessControlRevoke.sol";

abstract contract AccessControlConfiguration is AccessControlRevoke {
    bytes32 internal constant IPOR_ASSETS_ROLE = keccak256("IPOR_ASSETS_ROLE");
    bytes32 internal constant IPOR_ASSETS_ADMIN_ROLE =
        keccak256("IPOR_ASSETS_ADMIN_ROLE");

    bytes32 internal constant MILTON_ROLE = keccak256("MILTON_ROLE");
    bytes32 internal constant MILTON_ADMIN_ROLE =
        keccak256("MILTON_ADMIN_ROLE");

    bytes32 internal constant MILTON_STORAGE_ROLE =
        keccak256("MILTON_STORAGE_ROLE");
    bytes32 internal constant MILTON_STORAGE_ADMIN_ROLE =
        keccak256("MILTON_STORAGE_ADMIN_ROLE");

    bytes32 internal constant MILTON_LP_UTILIZATION_STRATEGY_ROLE =
        keccak256("MILTON_LP_UTILIZATION_STRATEGY_ROLE");
    bytes32 internal constant MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE =
        keccak256("MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE");

    bytes32 internal constant MILTON_SPREAD_STRATEGY_ROLE =
        keccak256("MILTON_SPREAD_STRATEGY_ROLE");
    bytes32 internal constant MILTON_SPREAD_STRATEGY_ADMIN_ROLE =
        keccak256("MILTON_SPREAD_STRATEGY_ADMIN_ROLE");

    bytes32 internal constant IPOR_ASSET_CONFIGURATION_ROLE =
        keccak256("IPOR_ASSET_CONFIGURATION_ROLE");
    bytes32 internal constant IPOR_ASSET_CONFIGURATION_ADMIN_ROLE =
        keccak256("IPOR_ASSET_CONFIGURATION_ADMIN_ROLE");

    bytes32 internal constant WARREN_ROLE = keccak256("WARREN_ROLE");
    bytes32 internal constant WARREN_ADMIN_ROLE =
        keccak256("WARREN_ADMIN_ROLE");

    bytes32 internal constant WARREN_STORAGE_ROLE =
        keccak256("WARREN_STORAGE_ROLE");
    bytes32 internal constant WARREN_STORAGE_ADMIN_ROLE =
        keccak256("WARREN_STORAGE_ADMIN_ROLE");

    bytes32 internal constant JOSEPH_ROLE = keccak256("JOSEPH_ROLE");
    bytes32 internal constant JOSEPH_ADMIN_ROLE =
        keccak256("JOSEPH_ADMIN_ROLE");

    bytes32 internal constant MILTON_PUBLICATION_FEE_TRANSFERER_ROLE =
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ROLE");
    bytes32 internal constant MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE =
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE");

    constructor(address root) {
        _setupRole(ADMIN_ROLE, root);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        _setRoleAdmin(ROLES_INFO_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ROLES_INFO_ROLE, ROLES_INFO_ADMIN_ROLE);

        _setRoleAdmin(IPOR_ASSETS_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(IPOR_ASSETS_ROLE, IPOR_ASSETS_ADMIN_ROLE);

        _setRoleAdmin(MILTON_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MILTON_ROLE, MILTON_ADMIN_ROLE);

        _setRoleAdmin(MILTON_STORAGE_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MILTON_STORAGE_ROLE, MILTON_STORAGE_ADMIN_ROLE);

        _setRoleAdmin(MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            MILTON_LP_UTILIZATION_STRATEGY_ROLE,
            MILTON_LP_UTILIZATION_STRATEGY_ADMIN_ROLE
        );

        _setRoleAdmin(MILTON_SPREAD_STRATEGY_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            MILTON_SPREAD_STRATEGY_ROLE,
            MILTON_SPREAD_STRATEGY_ADMIN_ROLE
        );

        _setRoleAdmin(IPOR_ASSET_CONFIGURATION_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            IPOR_ASSET_CONFIGURATION_ROLE,
            IPOR_ASSET_CONFIGURATION_ADMIN_ROLE
        );

        _setRoleAdmin(WARREN_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(WARREN_ROLE, WARREN_ADMIN_ROLE);

        _setRoleAdmin(WARREN_STORAGE_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(WARREN_STORAGE_ROLE, WARREN_STORAGE_ADMIN_ROLE);

        _setRoleAdmin(JOSEPH_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(JOSEPH_ROLE, JOSEPH_ADMIN_ROLE);

        _setRoleAdmin(MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            MILTON_PUBLICATION_FEE_TRANSFERER_ROLE,
            MILTON_PUBLICATION_FEE_TRANSFERER_ADMIN_ROLE
        );
    }
}
