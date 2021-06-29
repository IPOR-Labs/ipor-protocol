// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

library DataTypes {

    //@notice IPOR Index structure
    struct IporIndex {

        //@notice Asset Symbol like USDT, USDC, DAI etc.
        string asset;

        //@notice IPOR Index Value
        uint256 value;

        //@notice Interest Bearing Token Price
        uint256 ibtPrice;

        //@notice block timestamp
        uint256 blockTimestamp;
    }

    enum DerivativeDirection {

        //@notice In long position the trader will pay a fixed rate and receive a floating rate.
        PayFixedReceiveFloating,

        //@notice In short position the trader will receive fixed rate and pay a floating rate.
        PayFloatingReceiveFixed
    }

    //@notice IPOR Derivative
    struct IporDerivative {

        //@notice unique ID of this derivative
        uint256 id;

        //@notice Buyer of this derivative
        address buyer;

        //@notice the name of the asset to which the derivative relates
        string asset;

        //@notice Notional Principal Amount
        uint256 notionalAmount;

        //@notice Derivative deposit amount
        uint256 depositAmount;

        //@notice Starting time of this Derivative
        uint256 startingTimestamp;

        //@notice Endind time of this Derivative
        uint256 endingTimestamp;

        //@notice Fixed Rate
        uint256 fixedRate;

        //@notice SOAP - Sum Of All Payouts indicator
        uint256 soap;

        //@notice IPOR Index value indicator
        uint256 iporIndexValue;

        //@notice IPOR Interest Bearing Token price
        uint256 ibtPrice;

        //@notice IPOR Interest Bearing Token quantity
        uint256 ibtQuantity;


    }
}