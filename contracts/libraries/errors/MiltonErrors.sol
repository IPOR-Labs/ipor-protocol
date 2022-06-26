// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

library MiltonErrors {
    // 300-399-milton
    //@notice Liquidity Pool balance is equal 0
    string public constant LIQUIDITY_POOL_IS_EMPTY = "IPOR_300";

    string public constant LIQUIDITY_POOL_AMOUNT_TOO_LOW = "IPOR_301";

    string public constant LP_UTILIZATION_EXCEEDED = "IPOR_302";

    //@notice Liquidity Pool Utilization Per Leg exceeded
    string public constant LP_UTILIZATION_PER_LEG_EXCEEDED = "IPOR_303";

    //@notice Swap id used in input has incorrect value (like 0) or not exists
    string public constant INCORRECT_SWAP_ID = "IPOR_304";

    //@notice Swap has incorrect status
    string public constant INCORRECT_SWAP_STATUS = "IPOR_305";

    //@notice Deposit amount to notional amount leverage is too low
    string public constant LEVERAGE_TOO_LOW = "IPOR_306";

    string public constant LEVERAGE_TOO_HIGH = "IPOR_307";

    //@notice Total Amount when opening swap is too low
    string public constant TOTAL_AMOUNT_TOO_LOW = "IPOR_308";

    //@notice Total Amount when opening swap is lower than fee
    string public constant TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_309";

    //@notice Amount of collateral used to open swap exceeds limit
    string public constant COLLATERAL_AMOUNT_TOO_HIGH = "IPOR_310";

    //@notice Acceptable fixed interest rate exceeded.
    string public constant ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED = "IPOR_311";

    //@notice Swap Notional Amount is higher than Total Notional
    string public constant SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = "IPOR_312";

    /// @notice Number of swaps per leg which are going to be liquidated is too high.
    string public constant LIQUIDATION_LEG_LIMIT_EXCEEDED = "IPOR_313";

    //@notice Summary SOAP and Miltion Liquidity Pool Balance is less than zero. SOAP can be negative, Sum of SOAM and Liquidity Pool Balance can be negative, but this is undesirable
    string public constant SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW = "IPOR_314";

    string public constant CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP = "IPOR_315";

    string public constant CALC_TIMESTAMP_HIGHER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_316";

    string public constant CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_317";

    //@notice Swap cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen. Liquidity Pool is insolvent
    string public constant CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW = "IPOR_318";

    //@notice Swap cannot be closed because sender is not an owner of derivative and derivative maturity not achieved
    string public constant CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY = "IPOR_319";

    string public constant INTREST_FROM_STRATEGY_BELOW_ZERO = "IPOR_320";

    //@notice Liquiditiy
    string public constant SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO = "IPOR_321";

    //@notice During spread calculation - Exponential Weighted Moving Variance cannot be higher than 1
    string public constant SPREAD_EMVAR_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_322";

    //@notice During spread calculation - Alpha param which  cannot be higher than 1
    string public constant SPREAD_ALPHA_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_323";

    //@notice Opening Fee Balance is too low
    string public constant PUBLICATION_FEE_BALANCE_TOO_LOW = "IPOR_324";

    //@notice The caller must be the Ipor Liquidity Pool - Joseph
    string public constant CALLER_NOT_JOSEPH = "IPOR_325";

    //@notice Liquidity provider can deposit amount of stable, errors appeared when amount is to low
    string public constant DEPOSIT_AMOUNT_TOO_LOW = "IPOR_326";

    string public constant VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE = "IPOR_327";

    string public constant TREASURE_BALANCE_TOO_LOW = "IPOR_328";
}
