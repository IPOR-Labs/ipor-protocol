// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library IporTypes {
    struct AccruedIpor {
        uint256 indexValue;
        uint256 ibtPrice;
        uint256 exponentialMovingAverage;
        uint256 exponentialWeightedMovingVariance;
    }

    struct IporSwapMemory {
        uint256 state;
        //@notice Buyer of this swap
        address buyer;
        //@notice Starting time of this swap
        uint256 startingTimestamp;
        //@notice Endind time of this swap
        uint256 endingTimestamp;
        //@notice unique ID of this swap
        uint256 id;
        uint256 idsIndex;
        uint256 collateral;
        uint256 liquidationDepositAmount;
        //@notice Notional Principal Amount
        uint256 notionalAmount;
        uint256 fixedInterestRate;
        uint256 ibtQuantity;
    }

    //@dev all balances in 18 decimals
    struct MiltonBalancesMemory {
        //@notice derivatives balance for Pay Fixed & Receive Floating leg
        uint256 payFixedSwaps;
        //@notice derivatives balance for Pay Floating & Receive Fixed leg
        uint256 receiveFixedSwaps;
        //@notice Liquidity Pool Balance includes part of Opening Fee, how many of
        //Opening Fee goes here is defined by param IporAssetConfiguration.openingFeeForTreasurePercentage
        uint256 liquidityPool;
        uint256 vault;
    }
}
