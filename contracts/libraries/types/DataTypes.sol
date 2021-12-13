// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library DataTypes {
    struct MiltonTotalBalance {
        //@notice derivatives balance for Pay Fixed & Receive Floating leg
        uint256 payFixedDerivatives;
        //@notice derivatives balance for Pay Floating & Receive Fixed leg
        uint256 recFixedDerivatives;
        uint256 openingFee;
        uint256 liquidationDeposit;
        uint256 iporPublicationFee;
        //@notice Liquidity Pool Balance includes part of Opening Fee, how many of
        //Opening Fee goes here is defined by param IporAssetConfiguration.openingFeeForTreasurePercentage
        uint256 liquidityPool;
        //@notice income tax goes here, part of opening fee also goes here, how many of Opening Fee goes here is
        //configured here IporAssetConfiguration.openingFeeForTreasurePercentage
        uint256 treasury;
    }

    struct TotalSoapIndicator {
        SoapIndicator pf;
        SoapIndicator rf;
    }

    //soap payfixed and soap recfixed indicators
    struct SoapIndicator {
        uint256 rebalanceTimestamp;
        //TODO: don't have to store - use two separate structure - one for pay fixe, one for rec fixed
        //leg
        DataTypes.DerivativeDirection direction;
        //O_0, value without division by D18 * Constants.YEAR_IN_SECONDS
        uint256 quasiHypotheticalInterestCumulative;
        //N_0
        uint256 totalNotional;
        //I_0
        uint256 averageInterestRate;
        //TT
        uint256 totalIbtQuantity;
        //TODO: don't have to store this - can be calculated in runtime
        //SOAP
        int256 soap;
    }

    //@notice IPOR Structure
    struct IPOR {
        //TODO: remove it - redundant information
        //@notice Asset Symbol like USDT, USDC, DAI etc.
        address asset;
        //@notice IPOR Index Value shown as WAD
        uint256 indexValue;
        //@notice quasi Interest Bearing Token Price, it is IBT Price without division by year in seconds, shown as WAD
        uint256 quasiIbtPrice;
        //@notice exponential moving average - required for calculating SPREAD in Milton, shown as WAD
        uint256 exponentialMovingAverage;
        //@notice block timestamp
        uint256 blockTimestamp;
    }

    //@notice Derivative direction (long = pay fixed and receive a floating or short = receive fixed and pay a floating)
    enum DerivativeDirection {
        //@notice In long position the trader will pay a fixed rate and receive a floating rate.
        PayFixedReceiveFloating,
        //@notice In short position the trader will receive fixed rate and pay a floating rate.
        PayFloatingReceiveFixed
    }

    enum DerivativeState {
        INACTIVE,
        ACTIVE
    }

    struct IporDerivativeInterest {
        //TODO: reduce to one field the last one;
        uint256 quasiInterestFixed;
        uint256 quasiInterestFloating;
        int256 positionValue;
    }

    struct IporDerivativeAmount {
        uint256 deposit;
        uint256 notional;
        uint256 openingFee;
    }

    struct IporDerivativeIndicator {
        //@notice IPOR Index value indicator
        uint256 iporIndexValue;
        //@notice IPOR Interest Bearing Token price
        uint256 ibtPrice;
        //@notice IPOR Interest Bearing Token quantity
        uint256 ibtQuantity;
        //@notice Fixed interest rate at which the position has been locked (IPOR Index Vale +/- spread)
        uint256 fixedInterestRate;
    }

    struct IporDerivativeFee {
        //@notice amount
        uint256 liquidationDepositAmount;
        //TODO: probably don't have to store, add to event
        //@notice amount calculated based on deposit amount
        uint256 openingAmount;
        //TODO: probably don't have to store, add to event
        uint256 iporPublicationAmount;
        //TODO: probably don't have to store, add to event
        //@notice value are basis points
        uint256 spreadPayFixedValue;
        //TODO: probably don't have to store, add to event
        //@notice value are basis points
        uint256 spreadRecFixedValue;
    }

    struct MiltonDerivatives {
        uint256 lastDerivativeId;
        mapping(uint256 => DataTypes.MiltonDerivativeItem) items;
        uint256[] ids;
        mapping(address => uint256[]) userDerivativeIds;
    }

    struct MiltonDerivativeItem {
        DataTypes.IporDerivative item;
        //position in MiltonDerivatives.ids array, can be changed when some derivative is closed
        uint256 idsIndex;
        //position in MiltonDerivatives.userDerivativeIds array, can be changed when some derivative is closed
        uint256 userDerivativeIdsIndex;
    }

    //@notice IPOR Derivative
    struct IporDerivative {
        //@notice unique ID of this derivative
        uint256 id;
        DerivativeState state;
        //@notice Buyer of this derivative
        address buyer;
        //TODO: asset can be removed from storage when Milton per asset
        //@notice the name of the asset to which the derivative relates
        address asset;
        //@notice derivative direction: pay fixed and receive a floating or receive fixed and pay a floating
        uint8 direction;
        //@notice Collateral
        uint256 collateral;
        IporDerivativeFee fee;
        uint256 collateralizationFactor;
        //TODO: remove from storage, can be calculated
        //@notice Notional Principal Amount
        uint256 notionalAmount;
        //@notice Starting time of this Derivative
        uint256 startingTimestamp;
        //@notice Endind time of this Derivative
        uint256 endingTimestamp;
        IporDerivativeIndicator indicator;
    }
}
