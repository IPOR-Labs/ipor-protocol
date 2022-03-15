// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library MiltonStorageTypes {
    struct IporSwapId {
        uint256 id;
        uint8 direction;
    }

    struct ExtendedBalancesMemory {
        //@notice derivatives balance for Pay Fixed & Receive Floating leg
        uint256 payFixedSwaps;
        //@notice derivatives balance for Pay Floating & Receive Fixed leg
        uint256 receiveFixedSwaps;
        //@notice Liquidity Pool Balance includes part of Opening Fee, how many of
        //Opening Fee goes here is defined by param IporAssetConfiguration.openingFeeForTreasurePercentage
        uint256 liquidityPool;
        //@notice Actual Balance on IporVault site in Asset Management
        uint128 vault;
        uint256 openingFee;
        uint256 liquidationDeposit;
        uint256 iporPublicationFee;
        //@notice income fee goes here, part of opening fee also goes here, how many of Opening Fee goes here is
        //configured here IporAssetConfiguration.openingFeeForTreasurePercentage
        uint256 treasury;
    }
}
