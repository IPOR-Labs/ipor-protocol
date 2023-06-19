// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./types/IporTypes.sol";

/// @title AmmSwapsLens interface responsible for reading data related with swaps.
interface IAmmSwapsLens {
    /// @notice IPOR Swap structure.
    struct IporSwap {
        /// @notice Swap's ID.
        uint256 id;
        /// @notice Swap's asset (stablecoin / underlying token)
        address asset;
        /// @notice Swap's buyer address
        address buyer;
        /// @notice Swap's collateral, represented in 18 decimals.
        uint256 collateral;
        /// @notice Notional amount, represented in 18 decimals.
        uint256 notional;
        /// @notice Swap's leverage, represented in 18 decimals.
        uint256 leverage;
        /// @notice Swap's direction
        /// @dev 0 - Pay Fixed-Receive Floating, 1 - Receive Fixed - Pay Floading
        uint256 direction;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate.
        uint256 fixedInterestRate;
        /// @notice Current position value, represented in 18 decimals.
        int256 payoff;
        /// @notice Moment when swap was opened.
        uint256 openTimestamp;
        /// @notice Moment when swap achieve its maturity.
        uint256 endTimestamp;
        /// @notice Liquidation deposit value on day when swap was opened. Value represented in 18 decimals.
        uint256 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        uint256 state;
    }

    /// @notice Lens Configuration structure for AmmSwapsLens for a given asset (ppol)
    struct SwapLensPoolConfiguration {
        /// @notice Asset address
        address asset;
        /// @notice Address of the AMM (Automated Market Maker) storage contract
        address ammStorage;
        /// @notice Address of the AMM Treasury contract
        address ammTreasury;
    }

    /// @notice Struct describing configuration for one asset (pool)
    struct AssetConfiguration {
        /// @notice underlying token / stablecoin address
        address asset;
        /// @notice Minimal leverage value. Represented in 18 decimals.
        uint256 minLeverage;
        /// @notice Maximum swap leverage value. Represented in 18 decimals.
        uint256 maxLeverage;
        /// @notice Rate of collateral charged as a opening fee. Represented in 18 decimals.
        uint256 openingFeeRate;
        /// @notice IPOR publication fee amount collected from buyer when opening new swap. Represented in 18 decimals.
        uint256 iporPublicationFeeAmount;
        /// @notice Liquidation deposit amount collected from buyer when opening new swap. Represented in 18 decimals.
        uint256 liquidationDepositAmount;
        /// @notice Calculated Spread. Represented in 18 decimals.
        int256 spread;
        /// @notice Maximum Liquidity Pool Collateral Ratio.
        /// @dev It is a ratio of total collateral balance / liquidity pool balance
        uint256 maxLpCollateralRatio;
        /// @notice Maximum amount that can be in Liquidity Pool, represented in 18 decimals.
        uint256 maxLiquidityPoolBalance;
        /// @notice Maximum amount that can be contributed by one account in Liquidity Pool, represented in 18 decimals.
        uint256 maxLpAccountContribution;
    }

    /// @notice Gets active swaps for a given asset sender address (aka buyer).
    /// @param asset asset address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of sender's active swaps in AmmTreasury
    /// @return swaps list of active sender's swaps
    function getSwaps(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporSwap[] memory swaps);

    /// @notice Gets the swap's payoff for a pay-fixed, given asset and swap ID.
    /// @param asset asset address
    /// @param swapId swap ID
    /// @return payoff payoff for a pay fixed swap
    function getPayoffPayFixed(address asset, uint256 swapId) external view returns (int256 payoff);

    /// @notice Gets the swap's payoff for a receive-fixed, given asset and swap ID.
    /// @param asset asset address
    /// @param swapId swap ID
    /// @return payoff payoff for a receive fixed swap
    function getPayoffReceiveFixed(address asset, uint256 swapId) external view returns (int256 payoff);

    /// @notice Gets the balances structure required to open a swap.
    /// @param asset The address of the asset.
    /// @return AmmBalancesForOpenSwapMemory The balances required for opening a swap.
    function getBalancesForOpenSwap(
        address asset
    ) external view returns (IporTypes.AmmBalancesForOpenSwapMemory memory);

    /// @notice Gets the SOAP value for a given asset.
    /// @param asset The address of the asset.
    /// @return soapPayFixed SOAP value for pay fixed swaps.
    /// @return soapReceiveFixed SOAP value for receive fixed swaps.
    /// @return soap SOAP value which is a sum of soapPayFixed and soapReceiveFixed.
    function getSOAP(address asset) external view returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap);

    /**
     * @dev Returns the asset configuration details for a given asset, direction and tenor.
     * @param asset The address of the asset.
     * @param direction The direction of the swap (0 for pay fixed, 1 for receive fixed).
     * @param tenor The duration of the swap
     * @return The asset configuration details.
     */
    function getAmmSwapsLensConfiguration(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    ) external view returns (AssetConfiguration memory);
}
