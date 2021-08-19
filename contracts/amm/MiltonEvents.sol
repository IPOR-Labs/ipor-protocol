// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';

contract MiltonEvents {
}

contract MiltonV1Events is MiltonEvents {

    event LogDepositReceived(address _sender);

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
        bytes32 asset,
        uint256 date
    //TODO: figure out what we need in this event
    );

    event TotalBalances (
        bytes32 asset,
        uint256 token,
        uint256 derivative,
        uint256 openingFee,
        uint256 liquidationDepositFee,
        uint256 iporPublicationFee,
        uint256 liquidityPool
    );
}