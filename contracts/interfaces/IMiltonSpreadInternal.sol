// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

/// @title Interface for interacting with Milton Spread - for internal use.
interface IMiltonSpreadInternal {
    /// @notice Gets Spread Premiums Max Value param which is used in spread equations.
    /// @return Spread Premiums Max Value param represented in 18 decimals.
    function getSpreadPremiumsMaxValue() external pure returns (uint256);

    /// @notice Gets the "Demand Component Kf" constant - parameter used in spread calculations.
    /// @return Demand Component Kf" value represented in 18 decimals.
    function getDCKfValue() external pure returns (uint256);

    /// @notice Gets the "Demand Component Lambda" constant - parameter used in spread calculations.
    /// @return "Demand Component Lambda" represented in 18 decimals.
    function getDCLambdaValue() external pure returns (uint256);

    /// @notice Gets the "Demand Component KOmega" constant - parameter used in spread calculations.
    /// @return "Demand Component KOmega" represented in 18 decimals.
    function getDCKOmegaValue() external pure returns (uint256);

    /// @notice Gets the "Demand Component Liquidity Redemption Value" parameter used in spread calculations.
    /// This param controls maximum return or loss on the swap.
    /// @return "Demand Component Liquidity Redemption Value" represented in 18 decimals.
    function getDCMaxLiquidityRedemptionValue() external pure returns (uint256);

    /// @notice Gets Base in Region 1 for Pay Fixed - Receive Floating leg
    /// @return base in region 1 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionOneBase() external pure returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 1 for Pay Fixed - Receive Floating leg
    /// @return slope factor 1 for volatility in region 1 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionOneSlopeFactorOne() external pure returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 1 for Pay Fixed - Receive Floating leg
    /// @return slope factor 2 for mean reversion in region 1 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionOneSlopeFactorTwo() external pure returns (int256);

    /// @notice Gets Base in Region 2 for Pay Fixed - Receive Floating leg
    /// @return base in region 2 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionTwoBase() external pure returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 2 for Pay Fixed - Receive Floating leg
    /// @return slope factor 1 for volatility in region 2 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionTwoSlopeFactorOne() external pure returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 2 for Pay Fixed - Receive Floating leg
    /// @return slope factor 2 for mean reversion in region 2 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionTwoSlopeFactorTwo() external pure returns (int256);

    /// @notice Gets Base in Region 1 for Receive Fixed - Pay Floating leg
    /// @return base in region 1 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionOneBase() external pure returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 1 for Receive Fixed - Pay Floating leg
    /// @return slope factor 1 for volatility in region 1 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionOneSlopeFactorOne() external pure returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 1 for Receive Fixed - Pay Floating leg
    /// @return slope factor 2 for mean reversion in region 1 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionOneSlopeFactorTwo() external pure returns (int256);

    /// @notice Gets Base in Region 2 for Receive Fixed - Pay Floating leg
    /// @return base in region 2 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionTwoBase() external pure returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 2 for Receive Fixed - Pay Floating leg
    /// @return slope factor 1 for volatility in region 2 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionTwoSlopeFactorOne() external pure returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 2 for Receive Fixed - Pay Floating leg
    /// @return slope factor 2 for mean reversion in region 2 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionTwoSlopeFactorTwo() external pure returns (int256);
}
