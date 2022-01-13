// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IMiltonEvents {
    // @notice Open derivative position
    event OpenPosition(
        uint256 indexed derivativeId,
        address indexed buyer,
        address asset,
        DataTypes.DerivativeDirection direction,
        uint256 collateral,
        DataTypes.IporDerivativeFee fee,
        uint256 collateralizationFactor,
        uint256 notionalAmount,
        uint256 startingTimestamp,
        uint256 endingTimestamp,
        DataTypes.IporDerivativeIndicator indicator
    );

    // @notice Close derivative position
    event ClosePosition(
        uint256 indexed derivativeId,
        address asset,
        uint256 date

        //TODO: figure out what we need in this event
    );

    //TODO: add to event data this state which can be changed during one block!!! configuration/balances/ipor
}
