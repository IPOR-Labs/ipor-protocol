// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

/// @title Errors which occur inside Milton's method execution.
library MiltonErrors {
    // 300-399-milton
    /// @notice Liquidity Pool balance is equal 0.
    string public constant LIQUIDITY_POOL_IS_EMPTY = "IPOR_300";

    /// @notice Liquidity Pool balance is too low, should be equal or higher than 0.
    string public constant LIQUIDITY_POOL_AMOUNT_TOO_LOW = "IPOR_301";

    /// @notice Liquidity Pool Utilization exceeded. Liquidity Pool utilization is higher than configured in Milton maximum liquidity pool utilization.
    string public constant LP_UTILIZATION_EXCEEDED = "IPOR_302";

    /// @notice Liquidity Pool Utilization Per Leg exceeded. Liquidity Pool utilization per leg is higher than configured in Milton maximu liquidity pool utilization per leg.
    string public constant LP_UTILIZATION_PER_LEG_EXCEEDED = "IPOR_303";

    /// @notice Swap id used in input has incorrect value (like 0) or not exists.
    string public constant INCORRECT_SWAP_ID = "IPOR_304";

    /// @notice Swap has incorrect status.
    string public constant INCORRECT_SWAP_STATUS = "IPOR_305";

    /// @notice Leverage given as a parameter when opening swap is lower than configured in Milton minimum leverage.
    string public constant LEVERAGE_TOO_LOW = "IPOR_306";

    /// @notice Leverage given as a parameter when opening swap is higher than configured in Milton maxumum leverage.
    string public constant LEVERAGE_TOO_HIGH = "IPOR_307";

    /// @notice Total amount given as a parameter when opening swap is too low. Cannot be equal zero.
    string public constant TOTAL_AMOUNT_TOO_LOW = "IPOR_308";

    /// @notice Total amount given as a parameter when opening swap is lower than sum of liquidation deposit amount and ipor publication fee.
    string public constant TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_309";

    /// @notice Amount of collateral used to open swap is higher than configured in Milton max swap collateral amount
    string public constant COLLATERAL_AMOUNT_TOO_HIGH = "IPOR_310";

    /// @notice Acceptable fixed interest rate defined by traded exceeded.
    string public constant ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED = "IPOR_311";

    /// @notice Swap Notional Amount is higher than Total Notional for specific leg.
    string public constant SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = "IPOR_312";

    /// @notice Number of swaps per leg which are going to be liquidated is too high, is higher than configured in Milton liquidation leg limit.
    string public constant LIQUIDATION_LEG_LIMIT_EXCEEDED = "IPOR_313";

    /// @notice Sum of SOAP and Liquidity Pool Balance is lower than zero.
    /// @dev SOAP can be negative, Sum of SOAP and Liquidity Pool Balance can be negative, but this is undesirable.
    string public constant SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW = "IPOR_314";

    /// @notice Calculation timestamp is earlier than last SOAP rebalance timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP = "IPOR_315";

    /// @notice Calculation timestamp is lower than  Swap's open timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_316";

    /// @notice Closing timestamp is lower than Swap's open timestamp.
    string public constant CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_317";

    /// @notice Swap cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen where Liquidity Pool is insolvent.
    string public constant CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW = "IPOR_318";

    /// @notice Swap cannot be closed because sender is not an owner of derivative and derivative maturity not achieved.
    string public constant CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY = "IPOR_319";

    /// @notice Interest from Strategy is below zero.
    string public constant INTEREST_FROM_STRATEGY_BELOW_ZERO = "IPOR_320";

    /// @notice Accrued Liquidity Pool is equal zero.
    string public constant LIQUIDITY_POOL_ACCRUED_IS_EQUAL_ZERO = "IPOR_321";

    /// @notice During spread calculation - Exponential Weighted Moving Variance cannot be higher than 1.
    string public constant SPREAD_EMVAR_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_322";

    /// @notice During spread calculation - Alpha param cannot be higher than 1.
    string public constant SPREAD_ALPHA_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_323";

    /// @notice IPOR publication fee balance is too low.
    string public constant PUBLICATION_FEE_BALANCE_IS_TOO_LOW = "IPOR_324";

    /// @notice The caller must be the Joseph (Smart Contract responsible for managing Milton's tokens and balances).
    string public constant CALLER_NOT_JOSEPH = "IPOR_325";

    /// @notice Deposit amount is too low.
    string public constant DEPOSIT_AMOUNT_IS_TOO_LOW = "IPOR_326";

    /// @notice Vault balance is lower than deposit value.
    string public constant VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE = "IPOR_327";

    /// @notice Treasury balance is too low.
    string public constant TREASURY_BALANCE_IS_TOO_LOW = "IPOR_328";
}
