// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interaction with Milton's configuration.
interface IMiltonConfiguration {
    /// @notice Returns current version of Milton's.
    /// @return Current Milton version.
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Joseph instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Gets max swap collateral amount param value.
    /// @dev Param used in validation upcoming opened swap.
    /// @return max swap collateral amount represented in 18 decimals
    function getMaxSwapCollateralAmount() external pure returns (uint256);

    /// @notice Gets max Liquidity Pool Utilization Percentage param value.
    /// @dev Param used in validation upcoming opened swap.
    /// @return max Liquidity Pool Utilization Percentage represented in 18 decimals
    function getMaxLpUtilizationPercentage() external pure returns (uint256);

    /// @notice Gets max Liquidity Pool Utilization Per Leg Percentage param value.
    /// @dev Param used in validation upcoming opened swap.
    /// @return max Liquidity Pool Utilization Per Leg Percentage represented in 18 decimals
    function getMaxLpUtilizationPerLegPercentage() external pure returns (uint256);

    /// @notice Gets Income Fee Percentage param value.
    /// @dev Param used in closing swap. When trader earn then Milton takes fee from interest.
    /// @return income fee percentage param value represented in 18 decimals
    function getIncomeFeePercentage() external pure returns (uint256);

    /// @notice Gets Opening Fee Percentage param value. When trader open position then Milton takes fee from collateral.
    /// Opening fee amount is divided and transfered to Liquidity Pool and to Milton Treasury
    /// @dev Param used in opening swap.
    /// @return opening fee percentage param value represented in 18 decimals
    function getOpeningFeePercentage() external pure returns (uint256);

    /// @notice Gets Opening Fee For Treasury Percentage param value. When trader open position then Milton takes fee from collateral.
    /// Opening fee amount is divided and transfered to Liquidity Pool and to Milton Treasury.
    /// Opening Fee For Treasury define ration of Opening Fee transfered to Milton Treasury.
    /// @dev Param used in opening swap.
    /// @return opening fee for treasury percentage param value represented in 18 decimals
    function getOpeningFeeForTreasuryPercentage() external pure returns (uint256);

    /// @notice Gets IPOR publication fee amount param. When trader open position then Milton takes
    /// IPOR publication fee amount from total amount invested by trader.
    /// @dev Param used in opening swap.
    /// @return IPOR publication fee amount value represented in 18 decimals
    function getIporPublicationFeeAmount() external pure returns (uint256);

    /// @notice Gets liquidation deposit amount param. When trader open position then liquidation deposit amount is transfered from trader to Milton. This cash is intended to liquidator.
    /// @return liquidation deposit amount represented in 18 decimals
    function getLiquidationDepositAmount() external pure returns (uint256);

    /// @notice Gets max leverage value param.
    /// @dev Param used in validation upcoming opened swap.
    /// @return max leverage value represented in 18 decimals
    function getMaxLeverageValue() external pure returns (uint256);

    /// @notice Gets min leverage value param.
    /// @dev Param used in validation upcoming opened swap.
    /// @return min leverage value represented in 18 decimals
    function getMinLeverageValue() external pure returns (uint256);

    /// @notice Gets Joseph address.
    /// @return Joseph address.
    function getJoseph() external view returns (address);

    /// @notice Gets Milton Spread Model smart contract address responsible for Spread calculation.
    /// @return Milton Spread Model smart contract address
    function getMiltonSpreadModel() external view returns (address);
}
