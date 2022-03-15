// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library AmmTypes {
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

    struct OpenSwapMoney {
        uint256 totalAmount;
        uint256 collateral;
        uint256 notionalAmount;
        uint256 openingAmount;
        uint256 iporPublicationAmount;
        uint256 liquidationDepositAmount;
    }
}
