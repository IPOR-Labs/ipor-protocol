// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';

contract IporAmmEvents {
}

contract IporAmmV1Events is IporAmmEvents {

    // @notice Open derivative position
    event OpenPosition(
        uint256 indexed derivativeId,
        DataTypes.DerivativeDirection direction,
        address indexed buyer,
        string asset,
        uint256 notionalAmount,
        uint256 depositAmount,
        uint256 startingTime,
        uint256 endingTime,
        uint256 fixedRate,
        uint256 soap,
        uint256 iporIndexValue,
        uint256 ibtPrice,
        uint256 ibtQuantity
    );

    // @notice Close derivative position
    event ClosePosition(
        uint256 indexed derivativeId,
        string asset
        //TODO: figure out what we need in this event
    );
}