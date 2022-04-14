// SPDX-License-Identifier: agpl-3.0
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

    function getB1() external pure returns (int256);

    function getB2() external pure returns (int256);

    function getV1() external pure returns (int256);

    function getV2() external pure returns (int256);

    function getM1() external pure returns (int256);

    function getM2() external pure returns (int256);
}
