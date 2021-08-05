// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Errors} from '../Errors.sol';
import {Constants} from '../libraries/Constants.sol';

library IporLogic {

    function accrueIbtPrice(DataTypes.IPOR memory ipor, uint256 accrueTimestamp) public pure returns (uint256){
        return ipor.ibtPrice
        + (ipor.indexValue * ((accrueTimestamp - ipor.blockTimestamp) * Constants.MILTON_DECIMALS_FACTOR))
        / Constants.YEAR_IN_SECONDS_WITH_FACTOR;
    }
}