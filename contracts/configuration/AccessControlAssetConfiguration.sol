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

    bytes32 internal constant _INCOME_TAX_PERCENTAGE_ADMIN_ROLE =
        keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE");
    bytes32 internal constant _INCOME_TAX_PERCENTAGE_ROLE =
        keccak256("INCOME_TAX_PERCENTAGE_ROLE");

    bytes32 internal constant _OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE =
        keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE");
    bytes32 internal constant _OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE =
        keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE");

    bytes32 internal constant _LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE =
        keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE");
    bytes32 internal constant _LIQUIDATION_DEPOSIT_AMOUNT_ROLE =
        keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ROLE");

    bytes32 internal constant _OPENING_FEE_PERCENTAGE_ADMIN_ROLE =
        keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE");
    bytes32 internal constant _OPENING_FEE_PERCENTAGE_ROLE =
        keccak256("OPENING_FEE_PERCENTAGE_ROLE");

    bytes32 internal constant _IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE =
        keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE");
    bytes32 internal constant _IPOR_PUBLICATION_FEE_AMOUNT_ROLE =
        keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE");

    bytes32 internal constant _LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE =
        keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE");

    bytes32 internal constant _LP_MAX_UTILIZATION_PERCENTAGE_ROLE =
        keccak256("LP_MAX_UTILIZATION_PERCENTAGE_ROLE");

    bytes32 internal constant _REDEEM_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE =
        keccak256("REDEEM_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE");

    bytes32 internal constant _REDEEM_MAX_UTILIZATION_PERCENTAGE_ROLE =
        keccak256("REDEEM_MAX_UTILIZATION_PERCENTAGE_ROLE");

    bytes32 internal constant _MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE =
        keccak256("MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE");
    bytes32 internal constant _MAX_POSITION_TOTAL_AMOUNT_ROLE =
        keccak256("MAX_POSITION_TOTAL_AMOUNT_ROLE");

    bytes32 internal constant _COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE =
        keccak256("COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE");
    bytes32 internal constant _COLLATERALIZATION_FACTOR_VALUE_ROLE =
        keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE");

    bytes32 internal constant _CHARLIE_TREASURER_ADMIN_ROLE =
        keccak256("CHARLIE_TREASURER_ADMIN_ROLE");
    bytes32 internal constant _CHARLIE_TREASURER_ROLE =
        keccak256("CHARLIE_TREASURER_ROLE");

    bytes32 internal constant _TREASURE_TREASURER_ADMIN_ROLE =
        keccak256("TREASURE_TREASURER_ADMIN_ROLE");
    bytes32 internal constant _TREASURE_TREASURER_ROLE =
        keccak256("TREASURE_TREASURER_ROLE");

    bytes32 internal constant _ASSET_MANAGEMENT_VAULT_ADMIN_ROLE =
        keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE");
    bytes32 internal constant _ASSET_MANAGEMENT_VAULT_ROLE =
        keccak256("ASSET_MANAGEMENT_VAULT_ROLE");

    bytes32 internal constant _DECAY_FACTOR_VALUE_ADMIN_ROLE =
        keccak256("DECAY_FACTOR_VALUE_ADMIN_ROLE");
    bytes32 internal constant _DECAY_FACTOR_VALUE_ROLE =
        keccak256("DECAY_FACTOR_VALUE_ROLE");

    constructor(address root) {
        _setupRole(_ADMIN_ROLE, root);
        _setRoleAdmin(_ADMIN_ROLE, _ADMIN_ROLE);

        _setRoleAdmin(_ROLES_INFO_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_ROLES_INFO_ROLE, _ROLES_INFO_ADMIN_ROLE);

        _setRoleAdmin(_MILTON_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_MILTON_ROLE, _MILTON_ADMIN_ROLE);

        _setRoleAdmin(_MILTON_STORAGE_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_MILTON_STORAGE_ROLE, _MILTON_STORAGE_ADMIN_ROLE);

        _setRoleAdmin(_JOSEPH_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_JOSEPH_ROLE, _JOSEPH_ADMIN_ROLE);

        _setRoleAdmin(_INCOME_TAX_PERCENTAGE_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _INCOME_TAX_PERCENTAGE_ROLE,
            _INCOME_TAX_PERCENTAGE_ADMIN_ROLE
        );

        _setRoleAdmin(
            _OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE,
            _ADMIN_ROLE
        );
        _setRoleAdmin(
            _OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE,
            _OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE
        );

        _setRoleAdmin(_LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _LIQUIDATION_DEPOSIT_AMOUNT_ROLE,
            _LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE
        );

        _setRoleAdmin(_OPENING_FEE_PERCENTAGE_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _OPENING_FEE_PERCENTAGE_ROLE,
            _OPENING_FEE_PERCENTAGE_ADMIN_ROLE
        );

        _setRoleAdmin(_IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _IPOR_PUBLICATION_FEE_AMOUNT_ROLE,
            _IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE
        );

        _setRoleAdmin(_LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _LP_MAX_UTILIZATION_PERCENTAGE_ROLE,
            _LP_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE
        );

        _setRoleAdmin(
            _REDEEM_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE,
            _ADMIN_ROLE
        );
        _setRoleAdmin(
            _REDEEM_MAX_UTILIZATION_PERCENTAGE_ROLE,
            _REDEEM_MAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE
        );

        _setRoleAdmin(_MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _MAX_POSITION_TOTAL_AMOUNT_ROLE,
            _MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE
        );

        _setRoleAdmin(_COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _COLLATERALIZATION_FACTOR_VALUE_ROLE,
            _COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE
        );

        _setRoleAdmin(_CHARLIE_TREASURER_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_CHARLIE_TREASURER_ROLE, _CHARLIE_TREASURER_ADMIN_ROLE);

        _setRoleAdmin(_TREASURE_TREASURER_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_TREASURE_TREASURER_ROLE, _TREASURE_TREASURER_ADMIN_ROLE);

        _setRoleAdmin(_ASSET_MANAGEMENT_VAULT_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(
            _ASSET_MANAGEMENT_VAULT_ROLE,
            _ASSET_MANAGEMENT_VAULT_ADMIN_ROLE
        );

        _setRoleAdmin(_DECAY_FACTOR_VALUE_ADMIN_ROLE, _ADMIN_ROLE);
        _setRoleAdmin(_DECAY_FACTOR_VALUE_ROLE, _DECAY_FACTOR_VALUE_ADMIN_ROLE);
    }
}
