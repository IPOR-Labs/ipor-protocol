// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";

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
        /// @notice Current PnL value (Profit and Loss Value), represented in 18 decimals.
        int256 pnlValue;
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
        /// @notice minimum leverage, represented in 18 decimals.
        uint256 minLeverage;
    }

    /// @notice Gets pool configuration for AmmSwapsLens
    /// @param asset asset address
    /// @return SwapLensPoolConfiguration pool configuration
    function getSwapLensPoolConfiguration(address asset) external view returns (SwapLensPoolConfiguration memory);

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

    /// @notice Gets the swap's PnL (Profit and Loss) for a pay-fixed, given asset and swap ID.
    /// @param asset asset address
    /// @param swapId swap ID
    /// @return pnlValue PnL for a pay fixed swap
    function getPnlPayFixed(address asset, uint256 swapId) external view returns (int256 pnlValue);

    /// @notice Gets the swap's PnL (Profit and Loss) for a receive-fixed, given asset and swap ID.
    /// @param asset asset address
    /// @param swapId swap ID
    /// @return pnlValue PnL for a receive fixed swap
    function getPnlReceiveFixed(address asset, uint256 swapId) external view returns (int256 pnlValue);

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
    function getSoap(address asset) external view returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap);

    /// @notice Gets the offered rate value for a given asset, tenor and notional.
    /// @param asset The address of the asset.
    /// @param tenor The duration of the swap.
    /// @param notional The notional amount of the swap, represented in 18 decimals.
    /// @return offeredRatePayFixed The offered rate for pay fixed swaps.
    /// @return offeredRateReceiveFixed The offered rate for receive fixed swaps.
    function getOfferedRate(
        address asset,
        IporTypes.SwapTenor tenor,
        uint256 notional
    ) external view returns (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed);

    /**
     * @dev Returns the Risk indicators when open swap for a given asse, direction and tenor.
     * @param asset The address of the asset.
     * @param direction The direction of the swap
     * @param tenor The duration of the swap
     * @return riskIndicators The open swap configuration details.
     */
    function getOpenSwapRiskIndicators(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    ) external view returns (AmmTypes.OpenSwapRiskIndicators memory riskIndicators);
}
