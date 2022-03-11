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

    //@notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    //@notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    //TODO: add test for this
    //@notice Asset has too low decimals
    string public constant ASSET_DECIMALS_TOO_LOW = "IPOR_002";

    //@notice Trader doesnt have enought tokens to execute transaction
    string public constant ASSET_BALANCE_TOO_LOW = "IPOR_003";

    //TODO: better name for this error..
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    //@notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    //@notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    //only milton can have access to function
    string public constant CALLER_NOT_MILTON = "IPOR_008";

    // 200-299- warren
    //@notice Asset address not supported
    //@dev Address is not supported when quasiIbtPrice < Constants.WAD_YEAR_IN_SECONDS.
    //When quasiIbtPrice is lower than WAD_YEAR_IN_SECONDS (ibtPrice lower than 1), then we assume that asset is not supported.
    string public constant WARREN_ASSET_NOT_SUPPORTED = "IPOR_200";

    //@notice Cannot add new asset to asset list, because already exists
    string public constant WARREN_CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS = "IPOR_201";

    //@notice The caller must be the Warren updater
    string public constant WARREN_CALLER_NOT_UPDATER = "IPOR_202";

    //@notice Actual IPOR Index timestamp is higher than accrue timestamp
    string public constant WARREN_INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP = "IPOR_203";

    // 300-399-milton

    //@notice Liquidity Pool balance is equal 0
    string public constant MILTON_LIQUIDITY_POOL_IS_EMPTY = "IPOR_300";

    string public constant MILTON_LP_UTILIZATION_EXCEEDED = "IPOR_301";

    //@notice Liquidity Pool Utilization Per Leg exceeded
    string public constant MILTON_LP_UTILIZATION_PER_LEG_EXCEEDED = "IPOR_302";

    //@notice Swap id used in input has incorrect value (like 0) or not exists
    string public constant MILTON_INCORRECT_SWAP_ID = "IPOR_303";

    //@notice Swap has incorrect status
    string public constant MILTON_INCORRECT_SWAP_STATUS = "IPOR_304";

    //@notice Deposit amount to notional amount collateralization factor is too low
    string public constant MILTON_COLLATERALIZATION_FACTOR_TOO_LOW = "IPOR_305";

    string public constant MILTON_COLLATERALIZATION_FACTOR_TOO_HIGH = "IPOR_306";

    //@notice Total Amount when opening swap is too low
    string public constant MILTON_TOTAL_AMOUNT_TOO_LOW = "IPOR_307";

    //@notice Total Amount when opening swap is lower than fee
    string public constant MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_308";

    //@notice Amount of collateral used to open swap exceeds limit
    string public constant MILTON_COLLATERAL_AMOUNT_TOO_HIGH = "IPOR_309";

    //@notice ibtPrice has to be higher than 0
    string public constant MILTON_IBT_PRICE_CANNOT_BE_ZERO = "IPOR_310";

    //@notice Maximum Slippage is too high
    string public constant TOLERATED_QUOTE_VALUE_EXCEEDED = "IPOR_311";

    //@notice Swap Notional Amount is higher than Total Notional
    string public constant MILTON_SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = "IPOR_312";

    //@notice Summary SOAP and Miltion Liquidity Pool Balance is less than zero. SOAP can be negative, Sum of SOAM and Liquidity Pool Balance can be negative, but this is undesirable
    string public constant MILTON_SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW = "IPOR_313";

    string public constant MILTON_SWAP_IDS_ARRAY_IS_EMPTY = "IPOR_314";

    string public constant MILTON_CALC_TIMESTAMP_LTHAN_SI_REBALANCE_TIMESTAMP = "IPOR_315";
    string public constant MILTON_CALC_TIMESTAMP_HIGHER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_316";

    string public constant MILTON_CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_317";

    //@notice Swap cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen. Liquidity Pool is insolvent
    string public constant MILTON_CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW = "IPOR_318";

    //@notice Swap cannot be closed because sender is not an owner of derivative and derivative maturity not achieved
    string public constant MILTON_CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY =
        "IPOR_319";

    //@notcie Swap cannot be closed because liquidation deposit balance is to low to pay sender for liquidation
    string public constant MILTON_CANNOT_CLOSE_SWAP_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW =
        "IPOR_320";

    //@notice Liquiditiy
    string public constant MILTON_SPREAD_LP_PLUS_OPENING_FEE_IS_EQUAL_ZERO = "IPOR_321";

    //@notice During spread calculation - Exponential Weighted Moving Variance cannot be higher than 1
    string public constant MILTON_SPREAD_EMVAR_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_322";

    //@notice During spread calculation - Alpha param which  cannot be higher than 1
    string public constant MILTON_SPREAD_ALPHA_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_323";

    //TODO: try to add test for this
    //@notice Spread value cannot be higher than Ipor Index Value for particular asset
    string public constant MILTON_SPREAD_PREMIUMS_CANNOT_BE_HIGHER_THAN_IPOR_INDEX = "IPOR_324";

    //@notice The caller must be the Ipor Liquidity Pool - Joseph
    string public constant MILTON_CALLER_NOT_JOSEPH = "IPOR_325";

    //@notice Liquidity provider can deposit amount of stable, errors appeared when amount is to low
    string public constant MILTON_DEPOSIT_AMOUNT_TOO_LOW = "IPOR_326";

    //@notice Liquidity provider cannot withdraw because liquidity pool is too low
    string public constant MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW = "IPOR_327";

    // @notice Milton Vault Balance in Asset Management is lower than last saved vaultBalance in Milton
    string public constant MILTON_IPOR_VAULT_BALANCE_TOO_LOW = "IPOR_328";

    string public constant MILTON_TREASURE_BALANCE_TOO_LOW = "IPOR_329";

    //@notice Opening Fee Balance is too low
    string public constant MILTON_PUBLICATION_FEE_BALANCE_TOO_LOW = "IPOR_330";

    // 400-499-joseph
    //@notice IP Token Value which should be minted is too low
    string public constant JOSEPH_IP_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_400";

    //@notice Amount which should be burned is too low
    string public constant JOSEPH_IP_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_401";

    string public constant JOSEPH_REDEEM_LP_UTILIZATION_EXCEEDED = "IPOR_402";

    //@notice User cannot redeem underlying tokens because ipToken on his balance is too low
    string public constant JOSEPH_CANNOT_REDEEM_IP_TOKEN_TOO_LOW = "IPOR_403";

    string public constant JOSEPH_CALLER_NOT_TREASURE_TRANSFERER = "IPOR_404";

    //TODO: add test for this code
    //@notice Incorrect Treasure Treasurer Address
    string public constant JOSEPH_INCORRECT_TREASURE_TREASURER = "IPOR_405";

    //@notice Sender is not a publication fee transferer, not match address defined in IporConfiguration in key MILTON_PUBLICATION_FEE_TRANSFERER
    string public constant JOSEPH_CALLER_NOT_PUBLICATION_FEE_TRANSFERER = "IPOR_406";

    //@notice Charlie Treasurer address is incorrect
    string public constant JOSEPH_INCORRECT_CHARLIE_TREASURER = "IPOR_407";

    string public constant JOSEPH_STANLEY_BALANCE_IS_EMPTY = "IPOR_408";

    // 500-599-stanley
    string public constant STANLEY_ASSET_MISMATCH = "IPOR_500";

    // only stanley can have access to function
    string public constant STANLEY_CALLER_NOT_STANLEY = "IPOR_501";

    string public constant STANLEY_INCORRECT_TREASURY_ADDRESS = "IPOR_502";

    //@notice amount should be > 0
    string public constant STANLEY_IV_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_503";

    //@notice amount should be > 0
    string public constant STANLEY_IV_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_504";
}
