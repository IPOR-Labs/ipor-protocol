// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interacting with Milton Spread's configuration.
interface IMiltonSpreadConfiguration {
	
    /// @notice Gets Spread Premiums Max Value param which is used in spread equations.
    /// @return Spread Premiums Max Value param represented in 18 decimals.
    function getSpreadPremiumsMaxValue() external pure returns (uint256);

    /// @notice Gets Demand Component Kf Value param which is used in spread equations.
    /// @return Demand Component Kf Value param represented in 18 decimals.
    function getDCKfValue() external pure returns (uint256);

    /// @notice Gets Demand Component Lambda Value param which is used in spread equations.
    /// @return Demand Component Kf Value param represented in 18 decimals.
    function getDCLambdaValue() external pure returns (uint256);

    /// @notice Gets Demand Component KOmega Value param which is used in spread equations.
    /// @return Demand Component KOmega Value param represented in 18 decimals.
    function getDCKOmegaValue() external pure returns (uint256);

    /// @notice Gets Demand Component Liquidity Redemption Value param which is used in spread equations.
    /// @return Demand Component Liquidity Redemption Value param represented in 18 decimals.
    function getDCMaxLiquidityRedemptionValue() external pure returns (uint256);

    /// @notice Gets At Par Component KVol Value param which is used in spread equations.
    /// @return At Par Component KVol Value param represented in 18 decimals.
    function getAtParComponentKVolValue() external pure returns (uint256);

    /// @notice Gets At Par Component KHist Value param which is used in spread equations.
    /// @return At Par Component KHist Value param represented in 18 decimals.
    function getAtParComponentKHistValue() external pure returns (uint256);
}
