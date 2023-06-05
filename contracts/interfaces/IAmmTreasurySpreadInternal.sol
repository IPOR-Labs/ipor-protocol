// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface for interacting with AmmTreasury Spread - for internal use.
interface IAmmTreasurySpreadInternal {
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
}
