// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IAmmGovernanceService {
    /// @notice Set the ratio of AMM and asset management.
    /// Value which describe what percentage of asset amount stay in AMM Module in comparison to Asset Management Module
    /// @param asset Asset address. Asset corresponds to the AMM Pool
    /// @param newRatio New ratio value.
    function setAmmAndAssetManagementRatio(address asset, uint256 newRatio) external;

    function getAmmAndAssetManagementRatio(address asset) external view returns (uint256);

    function addSwapLiquidator(address account) external;

    function removeSwapLiquidator(address account) external;

    function isSwapLiquidator(address account) external view returns (bool);
}
