// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IAmmGovernanceService {
    function addSwapLiquidator(address asset, address account) external;
    function removeSwapLiquidator(address asset, address account) external;
    function isSwapLiquidator(address asset, address account) external view returns (bool);

    /// @notice Set the ratio of AMM and asset management.
    /// Value which describe what percentage of asset amount stay in AMM Module in comparison to Asset Management Module
    /// @param asset Asset address. Asset corresponds to the AMM Pool
    /// @param newRatio New ratio value.
    function setAmmPoolsAndAssetManagementRatio(address asset, uint256 newRatio) external;
    function getAmmPoolsAndAssetManagementRatio(address asset) external view returns (uint256);

    function setAmmPoolsMaxLiquidityPoolBalance(address asset, uint256 newMaxLiquidityPoolBalance) external;
    function getAmmPoolsMaxLiquidityPoolBalance(address asset) external view returns (uint256);

    function setAmmPoolsMaxLpAccountContribution(address asset, uint256 newMaxLpAccountContribution) external;
    function getAmmPoolsMaxLpAccountContribution(address asset) external view returns (uint256);

    function addAmmPoolsAppointedToRebalance(address asset, address account) external;
    function removeAmmPoolsAppointedToRebalance(address asset, address account) external;
    function isAmmPoolsAppointedToRebalance(address asset, address account) external view returns (bool);

    function setAmmPoolsTreasury(address asset, address newTreasuryWallet) external;
    function getAmmPoolsTreasury(address asset) external view returns (address);

    function setAmmPoolsTreasuryManager(address asset, address newTreasuryManager) external;
    function getAmmPoolsTreasuryManager(address asset) external view returns (address);

    function setAmmPoolsCharlieTreasury(address asset, address newCharlieTreasuryWallet) external;
    function getAmmPoolsCharlieTreasury(address asset) external view returns (address);

    function setAmmPoolsCharlieTreasuryManager(address asset, address newCharlieTreasuryManager) external;
    function getAmmPoolsCharlieTreasuryManager(address asset) external view returns (address);

    function setAmmPoolsAutoRebalanceThreshold(address asset, uint256 newAutoRebalanceThreshold) external;
    function getAmmPoolsAutoRebalanceThreshold(address asset) external view returns (uint256);






}
