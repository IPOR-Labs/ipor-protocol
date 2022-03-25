// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IMiltonConfiguration {
    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Joseph instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    function getMaxSwapCollateralAmount() external pure returns (uint256);

    function getMaxSlippagePercentage() external pure returns (uint256);

    function getMaxLpUtilizationPercentage() external pure returns (uint256);

    function getMaxLpUtilizationPerLegPercentage() external pure returns (uint256);

    function getIncomeFeePercentage() external pure returns (uint256);

    function getOpeningFeePercentage() external pure returns (uint256);

    function getOpeningFeeForTreasuryPercentage() external pure returns (uint256);

    function getIporPublicationFeeAmount() external pure returns (uint256);

    function getLiquidationDepositAmount() external pure returns (uint256);

    function getMaxLeverageValue() external pure returns (uint256);

    function getMinLeverageValue() external pure returns (uint256);

    function getMiltonSpreadModel() external view returns (address);

    function getJoseph() external view returns (address);

    function setJoseph(address joseph) external;

    event JosephUpdated(address indexed newJoseph);
}
