// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interacting with Milton Spread - for internal use.
interface IMiltonSpreadInternal {
    /// @notice Returns the current version of Milton Spread Model
    /// @return current Milton Spread Model version
    function getVersion() external pure returns (uint256);

    /// @notice Gets Spread Premiums maximum allowed value - parameter used in spread calculations.
    /// @return Spread Premiums Max param value - represented in 18 decimals.
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

    /// @notice Gets "At Par Component KVol" - parameter used in spread calculations.
    /// @return "At Par Component KVol" represented in 18 decimals.
    function getAtParComponentKVolValue() external pure returns (uint256);

    /// @notice Gets "At Par Component KHist" value - parameter used in spread equations.
    /// @return "At Par Component KHist" represented in 18 decimals.
    function getAtParComponentKHistValue() external pure returns (uint256);
}
