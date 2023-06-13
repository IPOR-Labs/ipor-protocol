// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
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

    /// @notice Gets the structure or common params described AMM Pool configuration
    /// @param asset Address of asset which represents specific pool
    /// @return ammPoolsParams Structure of common params described AMM Pool configuration
    function getAmmPoolsParams(address asset) external view returns (StorageLib.AmmPoolsParamsValue memory);
}
