// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library Errors {
    //@notice The caller must be the Milton smart contract
    string public constant MILTON_CALLER_NOT_MILTON = "IPOR_1";

    //@notice The caller must be the Warren updater
    string public constant WARREN_CALLER_NOT_WARREN_UPDATER = "IPOR_2";

    //@notice Deposit Amount when creating derivative position is lower than fee
    string public constant MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_3";

    //@notice Deposit Amount when creating derivative position is too low
    string public constant MILTON_TOTAL_AMOUNT_TOO_LOW = "IPOR_4";

    //@notice Maximum Slippage is too low
    string public constant MILTON_MAXIMUM_SLIPPAGE_TOO_LOW = "IPOR_5";

    //@notice Liquidity Pool for given asset symbol not exists
    string public constant MILTON_LIQUIDITY_POOL_NOT_EXISTS = "IPOR_7";

    //@notice Derivative direction not exists
    string public constant MILTON_DERIVATIVE_DIRECTION_NOT_EXISTS = "IPOR_8";

    //@notice Maximum Slippage is too high
    string public constant MILTON_MAXIMUM_SLIPPAGE_TOO_HIGH = "IPOR_9";

    //@notice Deposit Amount when creating derivative position is too high
    string public constant MILTON_TOTAL_AMOUNT_TOO_HIGH = "IPOR_10";

    //@notice Deposit amount to notional amount collateralization factor is too low
    string public constant MILTON_COLLATERALIZATION_FACTOR_TOO_LOW = "IPOR_12";

    //@notice Trader doesnt have enought tokens to execute transaction
    string public constant MILTON_ASSET_BALANCE_OF_TOO_LOW = "IPOR_13";

    //@notice Derivative cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen. Liquidity Pool is insolvent
    string
        public constant MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW =
        "IPOR_14";

    //@notcie Derivative cannot be closed because liquidation deposit balance is to low to pay sender for liquidation
    string
        public constant MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW =
        "IPOR_15";

    //@notice Derivative cannot be closed because sender is not an owner of derivative and derivative maturity not achieved
    string
        public constant MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY =
        "IPOR_16";

    //@notice Derivative should be in ACTIVE state
    string public constant MILTON_DERIVATIVE_IS_INACTIVE = "IPOR_17";

    //@notice Input arrays which should have the same length - mismatch
    string public constant WARREN_INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_18";

    //@notice Derivative Notional Amount is higher than Total Notional
    string
        public constant MILTON_DERIVATIVE_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL =
        "IPOR_19";

    //@notice Calculation timestamp is higher than derivative open timestamp, but should be lower or equal
    string
        public constant MILTON_CALC_TIMESTAMP_HIGHER_THAN_DERIVATIVE_OPEN_TIMESTAMP =
        "IPOR_20";

    //@notice Calculation timestamp is lower than last rebalance in soap indicator timestamp, but should be higher or equal
    string
        public constant MILTON_CALC_TIMESTAMP_LOWER_THAN_SOAP_INDICATOR_REBALANCE_TIMESTAMP =
        "IPOR_21";

    //@notice Derivative id used in input has incorrect value (like 0) or not exists
    string public constant MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID =
        "IPOR_22";

    //@notice Derivative has incorrect status
    string public constant MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS =
        "IPOR_23";

    //@notice General error, max value exceeded
    string public constant MILTON_CONFIG_MAX_VALUE_EXCEEDED = "IPOR_24";

    //@notice Derivative closing timestamp cannot be before derivative starting timestamp
    string
        public constant MILTON_CLOSING_TIMESTAMP_LOWER_THAN_DERIVATIVE_OPEN_TIMESTAMP =
        "IPOR_25";

    //@notice ibtPrice has to be higher than 0
    string public constant MILTON_IBT_PRICE_CANNOT_BE_ZERO = "IPOR_26";

    //@notice Actual IPOR Index timestamp is higher than accrue timestamp
    string public constant WARREN_INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP =
        "IPOR_27";

    //@notice Opening Fee Balance is too low
    string public constant MILTON_NOT_ENOUGH_OPENING_FEE_BALANCE = "IPOR_28";

    //@notice Charlie Treasurer address is incorrect
    string public constant MILTON_INCORRECT_CHARLIE_TREASURER_ADDRESS =
        "IPOR_29";

    //@notice Amount is too low to transfer
    string public constant MILTON_NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_30";

    //@notice Sender is not a publication fee transferer, not match address defined in IporConfiguration in key MILTON_PUBLICATION_FEE_TRANSFERER
    string public constant MILTON_CALLER_NOT_MILTON_PUBLICATION_FEE_TRANSFERER =
        "IPOR_31";

    //@notice Incorrect IPOR Configuration address
    string public constant MILTON_INCORRECT_CONFIGURATION_ADDRESS = "IPOR_32";

    //@notice Incorrect IPOR Configuration address
    string public constant MILTON_INCORRECT_ADRESSES_MANAGER_ADDRESS =
        "IPOR_33";

    string public constant MILTON_COLLATERALIZATION_FACTOR_TOO_HIGH = "IPOR_34";

    //@notice Liquidity Pool Utilisation exceeded, implementation interface IMiltonLPUtilizationStrategy calculate utilisation, IporAssetConfiguration.liquidityPoolMaxUtilizationPercentage define configured max utilisation rate
    string public constant MILTON_LIQUIDITY_POOL_UTILISATION_EXCEEDED =
        "IPOR_35";

    //@notice Updater address is wrong
    string public constant WARREN_WRONG_UPDATER_ADDRESS = "IPOR_36";

    //@notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_37";

    //@notice Cannot add new asset to asset list, because already exists
    string public constant MILTON_CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS =
        "IPOR_38";

    //@notice Asset address not supported
    string public constant MILTON_ASSET_ADDRESS_NOT_SUPPORTED = "IPOR_39";

    //@notice Amount which should be minted is too low
    string public constant MILTON_IPOT_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_40";

    //@notice Liquidity provider can deposit amount of stable, errors appeared when amount is to low
    string public constant MILTON_DEPOSIT_AMOUNT_TOO_LOW = "IPOR_41";

    //@notice User cannot redeem underlying tokens because ipToken on his balance is too low
    string public constant MILTON_CANNOT_REDEEM_IP_TOKEN_TOO_LOW = "IPOR_42";

    //@notice Liquidity provider cannot withdraw because liquidity pool is too low
    string public constant MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW =
        "IPOR_43";

    //@notice Amount which should be burned is too low
    string public constant MILTON_IPOT_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_44";

    //@notice Liquidity Pool balance is equal 0
    string public constant MILTON_LIQUIDITY_POOL_IS_EMPTY = "IPOR_45";

    //@notice The caller must be the Ipor Liquidity Pool - Joseph
    string public constant MILTON_CALLER_NOT_JOSEPH = "IPOR_46";

    //@notice Summary SOAP and Miltion Liquidity Pool Balance is less than zero. SOAP can be negative, Sum of SOAM and Liquidity Pool Balance can be negative, but this is undesirable
    string public constant JOSEPH_SOAP_AND_MILTON_LP_BALANCE_SUM_IS_TOO_LOW =
        "IPOR_47";

    //@notice Decay factor cannot be higher than 1 * D18
    string public constant CONFIG_DECAY_FACTOR_TOO_HIGH = "IPOR_48";

	//TODO: use this number for something else
    // string public constant CONFIG_INCORRECT_MULTIPLICATOR = "IPOR_49";

    //@notice ADMIN_ROLE can be revoked only by different user with ADMIN_ROLE
    string public constant CONFIG_REVOKE_ADMIN_ROLE_NOT_ALLOWED = "IPOR_50";

    //TODO: add test for this code
    //@notice Liquidity Pool Max Utilization Percentage cannot be higher than 1 * D18
    string
        public constant CONFIG_LIQUIDITY_POOL_MAX_UTILIZATION_PERCENTAGE_TOO_HIGH =
        "IPOR_51";

    //TODO: add test for this
    //@notice Asset has too low decimals
    string public constant CONFIG_ASSET_DECIMALS_TOO_LOW = "IPOR_52";

    //TODO: try to add test for this
    //@notic Spread value cannot be higher than Ipor Index Value for particular asset
    string public constant MILTON_SPREAD_CANNOT_BE_HIGHER_THAN_IPOR_INDEX =
        "IPOR_53";
}
