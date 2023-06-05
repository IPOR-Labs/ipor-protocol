// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "../interfaces/types/AmmTypes.sol";

/// @title Interface of the service that allows to close swaps.
interface IAmmCloseSwapService {
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
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Liquidator. Value represented in 18 decimals.
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

    struct AmmCloseSwapServicePoolConfiguration {
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

    function getAmmCloseSwapServicePoolConfiguration(address asset) external view returns (AmmCloseSwapServicePoolConfiguration memory);

    function closeSwapPayFixedUsdt(address beneficiary, uint256 swapId) external;

    function closeSwapPayFixedUsdc(address beneficiary, uint256 swapId) external;

    function closeSwapPayFixedDai(address beneficiary, uint256 swapId) external;

    function closeSwapReceiveFixedUsdt(address beneficiary, uint256 swapId) external;

    function closeSwapReceiveFixedUsdc(address beneficiary, uint256 swapId) external;

    function closeSwapReceiveFixedDai(address beneficiary, uint256 swapId) external;

    function closeSwapsUsdt(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    function closeSwapsUsdc(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    function closeSwapsDai(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    function emergencyCloseSwapPayFixedUsdt(uint256 swapId) external;

    function emergencyCloseSwapPayFixedUsdc(uint256 swapId) external;

    function emergencyCloseSwapPayFixedDai(uint256 swapId) external;

    function emergencyCloseSwapReceiveFixedUsdt(uint256 swapId) external;

    function emergencyCloseSwapReceiveFixedUsdc(uint256 swapId) external;

    function emergencyCloseSwapReceiveFixedDai(uint256 swapId) external;

    function emergencyCloseSwapsPayFixedUsdt(uint256[] memory swapIds)
        external
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    function emergencyCloseSwapsPayFixedUsdc(uint256[] memory swapIds)
        external
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    function emergencyCloseSwapsPayFixedDai(uint256[] memory swapIds)
        external
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    function emergencyCloseSwapsReceiveFixedUsdt(uint256[] memory swapIds)
        external
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    function emergencyCloseSwapsReceiveFixedUsdc(uint256[] memory swapIds)
        external
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    function emergencyCloseSwapsReceiveFixedDai(uint256[] memory swapIds)
        external
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);
}
