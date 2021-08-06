// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Errors} from '../Errors.sol';
import {Constants} from '../libraries/Constants.sol';

library SpreadIndicatorLogic {

    function calculateSpread(
        DataTypes.SpreadIndicator storage si,
        uint256 timestamp) public view returns (uint256) {
        //TODO: calculate spread in final way
        return 1e18;
    }
}