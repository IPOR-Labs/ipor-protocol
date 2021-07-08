// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';

contract IporAmmEvents {
}

contract IporAmmV1Events is IporAmmEvents {

    // @notice Open derivative position
    event OpenPosition(
        uint256 indexed derivativeId,
        address indexed buyer,
        string asset,
        DataTypes.DerivativeDirection direction,
        uint256 depositAmount,
        DataTypes.IporDerivativeFee fee,
        uint256 leverage,
        uint256 notionalAmount,
        uint256 startingTimestamp,
        uint256 endingTimestamp,
        DataTypes.IporDerivativeIndicator indicator
    );

    // @notice Close derivative position
    event ClosePosition(
        uint256 indexed derivativeId,
        string asset
        //TODO: figure out what we need in this event
    );
}