// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IAmmGovernanceService {
    struct PoolConfiguration {
        address asset;
        uint256 assetDecimals;
        address ammStorage;
        address ammTreasury;
    }

    function getAmmGovernanceServicePoolConfiguration(address asset) external view returns (PoolConfiguration memory);

    function depositToAssetManagement(address asset, uint256 assetAmount) external;

    function withdrawFromAssetManagement(address asset, uint256 assetAmount) external;

    function withdrawAllFromAssetManagement(address asset) external;

    function transferToTreasury(address asset, uint256 assetAmount) external;

    function transferToCharlieTreasury(address asset, uint256 assetAmount) external;

    function addSwapLiquidator(address asset, address account) external;

    function removeSwapLiquidator(address asset, address account) external;

    function isSwapLiquidator(address asset, address account) external view returns (bool);

    /// @notice Set the ratio of AMM and asset management.
    /// Value which describe what percentage of asset amount stay in AMM Module in comparison to Asset Management Module
    /// @param asset Asset address. Asset corresponds to the AMM Pool
    /// @param newRatio New ratio value.
    function setAmmAndAssetManagementRatio(address asset, uint256 newRatio) external;

    function getAmmAndAssetManagementRatio(address asset) external view returns (uint256);

    function setAmmMaxLiquidityPoolBalance(address asset, uint256 newMaxLiquidityPoolBalance) external;

    function getAmmMaxLiquidityPoolBalance(address asset) external view returns (uint256);

    function setAmmMaxLpAccountContribution(address asset, uint256 newMaxLpAccountContribution) external;

    function getAmmMaxLpAccountContribution(address asset) external view returns (uint256);

    function addAppointedToRebalanceInAmm(address asset, address account) external;

    function removeAppointedToRebalanceInAmm(address asset, address account) external;

    function isAppointedToRebalanceInAmm(address asset, address account) external view returns (bool);

    function setAmmPoolsTreasury(address asset, address newTreasuryWallet) external;

    function getAmmPoolsTreasury(address asset) external view returns (address);

    function setAmmPoolsTreasuryManager(address asset, address newTreasuryManager) external;

    function getAmmPoolsTreasuryManager(address asset) external view returns (address);

    function setAmmCharlieTreasury(address asset, address newCharlieTreasuryWallet) external;

    function getAmmCharlieTreasury(address asset) external view returns (address);

    function setAmmCharlieTreasuryManager(address asset, address newCharlieTreasuryManager) external;

    function getAmmCharlieTreasuryManager(address asset) external view returns (address);

    function setAmmAutoRebalanceThreshold(address asset, uint256 newAutoRebalanceThreshold) external;

    function getAmmAutoRebalanceThreshold(address asset) external view returns (uint256);
}
