// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
import "../libraries/StorageLib.sol";

interface IAmmGovernanceLens {
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

    function isSwapLiquidator(address asset, address account) external view returns (bool);

    function isAppointedToRebalanceInAmm(address asset, address account) external view returns (bool);

    function getAmmPoolsParams(address asset) external view returns (StorageLib.AmmPoolsParamsValue memory);
}
