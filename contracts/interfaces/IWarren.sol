// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IWarren {    
	
	function getAssets() external view returns (address[] memory);
    function getIndex(address asset)
        external
        view
        returns (
            uint256 value,
            uint256 ibtPrice,
            uint256 exponentialMovingAverage,
            uint256 exponentialWeightedMovingVariance,
            uint256 date
        );

    function getAccruedIndex(uint256 calculateTimestamp, address asset)
        external
		view
        returns (DataTypes.AccruedIpor memory accruedIpor);

    function updateIndex(address asset, uint256 indexValue) external;

    function updateIndexes(
        address[] memory assets,
        uint256[] memory indexValues
    ) external;

    function calculateAccruedIbtPrice(address asset, uint256 calculateTimestamp)
        external
        view
        returns (uint256);
}
