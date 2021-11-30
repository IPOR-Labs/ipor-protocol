// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./AccessControlRevoke.sol";

abstract contract AccessControlAssetConfiguration is AccessControlRevoke {
    bytes32 internal constant INCOME_TAX_PERCENTAGE_ROLE =
        keccak256("INCOME_TAX_PERCENTAGE_ROLE");
    bytes32 internal constant INCOME_TAX_PERCENTAGE_ADMIN_ROLE =
        keccak256("INCOME_TAX_PERCENTAGE_ADMIN_ROLE");

    bytes32 internal constant OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE =
        keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE");
    bytes32 internal constant OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE =
        keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE");

    bytes32 internal constant LIQUIDATION_DEPOSIT_AMOUNT_ROLE =
        keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ROLE");
    bytes32 internal constant LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE =
        keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE");

    bytes32 internal constant OPENING_FEE_PERCENTAGE_ROLE =
        keccak256("OPENING_FEE_PERCENTAGE_ROLE");
    bytes32 internal constant OPENING_FEE_PERCENTAGE_ADMIN_ROLE =
        keccak256("OPENING_FEE_PERCENTAGE_ADMIN_ROLE");

    bytes32 internal constant IPOR_PUBLICATION_FEE_AMOUNT_ROLE =
        keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE");
    bytes32 internal constant IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE =
        keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE");

    bytes32 internal constant LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE =
        keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE");
    bytes32
        internal constant LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE =
        keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE");

    bytes32 internal constant MAX_POSITION_TOTAL_AMOUNT_ROLE =
        keccak256("MAX_POSITION_TOTAL_AMOUNT_ROLE");
    bytes32 internal constant MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE =
        keccak256("MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE");

    bytes32 internal constant SPREAD_PAY_FIXED_VALUE_ROLE =
        keccak256("SPREAD_PAY_FIXED_VALUE_ROLE");
    bytes32 internal constant SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE =
        keccak256("SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE");

    bytes32 internal constant SPREAD_REC_FIXED_VALUE_ROLE =
        keccak256("SPREAD_REC_FIXED_VALUE_ROLE");
    bytes32 internal constant SPREAD_REC_FIXED_VALUE_ADMIN_ROLE =
        keccak256("SPREAD_REC_FIXED_VALUE_ADMIN_ROLE");

    bytes32 internal constant COLLATERALIZATION_FACTOR_VALUE_ROLE =
        keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE");
    bytes32 internal constant COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE =
        keccak256("COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE");

    bytes32 internal constant CHARLIE_TREASURER_ROLE =
        keccak256("CHARLIE_TREASURER_ROLE");
    bytes32 internal constant CHARLIE_TREASURER_ADMIN_ROLE =
        keccak256("CHARLIE_TREASURER_ADMIN_ROLE");

    bytes32 internal constant TREASURE_TREASURER_ROLE =
        keccak256("TREASURE_TREASURER_ROLE");
    bytes32 internal constant TREASURE_TREASURER_ADMIN_ROLE =
        keccak256("TREASURE_TREASURER_ADMIN_ROLE");

    bytes32 internal constant ASSET_MANAGEMENT_VAULT_ROLE =
        keccak256("ASSET_MANAGEMENT_VAULT_ROLE");
    bytes32 internal constant ASSET_MANAGEMENT_VAULT_ADMIN_ROLE =
        keccak256("ASSET_MANAGEMENT_VAULT_ADMIN_ROLE");

    bytes32 internal constant DECAY_FACTOR_VALUE_ROLE =
        keccak256("DECAY_FACTOR_VALUE_ROLE");
    bytes32 internal constant DECAY_FACTOR_VALUE_ADMIN_ROLE =
        keccak256("DECAY_FACTOR_VALUE_ADMIN_ROLE");

    constructor(address root) {
        _setupRole(ADMIN_ROLE, root);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        _setRoleAdmin(ROLES_INFO_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ROLES_INFO_ROLE, ROLES_INFO_ADMIN_ROLE);

        _setRoleAdmin(INCOME_TAX_PERCENTAGE_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            INCOME_TAX_PERCENTAGE_ROLE,
            INCOME_TAX_PERCENTAGE_ADMIN_ROLE
        );

        _setRoleAdmin(
            OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE,
            ADMIN_ROLE
        );
        _setRoleAdmin(
            OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE,
            OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE
        );

        _setRoleAdmin(LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            LIQUIDATION_DEPOSIT_AMOUNT_ROLE,
            LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE
        );

        _setRoleAdmin(OPENING_FEE_PERCENTAGE_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            OPENING_FEE_PERCENTAGE_ROLE,
            OPENING_FEE_PERCENTAGE_ADMIN_ROLE
        );

        _setRoleAdmin(IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            IPOR_PUBLICATION_FEE_AMOUNT_ROLE,
            IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE
        );

        _setRoleAdmin(
            LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE,
            ADMIN_ROLE
        );
        _setRoleAdmin(
            LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE,
            LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE
        );

        _setRoleAdmin(MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            MAX_POSITION_TOTAL_AMOUNT_ROLE,
            MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE
        );

        _setRoleAdmin(SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            SPREAD_PAY_FIXED_VALUE_ROLE,
            SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE
        );

        _setRoleAdmin(SPREAD_REC_FIXED_VALUE_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            SPREAD_REC_FIXED_VALUE_ROLE,
            SPREAD_REC_FIXED_VALUE_ADMIN_ROLE
        );

        _setRoleAdmin(COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            COLLATERALIZATION_FACTOR_VALUE_ROLE,
            COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE
        );

        _setRoleAdmin(CHARLIE_TREASURER_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CHARLIE_TREASURER_ROLE, CHARLIE_TREASURER_ADMIN_ROLE);

        _setRoleAdmin(TREASURE_TREASURER_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(TREASURE_TREASURER_ROLE, TREASURE_TREASURER_ADMIN_ROLE);

        _setRoleAdmin(ASSET_MANAGEMENT_VAULT_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(
            ASSET_MANAGEMENT_VAULT_ROLE,
            ASSET_MANAGEMENT_VAULT_ADMIN_ROLE
        );

        _setRoleAdmin(DECAY_FACTOR_VALUE_ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(DECAY_FACTOR_VALUE_ROLE, DECAY_FACTOR_VALUE_ADMIN_ROLE);
    }
}
