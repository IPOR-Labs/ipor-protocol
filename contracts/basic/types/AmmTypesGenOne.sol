// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/types/AmmTypes.sol";

/// @title Types used in interfaces strictly related to AMM (Automated Market Maker).
/// @dev Used by IAmmTreasury and IAmmStorage interfaces.
library AmmTypesGenOne {
    /// @notice Struct representing swap item, used for listing and in internal calculations
    struct Swap {
        /// @notice Swap's unique ID
        uint256 id;
        /// @notice Swap's buyer
        address buyer;
        /// @notice Swap opening epoch timestamp
        uint256 openTimestamp;
        /// @notice Swap's tenor
        IporTypes.SwapTenor tenor;
        /// @notice Swap's direction
        AmmTypes.SwapDirection direction;
        /// @notice Index position of this Swap in an array of swaps' identification associated to swap buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array.
        /// During removal the last item in the array is switched with the one that just has been removed.
        uint256 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit amount
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        IporTypes.SwapState state;
    }

    /// @notice Structure representing configuration of the AmmOpenSwapServicePool for specific asset (pool).
    struct AmmOpenSwapServicePoolConfiguration {
        /// @notice address of the asset
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice address of the AMM Storage
        address ammStorage;
        /// @notice address of the AMM Treasury
        address ammTreasury;
        /// @notice ipor publication fee, fee used when opening swap, represented in 18 decimals.
        uint256 iporPublicationFee;
        /// @notice maximum swap collateral amount, represented in 18 decimals.
        uint256 maxSwapCollateralAmount;
        /// @notice liquidation deposit amount, represented WITHOUT 18 decimals. Example 25 = 25 USDT.
        uint256 liquidationDepositAmount;
        /// @notice minimum leverage, represented in 18 decimals.
        uint256 minLeverage;
        /// @notice swap's opening fee rate, represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeRate;
        /// @notice swap's opening fee rate, portion of the rate which is allocated to "treasury" balance
        /// @dev Value describes what percentage of opening fee amount is allocated to "treasury" balance. Value represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeTreasuryPortionRate;
    }

    /// @notice Structure representing the configuration of the AmmCloseSwapService for a given pool (asset).
    struct AmmCloseSwapPoolConfiguration {
        /// @notice Spread Router
        address spreadRouter;
        /// @notice asset address
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice Amm Storage contract address
        address ammStorage;
        /// @notice Amm Treasury contract address
        address ammTreasury;
        /// @notice Asset Management contract address
        address assetManagement;
        /// @notice Unwinding Fee Rate for unwinding the swap, represented in 18 decimals, 1e18 = 100%
        uint256 unwindingFeeRate;
        /// @notice Unwinding Fee Rate for unwinding the swap, part earmarked for the treasury, represented in 18 decimals, 1e18 = 100%
        uint256 unwindingFeeTreasuryPortionRate;
        /// @notice Max number of swaps (per leg) that can be liquidated in one call, represented without decimals
        uint256 maxLengthOfLiquidatedSwapsPerLeg;
        /// @notice Time before maturity when the community is allowed to close the swap, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByCommunity;
        /// @notice Time before maturity then the swap owner can close it, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByBuyer;
        /// @notice Min liquidation threshold allowing community to close the swap ahead of maturity, represented in 18 decimals
        uint256 minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        /// @notice Min liquidation threshold allowing the owner to close the swap ahead of maturity, represented in 18 decimals
        uint256 minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        /// @notice Min leverage of the virtual swap used in unwinding, represented in 18 decimals
        uint256 minLeverage;
    }

    struct UnwindParams {
        address messageSigner;
        uint256 closeTimestamp;
        int256 swapPnlValueToDate;
        uint256 indexValue;
        AmmTypesGenOne.Swap swap;
        AmmCloseSwapPoolConfiguration poolCfg;
        AmmTypes.CloseSwapRiskIndicatorsInput riskIndicatorsInputs;
    }
}
