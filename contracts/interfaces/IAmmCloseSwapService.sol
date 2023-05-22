// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "../interfaces/types/AmmTypes.sol";

/// @title Interface of the service that allows to close swaps.
interface IAmmCloseSwapService {
    function closeSwapPayFixed(
        address asset,
        address beneficiary,
        uint256 swapId
    ) external;

    function closeSwapReceiveFixed(
        address asset,
        address beneficiary,
        uint256 swapId
    ) external;

    function closeSwaps(
        address asset,
        address onBehalfOf,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    function emergencyCloseSwapPayFixed(address asset, uint256 swapId) external;

    function emergencyCloseSwapReceiveFixed(address asset, uint256 swapId) external;

    function emergencyCloseSwapsPayFixed(address asset, uint256[] memory swapIds)
        external
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    function emergencyCloseSwapsReceiveFixed(address asset, uint256[] memory swapIds)
        external
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    function getPoolConfiguration(address asset) external view returns (PoolConfiguration memory);

    /// @notice Emmited when trader closes Swap.
    event CloseSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice underlying asset
        address asset,
        /// @notice the moment when swap was closed
        uint256 closeTimestamp,
        /// @notice account that liquidated the swap
        address liquidator,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator
    );

    /// @notice Emmited when trader closes Swap.
    event SwapUnwind(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice payoff to date without unwind value, represented in 18 decimals
        int256 swapPayoffToDate,
        // @notice swap unwind value, represented in 18 decimals
        int256 swapUnwindValue,
        // @notice swap unwind value, represented in 18 decimals
        uint256 swapUnwindOpeningFee
    );

    struct PoolConfiguration {
        address asset;
        uint256 decimals;
        address ammStorage;
        address ammTreasury;
        address assetManagement;
        uint256 openingFeeRate;
        uint256 openingFeeRateForSwapUnwind;
        uint256 liquidationLegLimit;
        uint256 timeBeforeMaturityAllowedToCloseSwapByCommunity;
        uint256 timeBeforeMaturityAllowedToCloseSwapByBuyer;
        uint256 minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        uint256 minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        uint256 minLeverage;
    }
}
