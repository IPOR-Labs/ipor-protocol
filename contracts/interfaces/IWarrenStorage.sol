// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IWarrenStorage {

    function getAssets() external view returns (address[] memory);

    function getIndex(address asset) external view returns (DataTypes.IPOR memory);

    function updateIndexes(address[] memory assets, uint256[] memory indexValues, uint256 updateTimestamp) external;

    function addUpdater(address updater) external;

    function removeUpdater(address updater) external;

    function getUpdaters() external view returns (address[] memory);
}
