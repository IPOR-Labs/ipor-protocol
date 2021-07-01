// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {Errors} from '../Errors.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IIporOracle.sol";
import './IporAmmStorage.sol';
import './IporAmmEvents.sol';
import './IporPool.sol';

/**
 * @title Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
contract IporAmmV1 is IporAmmV1Storage, IporAmmV1Events {

    IIporOracle public iporOracle;

    //@notice By default every derivative takes 28 days, this variable show this value in seconds
    uint256 constant DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = 60 * 60 * 24 * 28;

    constructor(address _iporOracle, address _usdtPool, address _usdcPool, address _daiPool) {

        admin = msg.sender;

        iporOracle = IIporOracle(_iporOracle);

        pools["USDT"] = _usdtPool;
        pools["USDC"] = _usdcPool;
        pools["DAI"] = _daiPool;

    }

    /**
    * @notice Trader open new derivative position. Depending on the direction it could be derivative
    * where trader pay fixed and receive a floating (long position) or receive fixed and pay a floating.
    * @param _asset symbol of asset of the derivative
    * @param _notionalAmount value of notional principal amount (reference or theoretical amount) on which the exchanged interest payments are based
    * @param _depositAmount value of asset which is deposited for this derivative
    * @param _direction pay fixed and receive a floating (trader assume that interest rate will increase)
    * or receive a floating and pay fixed (trader assume that interest rate will decrease)
    * In a long position the trader will pay a fixed rate and receive a floating rate.
    */
    function openPosition(
        string memory _asset,
        uint256 _notionalAmount,
        uint256 _depositAmount,
        uint256 _maximumSlippage,
        uint8 _direction) public {

        require(_notionalAmount > 0, Errors.AMM_NOTIONAL_AMOUNT_TOO_LOW);
        require(_notionalAmount <= 1e18, Errors.AMM_NOTIONAL_AMOUNT_TOO_HIGH);
        require(_depositAmount > 0, Errors.AMM_DEPOSIT_AMOUNT_TOO_LOW);
        require(_depositAmount <= 1e18, Errors.AMM_DEPOSIT_AMOUNT_TOO_HIGH);
        require(_maximumSlippage > 0, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_LOW);
        require(_maximumSlippage <= 1e18, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_HIGH);
        require(_notionalAmount > _depositAmount, Errors.AMM_NOTIONAL_AMOUNT_NOT_GREATER_THAN_DEPOSIT_AMOUNT);
        require(pools[_asset] != address(0), Errors.AMM_LIQUIDITY_POOL_NOT_EXISTS);
        require(_direction <= uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed), Errors.AMM_DERIVATIVE_DIRECTION_NOT_EXISTS);

        //TODO: calculate Exchange Rate and SOAP


        //TODO: BEGIN - calculate derivative indicators
        //        uint256 spread = _calculateSpread();
        //        uint256 fee = _calculateFee();
        //TODO: calculate Opening Fee
        //TODO: calculate liquidataion Fee
        //TODO: maybe calculate earlyTerminationFee

        //TODO: calculate IBT quantity - notinalAmount / IBT price
        //TODO: calculate IBT price - from oracle


        //        uint256 gas = _calculateGasForIporPublishing();
        //        uint256 fixedRate = 10;

        (uint256 iporIndexValue,uint256  ibtPrice,uint256  blockTimestamp) = iporOracle.getIndex(_asset);

        //uint256 soap = 10000;
        //TODO: END - calculate derivative indicators

        uint256 startingTime = block.timestamp;
        uint256 endingTime = startingTime + DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS;

        nextDerivativeId++;
        //        address pool = pools[_asset];
        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
            10,
            10000,
            iporIndexValue, ibtPrice,
            300 //ibtQuantity,
        );
        derivatives.push(
            DataTypes.IporDerivative(
                nextDerivativeId,
                _direction,
                msg.sender,
                _asset,
                _notionalAmount,
                _depositAmount,
                startingTime,
                endingTime,
                indicator
            )
        );

        //        emit OpenPosition(
        //            nextDerivativeId,
        //            DataTypes.DerivativeDirection(_direction),
        //            msg.sender,
        //            _asset,
        //            _notionalAmount,
        //            _depositAmount,
        //            startingTime,
        //            endingTime,
        //            10,
        //            10000,
        //            iporIndexValue,
        //            222, //ibtPrice
        //            333 //ibtQuantity
        //        );
    }

    function getOpenPositions() external view returns (DataTypes.IporDerivative[] memory) {
        DataTypes.IporDerivative[] memory _derivatives = new DataTypes.IporDerivative[](derivatives.length);

        for (uint256 i = 0; i < derivatives.length; i++) {
            DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
                derivatives[i].indicator.fixedRate,
                derivatives[i].indicator.soap,
                derivatives[i].indicator.iporIndexValue,
                derivatives[i].indicator.ibtPrice,
                derivatives[i].indicator.ibtQuantity
            );
            _derivatives[i] = DataTypes.IporDerivative(
                derivatives[i].id,
                derivatives[i].direction,
                derivatives[i].buyer,
                derivatives[i].asset,
                derivatives[i].notionalAmount,
                derivatives[i].depositAmount,
                derivatives[i].startingTimestamp,
                derivatives[i].endingTimestamp,
                indicator
            );
        }


        return _derivatives;

    }

    function closePosition(uint256 _derivativeId) public {
        //TODO: calculate Exchange Rate and SOAP
        //TODO: closeTrade
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `3`, a balance of `707` tokens should
     * be displayed to a user as `0,707` (`707 / 10 ** 3`).
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function withdrawGas() public {
        //TODO:
    }

    function rebalanceSoap() internal {
        //TODO:
    }

    function calculatePrice() public {
        //TODO: _calculateSpread, _calculateFee

    }

    function _calculateGasForIporPublishing() internal returns (uint256){
        //TODO:
        return 4;
    }

    function _chargeGas() internal {
        //TODO:
    }

    function _calculateFee() internal returns (uint256) {
        //TODO:
        return 1;
    }

    function _calculateSpread() internal returns (uint256) {
        //TODO:
        return 3;
    }

    function _calculateClosingFee() internal returns (uint256) {
        //TODO:
        return 2;
    }

    function readIndex(string memory _ticker) external view returns (uint256 value, uint256 interestBearingToken, uint256 date)  {
        (uint256 _value, uint256 _interestBearingToken, uint256 _date) = iporOracle.getIndex(_ticker);
        return (_value, _interestBearingToken, _date);
    }

    /**
     * @notice Modifier which checks if caller is admin for this contract
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, Errors.CALLER_NOT_IPOR_ORACLE_ADMIN);
        _;
    }
}