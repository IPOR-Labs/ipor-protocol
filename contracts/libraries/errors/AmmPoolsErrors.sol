// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

library AmmPoolsErrors {
    // 400-499-Amm Pools
    /// @notice IP Token Value which should be minted is too low
    string public constant IP_TOKEN_MINT_AMOUNT_TOO_LOW = "IPOR_400";

    /// @notice Amount which should be burned is too low
    string public constant IP_TOKEN_BURN_AMOUNT_TOO_LOW = "IPOR_401";

    /// @notice Liquidity Pool Collateral Ration is exceeded when redeeming
    string public constant REDEEM_LP_COLLATERAL_RATIO_EXCEEDED = "IPOR_402";

    /// @notice User cannot redeem underlying tokens because ipToken on his balance is too low
    string public constant CANNOT_REDEEM_IP_TOKEN_TOO_LOW = "IPOR_403";

    /// @notice Caller is not a treasury manager, not match address defined in IPOR Protocol configuration
    string public constant CALLER_NOT_TREASURY_MANAGER = "IPOR_404";

    /// @notice Account cannot redeem ip tokens because amount of underlying tokens for transfer to beneficiary is too low.
    string public constant CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW = "IPOR_405";

    /// @notice Sender is not a publication fee transferer, not match address defined in IporConfiguration in key AMM_TREASURY_PUBLICATION_FEE_TRANSFERER
    string public constant CALLER_NOT_PUBLICATION_FEE_TRANSFERER = "IPOR_406";

    /// @notice Asset Management Balance is empty
    string public constant ASSET_MANAGEMENT_BALANCE_IS_EMPTY = "IPOR_407";

    /// @notice Incorrect AMM Treasury and Asset Management Ratio
    string public constant AMM_TREASURY_ASSET_MANAGEMENT_RATIO = "IPOR_408";

    /// @notice Insufficient ERC20 balance
    string public constant INSUFFICIENT_ERC20_BALANCE = "IPOR_409";

    /// @notice Caller is not appointed to rebalance
    string public constant CALLER_NOT_APPOINTED_TO_REBALANCE = "IPOR_410";
}
