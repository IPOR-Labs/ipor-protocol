// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

//TODO: organize per smart contract (consider this) use internal, reorder in more intuitive way
// 000-199 - general codes
// 200-299- warren
// 300-399-milton
// 400-499-joseph
// 500-599-stanley
library IporErrors {
    // 000-199 - general codes

    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_000";

    //@notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_001";

    //@notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_002";

    //only milton can have access to function
    string public constant CALLER_NOT_MILTON = "IPOR_003";

    //TODO: add test for this
    //@notice Asset has too low decimals
    string public constant ASSET_DECIMALS_TOO_LOW = "IPOR_004";

    //@notice Trader doesnt have enought tokens to execute transaction
    string public constant ASSET_BALANCE_OF_TOO_LOW = "IPOR_005";

    //@notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_006";

    //@notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_007";

    //TODO: better name for this error..
    string public constant VALUE_SHOULD_BE_GRATER_THEN_ZERO = "IPOR_008";

    // 200-299- warren
    //@notice Cannot add new asset to asset list, because already exists
    string public constant WARREN_CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS = "IPOR_200";

    //@notice The caller must be the Warren updater
    string public constant WARREN_CALLER_NOT_UPDATER = "IPOR_201";

    //@notice Asset address not supported
    //@dev Address is not supported when quasiIbtPrice < Constants.WAD_YEAR_IN_SECONDS.
    //When quasiIbtPrice is lower than WAD_YEAR_IN_SECONDS (ibtPrice lower than 1), then we assume that asset is not supported.
    string public constant WARREN_ASSET_NOT_SUPPORTED = "IPOR_202";

    //@notice Actual IPOR Index timestamp is higher than accrue timestamp
    string public constant WARREN_INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP = "IPOR_203";

    // 300-399-milton

    string public constant MILTON_TREASURE_BALANCE_TOO_LOW = "IPOR_300";

    //@notice Summary SOAP and Miltion Liquidity Pool Balance is less than zero. SOAP can be negative, Sum of SOAM and Liquidity Pool Balance can be negative, but this is undesirable
    string public constant MILTON_SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW = "IPOR_301";

    //@notice Total Amount when opening swap is lower than fee
    string public constant MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_302";

    //@notice Total Amount when opening swap is too low
    string public constant MILTON_TOTAL_AMOUNT_TOO_LOW = "IPOR_303";

    //@notice Opening Fee Balance is too low
    string public constant MILTON_PUBLICATION_FEE_BALANCE_TOO_LOW = "IPOR_304";

    //@notice Maximum Slippage is too high
    string public constant TOLERATED_QUOTE_VALUE_EXCEEDED = "IPOR_305";

    //@notice Amount of collateral used to open swap exceeds limit
    string public constant MILTON_COLLATERAL_AMOUNT_TOO_HIGH = "IPOR_306";

    //@notice Deposit amount to notional amount collateralization factor is too low
    string public constant MILTON_COLLATERALIZATION_FACTOR_TOO_LOW = "IPOR_307";

    //@notice Swap cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen. Liquidity Pool is insolvent
    string public constant MILTON_CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW = "IPOR_308";

    //@notice Swap cannot be closed because sender is not an owner of derivative and derivative maturity not achieved
    string public constant MILTON_CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY =
        "IPOR_309";

    //@notice Swap Notional Amount is higher than Total Notional
    string public constant MILTON_SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = "IPOR_310";

    //@notice Swap id used in input has incorrect value (like 0) or not exists
    string public constant MILTON_INCORRECT_SWAP_ID = "IPOR_311";

    //@notice Swap has incorrect status
    string public constant MILTON_INCORRECT_DERIVATIVE_STATUS = "IPOR_312";

    string public constant MILTON_COLLATERALIZATION_FACTOR_TOO_HIGH = "IPOR_313";

    //@notice Liquidity Pool Utilization Per Leg exceeded
    string public constant MILTON_LP_UTILIZATION_PER_LEG_EXCEEDED = "IPOR_314";

    //@notice Liquidity provider cannot withdraw because liquidity pool is too low
    string public constant MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW = "IPOR_315";

    //@notice Liquidity Pool balance is equal 0
    string public constant MILTON_LIQUIDITY_POOL_IS_EMPTY = "IPOR_316";

    //@notice The caller must be the Ipor Liquidity Pool - Joseph
    string public constant MILTON_CALLER_NOT_JOSEPH = "IPOR_317";

    //@notice Liquiditiy
    string public constant MILTON_SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO = "IPOR_318";

    //@notice During spread calculation - Exponential Weighted Moving Variance cannot be higher than 1
    string public constant MILTON_SPREAD_EMVAR_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_319";

    //@notice During spread calculation - Alpha param which  cannot be higher than 1
    string public constant MILTON_SPREAD_ALPHA_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_320";

    string public constant MILTON_CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_321";

    string public constant MILTON_CALC_TIMESTAMP_HIGHER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_322";

    string public constant MILTON_CALC_TIMESTAMP_LOWER_THAN_SOAP_INDICATOR_REBALANCE_TIMESTAMP =
        "IPOR_323";

    //@notice Liquidity provider can deposit amount of stable, errors appeared when amount is to low
    string public constant MILTON_DEPOSIT_AMOUNT_TOO_LOW = "IPOR_324";

    //@notcie Swap cannot be closed because liquidation deposit balance is to low to pay sender for liquidation
    string public constant MILTON_CANNOT_CLOSE_SWAP_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW =
        "IPOR_325";

    string public constant MILTON_LP_UTILIZATION_EXCEEDED = "IPOR_326";

    //@notice ibtPrice has to be higher than 0
    string public constant MILTON_IBT_PRICE_CANNOT_BE_ZERO = "IPOR_327";

    //TODO: try to add test for this
    //@notice Spread value cannot be higher than Ipor Index Value for particular asset
    string public constant MILTON_SPREAD_PREMIUMS_CANNOT_BE_HIGHER_THAN_IPOR_INDEX = "IPOR_328";

    // @notice Milton Vault Balance in Asset Management is lower than last saved vaultBalance in Milton
    string public constant MILTON_IPOR_VAULT_BALANCE_TOO_LOW = "IPOR_329";

    string public constant MILTON_SWAP_IDS_ARRAY_IS_EMPTY = "IPOR_330";

    // 400-499-joseph
    //TODO: add test for this code
    //@notice Incorrect Treasure Treasurer Address
    string public constant JOSEPH_INCORRECT_TREASURE_TREASURER = "IPOR_400";

    string public constant JOSEPH_CALLER_NOT_TREASURE_TRANSFERER = "IPOR_401";

    //@notice Charlie Treasurer address is incorrect
    string public constant JOSEPH_INCORRECT_CHARLIE_TREASURER = "IPOR_402";

    //@notice Sender is not a publication fee transferer, not match address defined in IporConfiguration in key MILTON_PUBLICATION_FEE_TRANSFERER
    string public constant JOSEPH_CALLER_NOT_PUBLICATION_FEE_TRANSFERER = "IPOR_403";

    string public constant STANLEY_BALANCE_IS_EMPTY = "IPOR_404";

    //@notice User cannot redeem underlying tokens because ipToken on his balance is too low
    string public constant JOSEPH_CANNOT_REDEEM_IP_TOKEN_TOO_LOW = "IPOR_405";

    string public constant JOSEPH_REDEEM_LP_UTILIZATION_EXCEEDED = "IPOR_406";

    //@notice IP Token Value which should be minted is too low
    string public constant JOSEPH_IP_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_407";

    //@notice Amount which should be burned is too low
    string public constant JOSEPH_IP_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_408";

    // 500-599-stanley
    string public constant TREASURY_COULD_NOT_BE_ZERO = "IPOR_500";

    //@notice amount should be > 0
    string public constant STANLEY_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_501";

    //@notice amount should be > 0
    string public constant STANLEY_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_502";

    string public constant STANLEY_ASSET_MISMATCH = "IPOR_503";

    // only stanley can have access to function
    string public constant STANLEY_CALLER_NOT_STANLEY = "IPOR_504";
}
