// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/types/AmmTypes.sol";

/// @title Types used in interfaces strictly related to AMM (Automated Market Maker).
/// @dev Used by IAmmTreasury and IAmmStorage interfaces.
library AmmTypesGenOne {
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
        /// @notice Ipor Risk Management Oracle
        address iporRiskManagementOracle;
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
        AmmTypes.SwapDirection direction;
        uint256 closeTimestamp;
        int256 swapPnlValueToDate;
        uint256 indexValue;
        AmmTypes.Swap swap;
        AmmCloseSwapPoolConfiguration poolCfg;
        AmmTypes.CloseSwapRiskIndicatorsInput riskIndicatorsInputs;
    }
    //
    //    /// @notice Risk indicators calculated for swap opening
    //    struct RiskIndicatorsInputs {
    //        /// @notice Maximum collateral ratio in general
    //        uint256 maxCollateralRatio;
    //        /// @notice Maximum collateral ratio for a given leg
    //        uint256 maxCollateralRatioPerLeg;
    //        /// @notice Maximum leverage for a given leg
    //        uint256 maxLeveragePerLeg;
    //        /// @notice Base Spread for a given leg (without demand part)
    //        int256 baseSpreadPerLeg;
    //        /// @notice Fixed rate cap
    //        uint256 fixedRateCapPerLeg;
    //        /// @notice Demand spread factor used to calculate demand spread
    //        uint256 demandSpreadFactor;
    //        /// @notice expiration date in seconds
    //        uint256 expiration;
    //        /// @notice signature of data (maxCollateralRatio, maxCollateralRatioPerLeg,maxLeveragePerLeg,baseSpreadPerLeg,fixedRateCapPerLeg,demandSpreadFactor,expiration,asset,tenor,direction)
    //        /// asset - address
    //        /// tenor - uint256
    //        /// direction - uint256
    //        bytes signature;
    //    }
    //
    //    struct CloseSwapRiskIndicatorsInput {
    //        RiskIndicatorsInputs payFixed;
    //        RiskIndicatorsInputs receiveFixed;
    //    }
}
