// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";

interface IWarrenStorage {

    function getAssets() external view returns (bytes32[] memory);

    function getIndex(bytes32 asset) external view returns (DataTypes.IPOR memory);

    function updateIndexes(string[] memory _assets, uint256[] memory _indexValues, uint256 updateTimestamp) external;

    function addUpdater(address updater) external;

    function removeUpdater(address updater) external;

    function getUpdaters() external view returns (address[] memory);
}
