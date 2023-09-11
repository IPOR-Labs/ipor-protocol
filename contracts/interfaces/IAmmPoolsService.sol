// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface responsible for managing liquidity in the AMM Pools.
interface IAmmPoolsService {
    /// @notice A struct to represent a pool configuration in AmmPoolsService.
    struct AmmPoolsServicePoolConfiguration {
        /// @notice The address of the asset.
        address asset;
        /// @notice The number of decimals the asset uses.
        uint256 decimals;
        /// @notice The address of the ipToken associated with the asset.
        address ipToken;
        /// @notice The address of the AMM's storage contract.
        address ammStorage;
        /// @notice The address of the AMM's treasury contract.
        address ammTreasury;
        /// @notice The address of the asset management contract.
        address assetManagement;
        /// @notice Redeem fee rate, value represented in 18 decimals. 1e18 = 100%
        /// @dev Percentage of redeemed amount which stay in liquidity pool balance.
        uint256 redeemFeeRate;
        /// @notice Redeem liquidity pool max collateral ratio. Value describes what is maximal allowed collateral ratio for liquidity pool.
        /// @dev Collateral ratio is a proportion between liquidity pool balance and sum of all active swap collateral. Value represented in 18 decimals. 1e18 = 100%
        uint256 redeemLpMaxCollateralRatio;
    }

    /// @notice Emitted when `from` account provides liquidity (ERC20 token supported by IPOR Protocol) to AmmTreasury Liquidity Pool
    event ProvideLiquidity(
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

    /// @notice Emitted when `to` account executes redeem ipTokens
    event Redeem(
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

    /// @notice Gets the configuration of the pool for the given asset in AmmPoolsService.
    /// @param asset The address of the asset.
    /// @return The pool configuration.
    function getAmmPoolServiceConfiguration(
        address asset
    ) external view returns (AmmPoolsServicePoolConfiguration memory);

    /// @notice Providing USDT to the AMM Liquidity Pool by the sender on behalf of beneficiary.
    /// @dev Emits {ProvideLiquidity} event and transfers ERC20 tokens from the sender to the AmmTreasury,
    /// emits {Transfer} event from ERC20 asset, emits {Mint} event from ipToken.
    /// Transfers minted ipTokens to the beneficiary. Amount of transferred ipTokens is based on current ipToken exchange rate
    /// @param beneficiary Account receiving receive ipUSDT liquidity tokens.
    /// @param assetAmount Amount of ERC20 tokens transferred from the sender to the AmmTreasury. Represented in decimals specific for asset. Value represented in 18 decimals.
    function provideLiquidityUsdt(address beneficiary, uint256 assetAmount) external;

    /// @notice Providing USDC to the AMM Liquidity Pool by the sender on behalf of beneficiary.
    /// @dev Emits {ProvideLiquidity} event and transfers ERC20 tokens from the sender to the AmmTreasury,
    /// emits {Transfer} event from ERC20 asset, emits {Mint} event from ipToken.
    /// @param beneficiary Account receiving receive ipUSDT liquidity tokens.
    /// @param assetAmount Amount of ERC20 tokens transferred from the sender to the AmmTreasury. Represented in decimals specific for asset. Value represented in 18 decimals.
    function provideLiquidityUsdc(address beneficiary, uint256 assetAmount) external;

    /// @notice Providing DAI to the AMM Liquidity Pool by the sender on behalf of beneficiary.
    /// @dev Emits {ProvideLiquidity} event and transfers ERC20 tokens from the sender tothe AmmTreasury,
    /// emits {Transfer} event from ERC20 asset, emits {Mint} event from ipToken.
    /// @param beneficiary Account receiving receive ipUSDT liquidity tokens.
    /// @param assetAmount Amount of ERC20 tokens transferred from the sender to the AmmTreasury. Represented in decimals specific for asset. Value represented in 18 decimals.
    /// @dev Value represented in 18 decimals.
    function provideLiquidityDai(address beneficiary, uint256 assetAmount) external;

    /// @notice Redeems `ipTokenAmount` ipUSDT for underlying asset
    /// @dev Emits {Redeem} event, emits {Transfer} event from ERC20 asset, emits {Burn} event from ipToken.
    /// Transfers ERC20 tokens from the AmmTreasury to the beneficiary based on current exchange rate of ipUSDT.
    /// @param beneficiary Account receiving underlying tokens.
    /// @param ipTokenAmount redeem amount of ipUSDT tokens, represented in 18 decimals.
    /// @dev sender's ipUSDT tokens are burned, asset: USDT tokens are transferred to the beneficiary.
    function redeemFromAmmPoolUsdt(address beneficiary, uint256 ipTokenAmount) external;

    /// @notice Redeems `ipTokenAmount` ipUSDC for underlying asset
    /// @dev Emits {Redeem} event, emits {Transfer} event from ERC20 asset, emits {Burn} event from ipToken.
    /// Transfers ERC20 tokens from the AmmTreasury to the beneficiary based on current exchange rate of ipUSDC.
    /// @param beneficiary Account receiving underlying tokens.
    /// @param ipTokenAmount redeem amount of ipUSDC tokens, represented in 18 decimals.
    /// @dev sender's ipUSDC tokens are burned, asset: USDC tokens are transferred to the beneficiary.
    function redeemFromAmmPoolUsdc(address beneficiary, uint256 ipTokenAmount) external;

    /// @notice Redeems `ipTokenAmount` ipDAI for underlying asset
    /// @dev Emits {Redeem} event, emits {Transfer} event from ERC20 asset, emits {Burn} event from ipToken.
    /// Transfers ERC20 tokens from the AmmTreasury to the beneficiary based on current exchange rate of ipDAI.
    /// @param beneficiary Account receiving underlying tokens.
    /// @param ipTokenAmount redeem amount of ipDAI tokens, represented in 18 decimals.
    /// @dev sender's ipDAI tokens are burned, asset: DAI tokens are transferred to the beneficiary.
    function redeemFromAmmPoolDai(address beneficiary, uint256 ipTokenAmount) external;

    /// @notice Rebalances given assets between the AmmTreasury and the AssetManagement, based on configuration stored
    /// in the `AmmPoolsParamsValue.ammTreasuryAndAssetManagementRatio` field .
    /// @dev Emits {Deposit} or {Withdraw} event from AssetManagement depends on current asset balance on AmmTreasury and AssetManagement.
    /// @dev Emits {Transfer} from ERC20 asset.
    /// @param asset Address of the asset.
    function rebalanceBetweenAmmTreasuryAndAssetManagement(address asset) external;
}
