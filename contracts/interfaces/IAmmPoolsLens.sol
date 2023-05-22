// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IAmmPoolsLens {
    struct PoolConfiguration {
        address asset;
        uint256 decimals;
        address ipToken;
        address ammStorage;
        address ammTreasury;
        address assetManagement;
    }

    function getPoolConfiguration(address asset) external view returns (PoolConfiguration memory);

    function getExchangeRate(address asset) external view returns (uint256);
}
