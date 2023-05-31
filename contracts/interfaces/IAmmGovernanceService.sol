// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
import "../libraries/StorageLib.sol";

interface IAmmGovernanceService {
    struct PoolConfiguration {
        address asset;
        uint256 assetDecimals;
        address ammStorage;
        address ammTreasury;
        address ammPoolsTreasury;
        address ammPoolsTreasuryManager;
        address ammCharlieTreasury;
        address ammCharlieTreasuryManager;
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

    function addAppointedToRebalanceInAmm(address asset, address account) external;

    function removeAppointedToRebalanceInAmm(address asset, address account) external;

    function isAppointedToRebalanceInAmm(address asset, address account) external view returns (bool);

    function setAmmPoolsParams(
        address asset,
        uint32 newMaxLiquidityPoolBalance,
        uint32 newMaxLpAccountContribution,
        uint32 newAutoRebalanceThresholdInThousands,
        uint16 newAmmTreasuryAndAssetManagementRatio
    ) external;

    function getAmmPoolsParams(address asset) external view returns (StorageLib.AmmPoolsParamsValue memory);
}
