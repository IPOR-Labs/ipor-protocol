// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';

interface IWarren {

    function removeUpdater(address _updater) external;

    function getUpdaters() external view returns (address[] memory);
    /**
     * @notice Return IPOR index for specific asset
     * @param _ticker The ticker of the asset
     * @return value then value of IPOR Index for asset with ticker name _ticker
     * @return ibtPrice interest bearing token in this particular moment
     * @return date date when IPOR Index was calculated for asset
     *
     */
    function getIndex(string memory _ticker) external view returns (uint256 value, uint256 ibtPrice, uint256 date);

    function getIndexes() external view returns (DataTypes.IporFront[] memory);

    function updateIndex(string memory _asset, uint256 _indexValue) external;

    function updateIndexes(string[] memory _assets, uint256[] memory _indexValues) external;

    function calculateAccruedIbtPrice(string memory asset, uint256 calculateTimestamp) external view returns (uint256);

}