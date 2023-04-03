// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./types/IporTypes.sol";

/// @title Interface for interacting with Milton Spread - for internal use.
interface IMiltonSpreadInternal {
    /// @notice Gets Base in Region 1 for Pay Fixed - Receive Floating leg
    /// @return base in region 1 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionOneBase() external view returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 1 for Pay Fixed - Receive Floating leg
    /// @return slope factor 1 for volatility in region 1 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionOneSlopeForVolatility() external view returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 1 for Pay Fixed - Receive Floating leg
    /// @return slope factor 2 for mean reversion in region 1 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionOneSlopeForMeanReversion() external view returns (int256);

    /// @notice Gets Base in Region 2 for Pay Fixed - Receive Floating leg
    /// @return base in region 2 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionTwoBase() external view returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 2 for Pay Fixed - Receive Floating leg
    /// @return slope factor 1 for volatility in region 2 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionTwoSlopeForVolatility() external view returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 2 for Pay Fixed - Receive Floating leg
    /// @return slope factor 2 for mean reversion in region 2 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionTwoSlopeForMeanReversion() external view returns (int256);

    /// @notice Gets Base in Region 1 for Receive Fixed - Pay Floating leg
    /// @return base in region 1 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionOneBase() external view returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 1 for Receive Fixed - Pay Floating leg
    /// @return slope factor 1 for volatility in region 1 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionOneSlopeForVolatility() external view returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 1 for Receive Fixed - Pay Floating leg
    /// @return slope factor 2 for mean reversion in region 1 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionOneSlopeForMeanReversion() external view returns (int256);

    /// @notice Gets Base in Region 2 for Receive Fixed - Pay Floating leg
    /// @return base in region 2 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionTwoBase() external view returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 2 for Receive Fixed - Pay Floating leg
    /// @return slope factor 1 for volatility in region 2 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionTwoSlopeForVolatility() external view returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 2 for Receive Fixed - Pay Floating leg
    /// @return slope factor 2 for mean reversion in region 2 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionTwoSlopeForMeanReversion() external view returns (int256);

    function getWeightedNotionalPayFixed() external view returns (uint256);

    function getWeightedNotionalReceiveFixed() external view returns (uint256);

    function getLastUpdateTimePayFixed() external view returns (uint256);

    function getLastUpdateTimeReceiveFixed() external view returns (uint256);

    function getMinAnticipatedSustainedRate() external pure returns (uint256);

    function getMaxAnticipatedSustainedRate() external pure returns (uint256);

    function calculateVolatilitySpreadReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonSwapsBalanceMemory memory accruedBalance
    ) external view returns (int256 volatilitySpread);

    function calculateVolatilitySpreadPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonSwapsBalanceMemory memory accruedBalance
    ) external view returns (int256 volatilitySpread);

    function calculateLpDepth(
        uint256 lpBalance,
        uint256 totalCollateralPayFixed,
        uint256 totalCollateralReceiveFixed
    ) external view returns (uint256 lpDepth);

    function calculateMaxDdReceiveFixed(
        uint256 collateralReceiveFixed,
        uint256 notionalReceiveFixed,
        uint256 iporRate,
        uint256 minAnticipatedSustainedRate,
        uint256 maturity
    ) external view returns (uint256 maxDdReceiveFixed);

    function calculateMaxDdPayFixed(
        uint256 collateralPayFixed,
        uint256 notionalPayFixed,
        uint256 iporRate,
        uint256 maxAnticipatedSustainedRate,
        uint256 maturity
    ) external view returns (uint256 maxDdPayFixed);

    function calculateMaxDdAdjusted(
        uint256 maxDdT1,
        uint256 maxDdT2,
        uint256 weightedTimeToMaturity,
        uint256 weightedNotionalT1,
        uint256 weightedNotionalT2,
        uint256 totalNotionalPerLeg
    ) external view returns (uint256 maxDdAdjusted);
}
