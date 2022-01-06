// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./AccessControlRevoke.sol";

abstract contract AccessControlMiltonSpreadConfiguration is
    AccessControlRevoke
{
    bytes32 internal constant _SPREAD_MAX_VALUE_ADMIN_ROLE =
        keccak256("SPREAD_MAX_VALUE_ADMIN_ROLE");
    bytes32 internal constant _SPREAD_MAX_VALUE_ROLE =
        keccak256("SPREAD_MAX_VALUE_ROLE");

    bytes32 internal constant _SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE =
        keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE");
    bytes32 internal constant _SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE =
        keccak256("SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE");

    bytes32 internal constant _SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE =
        keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE");
    bytes32 internal constant _SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE =
        keccak256("SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE");

    bytes32 internal constant _SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE =
        keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE");
    bytes32 internal constant _SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE =
        keccak256("SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE");

    bytes32
        internal constant _SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE =
        keccak256(
            "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE"
        );
    bytes32
        internal constant _SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE =
        keccak256(
            "SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE"
        );

    bytes32 internal constant _SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE =
        keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE");
    bytes32 internal constant _SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE =
        keccak256("SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE");

    bytes32 internal constant _SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE =
        keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE");
    bytes32 internal constant _SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE =
        keccak256("SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE");

    constructor(address root) {
        _setupRole(_ADMIN_ROLE, root);
        _setRoleAdmin(_ADMIN_ROLE, _ADMIN_ROLE);

        _setRoleAdmin(_ROLES_INFO_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_ROLES_INFO_ROLE, _ROLES_INFO_ADMIN_ROLE);

        _setRoleAdmin(_SPREAD_MAX_VALUE_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_SPREAD_MAX_VALUE_ROLE, _SPREAD_MAX_VALUE_ADMIN_ROLE);

        _setRoleAdmin(
            _SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE,
            _ADMIN_ROLE
        );
        _setRoleAdmin(
            _SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE,
            _SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE
        );

        _setRoleAdmin(
            _SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE,
            _ADMIN_ROLE
        );
        _setRoleAdmin(
            _SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE,
            _SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE
        );

        _setRoleAdmin(
            _SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE,
            _ADMIN_ROLE
        );
        _setRoleAdmin(
            _SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE,
            _SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE
        );

        _setRoleAdmin(
            _SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE,
            _ADMIN_ROLE
        );
        _setRoleAdmin(
            _SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE,
            _SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE
        );

        _setRoleAdmin(
            _SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE,
            _ADMIN_ROLE
        );
        _setRoleAdmin(
            _SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE,
            _SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE
        );

        _setRoleAdmin(
            _SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE,
            _ADMIN_ROLE
        );
        _setRoleAdmin(
            _SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE,
            _SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE
        );
    }
}
