// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library DataTypes {
    struct MiltonTotalBalance {
		//TODO: reduce to 128
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


    //soap payfixed and soap recfixed indicators
    struct SoapIndicator {
        uint32 rebalanceTimestamp;
        //N_0
        uint128 totalNotional;
        //I_0
		//TODO: reduce to 128
        uint256 averageInterestRate;
        //TT
		//TODO: reduce to 128
        uint256 totalIbtQuantity;

		//O_0, value without division by D18 * Constants.YEAR_IN_SECONDS
		//TODO: reduce to 128
        uint256 quasiHypotheticalInterestCumulative;
        
    }

    //@notice IPOR Structure
    struct IPOR {
		//TODO: reduce to 128
        //TODO: remove it - redundant information
        //@notice Asset Symbol like USDT, USDC, DAI etc.
        address asset;
        //@notice IPOR Index Value shown as WAD
        uint256 indexValue;
        //@notice quasi Interest Bearing Token Price, it is IBT Price without division by year in seconds, shown as WAD
        uint256 quasiIbtPrice;
        //@notice exponential moving average - required for calculating SPREAD in Milton, shown as WAD
        uint256 exponentialMovingAverage;
		//@notice exponential weighted moving variance - required for calculating SPREAD in Milton, shown as WAD 
        uint256 exponentialWeightedMovingVariance;
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

	struct BeforeOpenSwapStruct {
		uint256 wadTotalAmount;
		uint256 collateral;
		uint256 notional;
		uint256 openingFee;
		uint256 liquidationDepositAmount;
		uint256 decimals;
		uint256 iporPublicationFeeAmount;
	}

    struct IporDerivativeInterest {
        //TODO: reduce to one field the last one;
        uint256 quasiInterestFixed;
        uint256 quasiInterestFloating;
        int256 positionValue;
    }
    struct IporDerivativeIndicator {		
        //@notice IPOR Index value indicator
        uint256 iporIndexValue;
        //@notice IPOR Interest Bearing Token price
        uint256 ibtPrice;
        //@notice IPOR Interest Bearing Token quantity
        uint256 ibtQuantity;
        //@notice Fixed interest rate at which the position has been locked (Refference leg +/- spread per leg), it is quote from spread documentation
        uint256 fixedInterestRate;
    }
	
    struct MiltonDerivatives {
        mapping(uint256 => DataTypes.MiltonDerivativeItem) items;
        uint256[] ids;
        mapping(address => uint256[]) userDerivativeIds;
    }

	//TODO: move storage structure to storage smart contract
    struct MiltonDerivativeItem {
        DataTypes.IporDerivative item;
        //position in MiltonDerivatives.ids array, can be changed when some derivative is closed
        uint256 idsIndex;
        //position in MiltonDerivatives.userDerivativeIds array, can be changed when some derivative is closed
        uint256 userDerivativeIdsIndex;
    }

    //@notice IPOR Derivative
	//TODO: move storage structure to storage smart contract
    struct IporDerivative {
        DerivativeState state;
		//@notice Buyer of this derivative
        address buyer;
        //TODO: asset can be removed from storage when Milton per asset
        //@notice the name of the asset to which the derivative relates
        address asset;
		//@notice Starting time of this Derivative
		uint32 startingTimestamp;
		//@notice Endind time of this Derivative
		uint32 endingTimestamp;
		//@notice unique ID of this derivative
        uint64 id;        
        uint128 collateral;
		uint128 liquidationDepositAmount;
        //@notice Notional Principal Amount
        uint128 notionalAmount;        
		uint128 fixedInterestRate;
		uint128 ibtQuantity;
    }
}
