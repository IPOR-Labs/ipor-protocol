// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IMiltonEvents {
    // @notice Open derivative position
    event OpenSwap(
        uint256 indexed swapId,
        address indexed buyer,
        address asset,
        DataTypes.SwapDirection direction,
        uint256 collateral,
        uint256 liquidationDepositAmount,
        uint256 notionalAmount,
        uint256 startingTimestamp,
        uint256 endingTimestamp,
        DataTypes.IporSwapIndicator indicator,
        uint256 openingAmount,
        uint256 iporPublicationAmount,
        uint256 spreadValue
    );

    // @notice Close derivative position
    event CloseSwap(
        uint256 indexed swapId,
        address asset,
        uint256 closeTimestamp
    );
}
