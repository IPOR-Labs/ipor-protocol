// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library AmmPoolsErrors {
    // 400-499-Amm Pools
    //@notice IP Token Value which should be minted is too low
    string public constant IP_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_400";

    //@notice Amount which should be burned is too low
    string public constant IP_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_401";

    string public constant REDEEM_LP_UTILIZATION_EXCEEDED = "IPOR_402";
    //@notice User cannot redeem underlying tokens because ipToken on his balance is too low
    string public constant CANNOT_REDEEM_IP_TOKEN_TOO_LOW = "IPOR_403";

    string public constant CALLER_NOT_TREASURY_MANAGER = "IPOR_404";

    //@notice Incorrect Treasury Treasurer Address
    string public constant INCORRECT_TREASURE_TREASURER = "IPOR_405";

    //@notice Sender is not a publication fee transferer, not match address defined in IporConfiguration in key AMM_TREASURY_PUBLICATION_FEE_TRANSFERER
    string public constant CALLER_NOT_PUBLICATION_FEE_TRANSFERER = "IPOR_406";

    //@notice Charlie Treasurer address is incorrect
    string public constant INCORRECT_CHARLIE_TREASURER = "IPOR_407";

    string public constant ASSET_MANAGEMENT_BALANCE_IS_EMPTY = "IPOR_408";

    string public constant AMM_TREASURY_ASSET_MANAGEMENT_RATIO = "IPOR_409";

    string public constant INSUFFICIENT_ERC20_BALANCE = "IPOR_410";

    string public constant CALLER_NOT_APPOINTED_TO_REBALANCE = "IPOR_411";
}