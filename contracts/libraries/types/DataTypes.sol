// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library DataTypes {

	struct MiltonTotalBalanceMemory {
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
    struct MiltonTotalBalanceStorage {
		//TODO: reduce to 128
        //@notice derivatives balance for Pay Fixed & Receive Floating leg
         uint128 payFixedDerivatives;
        //@notice derivatives balance for Pay Floating & Receive Fixed leg
         uint128 recFixedDerivatives;
        uint128 openingFee;
        uint128 liquidationDeposit;
        uint128 iporPublicationFee;
        //@notice Liquidity Pool Balance includes part of Opening Fee, how many of
        //Opening Fee goes here is defined by param IporAssetConfiguration.openingFeeForTreasurePercentage
        uint128 liquidityPool;
        //@notice income tax goes here, part of opening fee also goes here, how many of Opening Fee goes here is
        //configured here IporAssetConfiguration.openingFeeForTreasurePercentage
        uint128 treasury;
    }


    //soap payfixed and soap recfixed indicators
    struct SoapIndicatorStorage {
        uint32 rebalanceTimestamp;
        //N_0
        uint128 totalNotional;
        //I_0
		//TODO: reduce to 128
        uint128 averageInterestRate;
        //TT
		//TODO: reduce to 128
        uint128 totalIbtQuantity;

		//O_0, value without division by D18 * Constants.YEAR_IN_SECONDS
		//TODO: reduce to 128
        uint256 quasiHypotheticalInterestCumulative;
        
    }

	struct SoapIndicatorMemory {
        uint256 rebalanceTimestamp;
        //N_0
        uint256 totalNotional;
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
		//@notice block timestamp
        uint32 blockTimestamp;		
        //@notice IPOR Index Value shown as WAD
        uint128 indexValue;
        //@notice quasi Interest Bearing Token Price, it is IBT Price without division by year in seconds, shown as WAD
        uint128 quasiIbtPrice;
        //@notice exponential moving average - required for calculating SPREAD in Milton, shown as WAD
        uint128 exponentialMovingAverage;
		//@notice exponential weighted moving variance - required for calculating SPREAD in Milton, shown as WAD 
        uint128 exponentialWeightedMovingVariance;
        
    }
    //@notice Derivative direction (long = pay fixed and receive a floating or short = receive fixed and pay a floating)
    enum DerivativeDirection {
		//TODO: use consistent names in enums
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
	
    struct MiltonDerivativesStorage {
        uint256[] ids;
		mapping(uint256 => DataTypes.MiltonDerivativeItemStorage) items;        
        mapping(address => uint256[]) userDerivativeIds;
    }

	//TODO: move storage structure to storage smart contract
    struct MiltonDerivativeItemStorage {
        //position in MiltonDerivatives.ids array, can be changed when some derivative is closed
        uint64 idsIndex;
		//position in MiltonDerivatives.userDerivativeIds array, can be changed when some derivative is closed
        uint64 userDerivativeIdsIndex;
		DataTypes.IporDerivativeStorage item;
    }

	struct MiltonDerivativeItemMemory {
        //position in MiltonDerivatives.ids array, can be changed when some derivative is closed
        uint256 idsIndex;
		//position in MiltonDerivatives.userDerivativeIds array, can be changed when some derivative is closed
        uint256 userDerivativeIdsIndex;
		DataTypes.IporDerivativeMemory item;
    }

	struct IporDerivativeMemory {
        uint256 state;
		//@notice Buyer of this derivative
        address buyer;
		//@notice Starting time of this Derivative
		uint256 startingTimestamp;
		//@notice Endind time of this Derivative
		uint256 endingTimestamp;
		//@notice unique ID of this derivative
        uint256 id;        
        uint256 collateral;
		uint256 liquidationDepositAmount;
        //@notice Notional Principal Amount
        uint256 notionalAmount;        
		uint256 fixedInterestRate;
		uint256 ibtQuantity;
    }
    //@notice IPOR Derivative
	//TODO: move storage structure to storage smart contract
    struct IporDerivativeStorage {
        DerivativeState state;
		//@notice Buyer of this derivative
        address buyer;
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
