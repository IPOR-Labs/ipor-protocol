// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "../libraries/StorageLib.sol";

interface IAmmGovernanceService {
    function depositToAssetManagement(address asset, uint256 assetAmount) external;

    function withdrawFromAssetManagement(address asset, uint256 assetAmount) external;

    function withdrawAllFromAssetManagement(address asset) external;

    function transferToTreasury(address asset, uint256 assetAmount) external;

    function transferToCharlieTreasury(address asset, uint256 assetAmount) external;

    function addSwapLiquidator(address asset, address account) external;

    function removeSwapLiquidator(address asset, address account) external;

    function addAppointedToRebalanceInAmm(address asset, address account) external;

    function removeAppointedToRebalanceInAmm(address asset, address account) external;

    function setAmmPoolsParams(
        address asset,
        uint32 newMaxLiquidityPoolBalance,
        uint32 newMaxLpAccountContribution,
        uint32 newAutoRebalanceThresholdInThousands,
        uint16 newAmmTreasuryAndAssetManagementRatio
    ) external;
}
