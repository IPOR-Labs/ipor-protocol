// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "../interfaces/types/AmmTypes.sol";

interface IAmmPoolsService {
    /// @notice Function invoked to provide asset to Liquidity Pool in amount `assetValue`
    /// @dev Emits {ProvideLiquidity} event and transfers ERC20 tokens from sender to Milton,
    /// emits {Transfer} event from ERC20 asset, emits {Mint} event from ipToken.
    /// Transfers minted ipTokens to the sender. Amount of transferred ipTokens is based on current ipToken exchange rate
    /// @param assetAmount Amount of ERC20 tokens which are transferred from sender to Milton. Represented in decimals specific for asset.
    function provideLiquidity(
        address asset,
        address onBehalfOf,
        uint256 assetAmount
    ) external;

    /// @notice Redeems `ipTokenAmount` IpTokens for underlying asset
    /// @dev Emits {Redeem} event, emits {Transfer} event from ERC20 asset, emits {Burn} event from ipToken.
    /// Transfers asser ERC20 tokens from Milton to sender based on current exchange rate.
    /// @param ipTokenAmount redeem amount, represented in 18 decimals.
    function redeem(
        address asset,
        address onBehalfOf,
        uint256 ipTokenAmount
    ) external;

    /// @notice Rebalances ERC20 balance between Milton and Stanley, based on configuration
    /// `_MILTON_STANLEY_BALANCE_RATIO` part of Milton balance is transferred to Stanley or vice versa.
    /// for more information refer to the documentation: https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/asset-management
    /// @dev Emits {Deposit} or {Withdraw} event from Stanley depends on current asset balance on Milton and Stanley.
    /// @dev Emits {Mint} or {Burn} event from ivToken depends on current asset balance on Milton and Stanley.
    /// @dev Emits {Transfer} from ERC20 asset.
    function rebalance(address asset) external;

    /// @notice Emitted when `from` account provides liquidity (ERC20 token supported by IPOR Protocol) to Milton Liquidity Pool
    event ProvideLiquidity(
        /// @notice moment when liquidity is provided by `from` account
        uint256 timestamp,
        /// @notice address that provides liquidity
        address from,
        /// @notice Milton's address where liquidity is received
        address to,
        /// @notice current ipToken exchange rate
        /// @dev value represented in 18 decimals
        uint256 exchangeRate,
        /// @notice amount of asset provided by user to Milton's liquidity pool
        /// @dev value represented in 18 decimals
        uint256 assetAmount,
        /// @notice amount of ipToken issued to represent user's share in the liquidity pool.
        /// @dev value represented in 18 decimals
        uint256 ipTokenAmount
    );

    /// @notice Emitted when `to` accound executes redeem ipTokens
    event Redeem(
        /// @notice moment in which ipTokens were redeemed by `to` account
        uint256 timestamp,
        /// @notice Milton's address from which underlying asset - ERC20 Tokens, are transferred to `to` account
        address from,
        /// @notice account where underlying asset tokens are transferred after redeem
        address to,
        /// @notice ipToken exchange rate used for calculating `assetAmount`
        /// @dev value represented in 18 decimals
        uint256 exchangeRate,
        /// @notice underlying asset value calculated based on `exchangeRate` and `ipTokenAmount`
        /// @dev value represented in 18 decimals
        uint256 assetAmount,
        /// @notice redeemed IP Token value
        /// @dev value represented in 18 decimals
        uint256 ipTokenAmount,
        /// @notice underlying asset fee deducted when redeeming ipToken.
        /// @dev value represented in 18 decimals
        uint256 redeemFee,
        /// @notice net asset amount transferred from Milton to `to`/sender's account, reduced by the redeem fee
        /// @dev value represented in 18 decimals
        uint256 redeemAmount
    );
}
