// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "../../../interfaces/types/AmmTypes.sol";

library AmmMiltonStorageTypes {
    struct IporSwap {
        AmmTypes.SwapState state;
        //@notice Starting time of this swap
        uint32 openTimestamp;
        //@notice unique ID of this swap
        //@notice Buyer of this swap
        address buyer;
        uint64 id;
        uint64 idsIndex;
        uint128 collateral;
        uint128 liquidationDepositAmount;
        //@notice Notional Principal Amount
        uint128 notional;
        uint128 fixedInterestRate;
        uint128 ibtQuantity;
    }

    //@notice All active swaps available in Milton with information which swaps belong to account
    struct IporSwapContainer {
        //@notice swap details, key in map is a swapId
        mapping(uint128 => IporSwap) swaps;
        //@notice list of swap ids per account, key is account address, value is a list of swap ids
        mapping(address => uint128[]) ids;
    }

    //@dev all balances in 18 decimals
    struct Balances {
        //@notice derivatives balance for Pay Fixed & Receive Floating leg
        uint128 totalCollateralPayFixed;
        //@notice derivatives balance for Pay Floating & Receive Fixed leg
        uint128 totalCollateralReceiveFixed;
        //@notice Liquidity Pool Balance includes part of Opening Fee, how many of
        //Opening Fee goes here is defined by param IporAssetConfiguration.openingFeeForTreasureRate
        uint128 liquidityPool;
        //@notice Actual Balance on IporVault site in Asset Management
        uint128 vault;
        uint128 iporPublicationFee;
        //@notice income fee goes here, part of opening fee also goes here, how many of Opening Fee goes here is
        //configured here IporAssetConfiguration.openingFeeForTreasureRate
        uint128 treasury;
    }

    //soap payfixed and soap recfixed indicators
    struct SoapIndicators {
        uint32 rebalanceTimestamp;
        //N_0
        uint128 totalNotional;
        //I_0
        uint128 averageInterestRate;
        //TT
        uint128 totalIbtQuantity;
        //O_0, value without division by D18 * Constants.YEAR_IN_SECONDS
        uint256 quasiHypotheticalInterestCumulative;
    }

    struct SoapIndicatorsMemory {
        uint256 rebalanceTimestamp;
        //N_0
        uint256 totalNotional;
        //I_0
        uint256 averageInterestRate;
        //TT
        uint256 totalIbtQuantity;
        //O_0, value without division by D18 * Constants.YEAR_IN_SECONDS
        uint256 quasiHypotheticalInterestCumulative;
    }
}
