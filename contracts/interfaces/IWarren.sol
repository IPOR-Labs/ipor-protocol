// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';

interface IWarren {

    function pause() external;

    function unpause() external;

    function getIndex(address asset) external view returns (
        uint256 value, uint256 ibtPrice, uint256 exponentialMovingAverage, uint256 date);

    function updateIndex(address asset, uint256 indexValue) external;

    function updateIndexes(address[] memory assets, uint256[] memory indexValues) external;

    function calculateAccruedIbtPrice(address asset, uint256 calculateTimestamp) external view returns (uint256);

}
