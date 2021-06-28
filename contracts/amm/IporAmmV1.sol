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

    uint256 constant ONE_MONTH_SECONDS = 60 * 60 * 24 * 30;

    constructor(address _iporOracle, address _usdtPool, address _usdcPool, address _daiPool) {
        admin = msg.sender;
        iporOracle = IIporOracle(_iporOracle);
        pools["USDT"] = _usdtPool;
        pools["USDC"] = _usdcPool;
        pools["DAI"] = _daiPool;

    }

    /**
    * @notice function called by trader to enter into long derivative position
    * In a long position the trader will pay a fixed rate and receive a floating rate.
    */
    function openPosition(
        string memory _asset,
        uint256 _notionalAmount,
        uint256 _depositAmount,
        uint256 _maximumSlippage,
        DataTypes.DerivativeDirection direction) public {

        require(_notionalAmount > 0, Errors.AMM_NOTIONAL_AMOUNT_TOO_LOW);
        require(_depositAmount > 0, Errors.AMM_DEPOSIT_AMOUNT_TOO_LOW);
        require(_maximumSlippage > 0, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_LOW);
        //TODO: check to hight positions
        //TODO: confirm if notional >= deposit


        //TODO: BEGIN - calculate derivative indicators
        uint256 spread = _calculateSpread();
        uint256 fee = _calculateFee();
        //TODO: calculate Opening Fee
        //TODO: calculate liquidataion Fee
        //TODO: maybe calculate earlyTerminationFee

        //TODO: calculate IBT quantity - notinalAmount / IBT price
        //TODO: calculate IBT price - from oracle


        uint256 gas = _calculateGasForIporPublishing();
        uint256 fixedRate = 10;
        uint256 iporIndexValue = 3;

        //uint256 soap = 10000;
        //TODO: END - calculate derivative indicators

        uint256 startingTime = block.timestamp;
        uint256 endingTime = startingTime + ONE_MONTH_SECONDS;

        nextDerivativeId++;

        payFixedPositions[keccak256(abi.encodePacked(_asset))].push(
            DataTypes.IporDerivative(
                nextDerivativeId,
                msg.sender,
                _asset,
                _notionalAmount,
                _depositAmount,
                startingTime,
                endingTime,
                fixedRate,
                    10000,
                iporIndexValue,
        130, //ibtPrice,
                300 //ibtQuantity
            )
        );

        emit OpenPosition(
            nextDerivativeId,
            direction,
            msg.sender,
                _asset,
            _notionalAmount,
            _depositAmount,
            startingTime,
            endingTime,
            fixedRate,
                10000,
            iporIndexValue,
            222, //ibtPrice
            333 //ibtQuantity
        );
    }

    function closeShortPosition(uint256 _derivativeId) public {
        //TODO: closeTrade
    }

    function closeLongPosition(uint256 _derivativeId) public {
        //TODO: closeTrade
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