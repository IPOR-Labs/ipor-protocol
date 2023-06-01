// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "../interfaces/types/AmmTypes.sol";

interface IAmmPoolsService {
    struct AmmPoolsServicePoolConfiguration {
        address asset;
        uint256 decimals;
        address ipToken;
        address ammStorage;
        address ammTreasury;
        address assetManagement;
        uint256 redeemFeeRate;
        uint256 redeemLpMaxUtilizationRate;
    }

    /// @notice Emitted when `from` account provides liquidity (ERC20 token supported by IPOR Protocol) to AmmTreasury Liquidity Pool
    event ProvideLiquidity(
        /// @notice moment when liquidity is provided by `from` account
        uint256 timestamp,
        /// @notice address that provides liquidity
        address from,
        /// @notice AmmTreasury's address where liquidity is received
        address to,
        /// @notice current ipToken exchange rate
        /// @dev value represented in 18 decimals
        uint256 exchangeRate,
        /// @notice amount of asset provided by user to AmmTreasury's liquidity pool
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
        /// @notice AmmTreasury's address from which underlying asset - ERC20 Tokens, are transferred to `to` account
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
        /// @notice net asset amount transferred from AmmTreasury to `to`/sender's account, reduced by the redeem fee
        /// @dev value represented in 18 decimals
        uint256 redeemAmount
    );

    function getAmmPoolServiceConfiguration(address asset) external view returns (AmmPoolsServicePoolConfiguration memory);

    /// @notice Function invoked to provide asset to Liquidity Pool in amount `assetValue`
    /// @dev Emits {ProvideLiquidity} event and transfers ERC20 tokens from sender to AmmTreasury,
    /// emits {Transfer} event from ERC20 asset, emits {Mint} event from ipToken.
    /// Transfers minted ipTokens to the sender. Amount of transferred ipTokens is based on current ipToken exchange rate
    /// @param assetAmount Amount of ERC20 tokens which are transferred from sender to AmmTreasury. Represented in decimals specific for asset.
    function provideLiquidityUsdt(address onBehalfOf, uint256 assetAmount) external;

    function provideLiquidityUsdc(address onBehalfOf, uint256 assetAmount) external;

    function provideLiquidityDai(address onBehalfOf, uint256 assetAmount) external;

    /// @notice Redeems `ipTokenAmount` IpTokens for underlying asset
    /// @dev Emits {Redeem} event, emits {Transfer} event from ERC20 asset, emits {Burn} event from ipToken.
    /// Transfers asser ERC20 tokens from AmmTreasury to sender based on current exchange rate.
    /// @param ipTokenAmount redeem amount, represented in 18 decimals.
    function redeemFromAmmPoolUsdt(address onBehalfOf, uint256 ipTokenAmount) external;

    function redeemFromAmmPoolUsdc(address onBehalfOf, uint256 ipTokenAmount) external;

    function redeemFromAmmPoolDai(address onBehalfOf, uint256 ipTokenAmount) external;

    /// @notice Rebalances ERC20 balance between AmmTreasury and AssetManagement, based on configuration
    /// `_AMM_TREASURY_ASSET_MANAGEMENT_BALANCE_RATIO` part of AmmTreasury balance is transferred to AssetManagement or vice versa.
    /// for more information refer to the documentation: https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/asset-management
    /// @dev Emits {Deposit} or {Withdraw} event from AssetManagement depends on current asset balance on AmmTreasury and AssetManagement.
    /// @dev Emits {Mint} or {Burn} event from ivToken depends on current asset balance on AmmTreasury and AssetManagement.
    /// @dev Emits {Transfer} from ERC20 asset.
    function rebalanceBetweenAmmTreasuryAndAssetManagement(address asset) external;
}
