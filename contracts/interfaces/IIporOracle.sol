// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';

interface IIporOracle {

    /**
     * @notice Return IPOR index for specific asset
     * @param _ticker The ticker of the asset
     * @return value then value of IPOR Index for asset with ticker name _ticker
     * @return interestBearingToken interest bearing token in this particular moment
     * @return date date when IPOR Index was calculated for asset
     *
     */
    function getIndex(string memory _ticker) external view returns (uint256 value, uint256 interestBearingToken, uint256 date);

}