// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

library AmmOpenSwapTypes {
    struct OpenSwapPoolConfiguration {
        address asset;
        uint256 decimals;
        address ammStorage;
        address ammTreasury;
        uint256 iporPublicationFee;
        uint256 maxSwapCollateralAmount;
        uint256 liquidationDepositAmount;
        uint256 minLeverage;
        uint256 openingFeeRate;
        uint256 openingFeeTreasuryPortionRate;
    }
}
