// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interaction with Joseph - smart contract responsible
/// for managing ipTokens and ERC20 tokens in IPOR Protocol.
interface IJoseph {
    /// @notice Calculates ipToken exchange rate
    /// @dev exchange rate is a Liqudity Pool Balance and ipToken total supply ratio
    /// @return ipToken exchange rate for a specific asset
    function calculateExchangeRate() external view returns (uint256);

    /// @notice Function invoked to provide asset to Liquidity Pool in amount `assetValue`
    /// @dev Emits {ProvideLiquidity} event and transfers ERC20 tokens from sender to Milton,
    /// emits {Transfer} event from ERC20 asset, emits {Mint} event from ipToken
    /// in return transfers minted ipTokens to the sender. Volume of transferred ipTokens is based on current ipToken exchange rate
    /// @param assetAmount volume of ERC20 tokens which are transferred from sender to Milton
    function provideLiquidity(uint256 assetAmount) external;

    /// @notice Redeems `ipTokenVolume` IpTokens for underlying asset
    /// @dev Emits {Redeem} event, emits {Transfer} event from ERC20 asset, emits {Burn} event from ipToken,
    /// transfer asser ERC20 tokens from Milton to sender based on current exchange rate.
    /// @param ipTokenVolume redeem amount
    function redeem(uint256 ipTokenVolume) external;

    /// @notice Returns reserve ratio on Milton Asset Balance / (Milton Asset Balance + Stanley Asset Balance) for a given asset
    /// @return reserves ratio
    function checkVaultReservesRatio() external returns (uint256);

    /// @notice Emitted when `from` account provides liquidity to Milton Liquidity Pool
    event ProvideLiquidity(
        /// @notice moment when liquidity is provided by `from` account
        uint256 timestamp,
        /// @notice user who provide liquidity, `from` account are transferred asset tokens to `to` account
        address from,
        /// @notice Milton address where liquidity is provided, to this account asset tokens are transferred from sender `to`
        address to,
        /// @notice actual IP Token exchange rate
        /// @dev value represented in 18 decimals
        uint256 exchangeRate,
        /// @notice asset amount which was provided by user to Milton liquidity pool
        /// @dev value represented in 18 decimals
        uint256 assetAmount,
        /// @notice ipToken value corresponding to `assetAmount` and `excangeRate`
        /// @dev value represented in 18 decimals
        uint256 ipTokenAmount
    );

    /// @notice Emitted when `to` accound executes redeem ipTokens
    event Redeem(
        /// @notice moment when IP Tokens were redeemed by `to` account
        uint256 timestamp,
        /// @notice Milton address from asset tokens are transferred to `to` account
        address from,
        /// @notice sender account where underlying asset tokens are transferred after redeem
        address to,
        /// @notice IP Token exchange rate used for calculating `assetAmount`
        /// @dev value represented in 18 decimals
        uint256 exchangeRate,
        /// @notice underlying asset value calculated based on `exchangeRate` and `ipTokenAmount`
        /// @dev value represented in 18 decimals
        uint256 assetAmount,
        /// @notice redeemed IP Token value
        /// @dev value represented in 18 decimals
        uint256 ipTokenAmount,
        /// @notice underlying asset fee taken for redeeming
        /// @dev value represented in 18 decimals
        uint256 redeemFee,
        /// @notice final asset value transferred from Milton to `to` / sender account, substraction assetAmount - redeemFee
        /// @dev value represented in 18 decimals
        uint256 redeemAmount
    );
}
