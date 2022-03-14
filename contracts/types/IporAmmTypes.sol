// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library IporAmmTypes {
    enum SwapState {
        INACTIVE,
        ACTIVE
    }
    struct NewSwap {
        address buyer;
        uint256 startingTimestamp;
        uint256 collateral;
        uint256 liquidationDepositAmount;
        uint256 notionalAmount;
        uint256 fixedInterestRate;
        uint256 ibtQuantity;
    }
}
