// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

library Errors {
    string public constant MILTON_CALLER_NOT_MILTON = 'IPOR_1'; // 'The caller must be the Milton smart contract'
    string public constant WARREN_CALLER_NOT_WARREN_UPDATER = 'IPOR_2'; // 'The caller must be the Warren updater'
    string public constant MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE = 'IPOR_3'; // 'Deposit Amount when creating derivative position is lower than fee'
    string public constant MILTON_TOTAL_AMOUNT_TOO_LOW = 'IPOR_4'; // 'Deposit Amount when creating derivative position is too low'
    string public constant MILTON_MAXIMUM_SLIPPAGE_TOO_LOW = 'IPOR_5'; // 'Maximum Slippage is too low'
    string public constant MILTON_LIQUIDITY_POOL_NOT_EXISTS = 'IPOR_7'; // 'Liquidity Pool for given asset symbol not exists'
    string public constant MILTON_DERIVATIVE_DIRECTION_NOT_EXISTS = 'IPOR_8'; // 'Derivative direction not exists'
    string public constant MILTON_MAXIMUM_SLIPPAGE_TOO_HIGH = 'IPOR_9'; // 'Maximum Slippage is too high'
    string public constant MILTON_TOTAL_AMOUNT_TOO_HIGH = 'IPOR_10'; // 'Deposit Amount when creating derivative position is too high'
    string public constant MILTON_COLLATERALIZATION_TOO_LOW = 'IPOR_12'; //'Deposit amount to notional amount collateralization is too low'
    string public constant MILTON_ASSET_BALANCE_OF_TOO_LOW = 'IPOR_13'; //'Trader doesnt have enought tokens to execute transaction'
    string public constant MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW = 'IPOR_14'; //'Derivative cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen. Liquidity Pool is insolvent'
    string public constant MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW = 'IPOR_15'; //'Derivative cannot be closed because liquidation deposit balance is to low to pay sender for liquidation.'
    string public constant MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY = 'IPOR_16'; //'Derivative cannot be closed because sender is not an owner of derivative and derivative maturity not achieved'
    string public constant MILTON_DERIVATIVE_IS_INACTIVE = 'IPOR_17'; //'Derivative should be in ACTIVE state'
    string public constant WARREN_INPUT_ARRAYS_LENGTH_MISMATCH = 'IPOR_18'; //'Input arrays which should have the same length - mismatch.'
    string public constant MILTON_DERIVATIVE_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = 'IPOR_19'; //'Derivative Notional Amount is higher than Total Notional
    string public constant MILTON_CALC_TIMESTAMP_HIGHER_THAN_DERIVATIVE_OPEN_TIMESTAMP = 'IPOR_20'; //'Calculation timestamp is higher than derivative open timestamp, but should be lower or equal`
    string public constant MILTON_CALC_TIMESTAMP_LOWER_THAN_SOAP_INDICATOR_REBALANCE_TIMESTAMP = 'IPOR_21'; //'Calculation timestamp is lower than last rebalance in soap indicator timestamp, but should be higher or equal`
    string public constant MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID = 'IPOR_22'; //derivative id used in input has incorrect value (like 0) or not exists
    string public constant MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS = 'IPOR_23'; //derivative has incorrect status
    string public constant MILTON_CONFIG_MAX_VALUE_EXCEEDED = 'IPOR_24'; //general error, max value exceeded
    string public constant MILTON_CLOSING_TIMESTAMP_LOWER_THAN_DERIVATIVE_OPEN_TIMESTAMP = 'IPOR_25'; //'Derivative closing timestamp cannot be before derivative starting timestamp`
    string public constant MILTON_IBT_PRICE_CANNOT_BE_ZERO = 'IPOR_26'; //'ibtPrice has to be higher than 0`
    string public constant WARREN_INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP = 'IPOR_27'; //Actual IPOR Index timestamp is higher than accrue timestamp
    string public constant MILTON_NOT_ENOUGH_OPENING_FEE_BALANCE = 'IPOR_28'; // Opening Fee Balance is too low`
    string public constant MILTON_INCORRECT_CHARLIE_TREASURER_ADDRESS = 'IPOR_29'; // Charlie Treasurer address is incorrect
    string public constant MILTON_NOT_ENOUGH_AMOUNT_TO_TRANSFER = 'IPOR_30'; // Amount is too low to transfer
    string public constant MILTON_CALLER_NOT_PUBLICATION_FEE_TRANSFERER = 'IPOR_31'; // Sender is not a publication fee transferer, not match address defined in IporAddressesManager in key PUBLICATION_FEE_TRANSFERER
    string public constant MILTON_INCORRECT_CONFIGURATION_ADDRESS = 'IPOR_32'; // Incorrect Milton Configuration address
    string public constant MILTON_INCORRECT_ADRESSES_MANAGER_ADDRESS = 'IPOR_33'; // Incorrect Milton Configuration address
    string public constant MILTON_COLLATERALIZATION_TOO_HIGH = 'IPOR_34';



}