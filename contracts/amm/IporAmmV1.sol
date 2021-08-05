// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";
import "../libraries/DerivativeLogic.sol";
import "../libraries/AmmMath.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Errors} from '../Errors.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IIporOracle.sol";
import './IporAmmStorage.sol';
import './IporAmmEvents.sol';
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/TotalSoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";



/**
 * @title Milton - Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
contract IporAmmV1 is IporAmmV1Storage, IporAmmV1Events {

    using DerivativeLogic for DataTypes.IporDerivative;
    using SoapIndicatorLogic for DataTypes.SoapIndicator;
    using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;
    using DerivativesView for DataTypes.IporDerivative[];

    IIporOracle public iporOracle;

    //@notice percentage of deposit amount
    uint256 constant SPREAD_FEE_PERCENTAGE = 1e16;

    constructor(address iporOracleAddr, address usdtToken, address usdcToken, address daiToken) {

        admin = msg.sender;

        iporOracle = IIporOracle(iporOracleAddr);

        tokens["USDT"] = usdtToken;
        tokens["USDC"] = usdcToken;
        tokens["DAI"] = daiToken;

        uint256 blockTimestamp = block.timestamp;

        soapIndicators["USDT"] = DataTypes.TotalSoapIndicator(
            DataTypes.SoapIndicator(blockTimestamp, DataTypes.DerivativeDirection.PayFixedReceiveFloating, 0, 0, 0, 0, 0),
            DataTypes.SoapIndicator(blockTimestamp, DataTypes.DerivativeDirection.PayFloatingReceiveFixed, 0, 0, 0, 0, 0)
        );

        soapIndicators["USDC"] = DataTypes.TotalSoapIndicator(
            DataTypes.SoapIndicator(blockTimestamp, DataTypes.DerivativeDirection.PayFixedReceiveFloating, 0, 0, 0, 0, 0),
            DataTypes.SoapIndicator(blockTimestamp, DataTypes.DerivativeDirection.PayFloatingReceiveFixed, 0, 0, 0, 0, 0)
        );

        soapIndicators["DAI"] = DataTypes.TotalSoapIndicator(
            DataTypes.SoapIndicator(blockTimestamp, DataTypes.DerivativeDirection.PayFixedReceiveFloating, 0, 0, 0, 0, 0),
            DataTypes.SoapIndicator(blockTimestamp, DataTypes.DerivativeDirection.PayFloatingReceiveFixed, 0, 0, 0, 0, 0)
        );

        //TODO: allow admin to setup it during runtime
        closingFeePercentage = 0;
        nextDerivativeId = 0;

    }

    function calculateSoap(string memory asset) public view returns (int256 soapPf, int256 soapRf, int256 soap) {
        (int256 _soapPf, int256 _soapRf, int256 _soap) = _calculateSoap(asset, block.timestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    //    fallback() external payable  {
    //        require(msg.data.length == 0); emit LogDepositReceived(msg.sender);
    //    }

    function _calculateSoap(
        string memory asset,
        uint256 calculateTimestamp) internal view returns (int256 soapPf, int256 soapRf, int256 soap){
        (, uint256 ibtPrice,) = iporOracle.getIndex(asset);
        (int256 _soapPf, int256 _soapRf) = soapIndicators[asset].calculateSoap(calculateTimestamp, ibtPrice);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soapPf + _soapRf);
    }

    function openPosition(
        string memory asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint8 leverage,
        uint8 direction) public returns (uint256){
        return _openPosition(block.timestamp, asset, totalAmount, maximumSlippage, leverage, direction);
    }

    function closePosition(uint256 derivativeId) onlyActiveDerivative(derivativeId) public {
        _closePosition(derivativeId, block.timestamp);
    }

    function _openPosition(
        uint256 openTimestamp,
        string memory asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint8 leverage,
        uint8 direction) internal returns (uint256) {

        //TODO: confirm if _totalAmount always with 18 ditigs or what? (appeared question because this amount contain fee)
        //TODO: _totalAmount multiply if required based on _asset

        require(leverage > 0, Errors.AMM_LEVERAGE_TOO_LOW);
        require(totalAmount > 0, Errors.AMM_TOTAL_AMOUNT_TOO_LOW);
        require(totalAmount > Constants.LIQUIDATION_DEPOSIT_FEE_AMOUNT + Constants.IPOR_PUBLICATION_FEE_AMOUNT, Errors.AMM_TOTAL_AMOUNT_LOWER_THAN_FEE);
        require(totalAmount <= 1e24, Errors.AMM_TOTAL_AMOUNT_TOO_HIGH);
        require(maximumSlippage > 0, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_LOW);
        require(maximumSlippage <= 1e20, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_HIGH);
        require(tokens[asset] != address(0), Errors.AMM_LIQUIDITY_POOL_NOT_EXISTS);
        require(direction <= uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed), Errors.AMM_DERIVATIVE_DIRECTION_NOT_EXISTS);
        require(IERC20(tokens[asset]).balanceOf(msg.sender) >= totalAmount, Errors.AMM_ASSET_BALANCE_OF_TOO_LOW);

        //TODO consider check if it is smart contract, if yes then revert
        //TODO verify if this opened derivatives is closable based on liquidity pool
        //TODO: add configurable parameter which describe utilization rate of liquidity pool (total deposit amount / total liquidity)

        DataTypes.IporDerivativeAmount memory derivativeAmount = AmmMath.calculateDerivativeAmount(totalAmount, leverage);
        require(totalAmount > Constants.LIQUIDATION_DEPOSIT_FEE_AMOUNT + Constants.IPOR_PUBLICATION_FEE_AMOUNT + derivativeAmount.openingFee,
            Errors.AMM_TOTAL_AMOUNT_LOWER_THAN_FEE);

        DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
            Constants.LIQUIDATION_DEPOSIT_FEE_AMOUNT,
            derivativeAmount.openingFee,
            Constants.IPOR_PUBLICATION_FEE_AMOUNT,
            SPREAD_FEE_PERCENTAGE);

        DataTypes.IporDerivativeIndicator memory iporDerivativeIndicator = _calculateDerivativeIndicators(asset, direction, derivativeAmount.notional);

        DataTypes.IporDerivative memory iporDerivative = DataTypes.IporDerivative(
            nextDerivativeId,
            DataTypes.DerivativeState.ACTIVE,
            msg.sender,
            asset,
            direction,
            derivativeAmount.deposit,
            fee,
            leverage,
            derivativeAmount.notional,
            openTimestamp,
            openTimestamp + Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
            iporDerivativeIndicator
        );
        derivatives.push(iporDerivative);

        nextDerivativeId++;

        _updateBalances(asset, derivativeAmount);

        soapIndicators[asset].rebalanceSoapWhenOpenPosition(
            direction,
            openTimestamp,
            derivativeAmount.notional,
            iporDerivativeIndicator.fixedInterestRate,
            iporDerivativeIndicator.ibtQuantity
        );

        IERC20(tokens[asset]).transferFrom(msg.sender, address(this), totalAmount);

        _emitOpenPositionEvent(iporDerivative);

        //TODO: clarify if ipAsset should be transfered to trader when position is opened

        return iporDerivative.id;
    }

    function _emitOpenPositionEvent(DataTypes.IporDerivative memory iporDerivative) internal {
        emit OpenPosition(
            iporDerivative.id,
            iporDerivative.buyer,
            iporDerivative.asset,
            DataTypes.DerivativeDirection(iporDerivative.direction),
            iporDerivative.depositAmount,
            iporDerivative.fee,
            iporDerivative.leverage,
            iporDerivative.notionalAmount,
            iporDerivative.startingTimestamp,
            iporDerivative.endingTimestamp,
            iporDerivative.indicator
        );
    }

    function _updateBalances(string memory asset, DataTypes.IporDerivativeAmount memory derivativeAmount) internal {
        derivativesTotalBalances[asset] = derivativesTotalBalances[asset] + derivativeAmount.deposit;
        openingFeeTotalBalances[asset] = openingFeeTotalBalances[asset] + derivativeAmount.openingFee;
        liquidationDepositTotalBalances[asset] = liquidationDepositTotalBalances[asset] + Constants.LIQUIDATION_DEPOSIT_FEE_AMOUNT;
        iporPublicationFeeTotalBalances[asset] = iporPublicationFeeTotalBalances[asset] + Constants.IPOR_PUBLICATION_FEE_AMOUNT;
        liquidityPoolTotalBalances[asset] = liquidityPoolTotalBalances[asset] + derivativeAmount.openingFee;
    }

    function _calculateDerivativeIndicators(string memory asset, uint8 direction, uint256 notionalAmount)
    internal view returns (DataTypes.IporDerivativeIndicator memory _indicator) {
        (uint256 iporIndexValue, uint256  ibtPrice,) = iporOracle.getIndex(asset);
        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
            iporIndexValue,
            ibtPrice,
            AmmMath.calculateIbtQuantity(notionalAmount, ibtPrice),
            direction == 0 ? (iporIndexValue + SPREAD_FEE_PERCENTAGE) : (iporIndexValue - SPREAD_FEE_PERCENTAGE)
        );
        return indicator;
    }

    function _closePosition(uint256 derivativeId, uint256 closeTimestamp) internal {

        derivatives[derivativeId].state = DataTypes.DerivativeState.INACTIVE;

        (, uint256 ibtPrice,) = iporOracle.getIndex(derivatives[derivativeId].asset);

        DataTypes.IporDerivativeInterest memory derivativeInterest = derivatives[derivativeId].calculateInterest(closeTimestamp, ibtPrice);

        _rebalanceBasedOnInterestDifferenceAmount(derivativeId, derivativeInterest.interestDifferenceAmount, closeTimestamp);

        soapIndicators[derivatives[derivativeId].asset].rebalanceSoapWhenClosePosition(
            derivatives[derivativeId].direction,
            closeTimestamp,
            derivatives[derivativeId].startingTimestamp,
            derivatives[derivativeId].notionalAmount,
            derivatives[derivativeId].indicator.fixedInterestRate,
            derivatives[derivativeId].indicator.ibtQuantity
        );

        emit ClosePosition(
            derivativeId,
            derivatives[derivativeId].asset,
            closeTimestamp,
            derivativeInterest.interestFixed,
            derivativeInterest.interestFloating
        );

        emit TotalBalances(
            derivatives[derivativeId].asset,
            IERC20(tokens[derivatives[derivativeId].asset]).balanceOf(address(this)),
            derivativesTotalBalances[derivatives[derivativeId].asset],
            openingFeeTotalBalances[derivatives[derivativeId].asset],
            liquidationDepositTotalBalances[derivatives[derivativeId].asset],
            iporPublicationFeeTotalBalances[derivatives[derivativeId].asset],
            liquidityPoolTotalBalances[derivatives[derivativeId].asset]
        );
    }

    //TODO: [REFACTOR] move to library extend int256
    function _calculateAbsValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? - value : value);
    }

    function _rebalanceBasedOnInterestDifferenceAmount(uint256 derivativeId, int256 interestDifferenceAmount, uint256 _calculationTimestamp) internal {

        uint256 absInterestDifferenceAmount = _calculateAbsValue(interestDifferenceAmount);

        //decrease from balances the liquidation deposit
        require(liquidationDepositTotalBalances[derivatives[derivativeId].asset] >= derivatives[derivativeId].fee.liquidationDepositAmount,
            Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW);

        liquidationDepositTotalBalances[derivatives[derivativeId].asset] = liquidationDepositTotalBalances[derivatives[derivativeId].asset] - derivatives[derivativeId].fee.liquidationDepositAmount;

        derivativesTotalBalances[derivatives[derivativeId].asset] = derivativesTotalBalances[derivatives[derivativeId].asset] - derivatives[derivativeId].depositAmount;

        uint256 transferAmount = derivatives[derivativeId].depositAmount;

        if (interestDifferenceAmount > 0) {

            //tokens transfered outsite AMM
            if (absInterestDifferenceAmount > derivatives[derivativeId].depositAmount) {
                // |I| > D

                require(liquidityPoolTotalBalances[derivatives[derivativeId].asset] >= derivatives[derivativeId].depositAmount, Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);
                //fetch "D" amount from Liquidity Pool
                liquidityPoolTotalBalances[derivatives[derivativeId].asset] = liquidityPoolTotalBalances[derivatives[derivativeId].asset] - derivatives[derivativeId].depositAmount;

                //transfer D+D to user's address
                transferAmount = transferAmount + derivatives[derivativeId].depositAmount;
                _transferDerivativeAmount(derivativeId, transferAmount);
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount

            } else {
                // |I| <= D

                require(liquidityPoolTotalBalances[derivatives[derivativeId].asset] >= absInterestDifferenceAmount, Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (msg.sender != derivatives[derivativeId].buyer) {
                    require(_calculationTimestamp >= derivatives[derivativeId].endingTimestamp, Errors.AMM_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                //fetch "I" amount from Liquidity Pool
                liquidityPoolTotalBalances[derivatives[derivativeId].asset] = liquidityPoolTotalBalances[derivatives[derivativeId].asset] - absInterestDifferenceAmount;

                //transfer P=D+I to user's address
                transferAmount = transferAmount + absInterestDifferenceAmount;

                _transferDerivativeAmount(derivativeId, transferAmount);
            }

        } else {
            //tokens transfered inside AMM, updates on balances
            if (absInterestDifferenceAmount > derivatives[derivativeId].depositAmount) {
                // |I| > D

                //transfer D  to Liquidity Pool
                liquidityPoolTotalBalances[derivatives[derivativeId].asset] = liquidityPoolTotalBalances[derivatives[derivativeId].asset] + derivatives[derivativeId].depositAmount;
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount

                IERC20(tokens[derivatives[derivativeId].asset]).transfer(msg.sender, derivatives[derivativeId].fee.liquidationDepositAmount);
            } else {
                // |I| <= D

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (msg.sender != derivatives[derivativeId].buyer) {
                    require(_calculationTimestamp >= derivatives[derivativeId].endingTimestamp, Errors.AMM_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                //transfer I to Liquidity Pool
                liquidityPoolTotalBalances[derivatives[derivativeId].asset] = liquidityPoolTotalBalances[derivatives[derivativeId].asset] + absInterestDifferenceAmount;

                //transfer D-I to user's address
                transferAmount = transferAmount - absInterestDifferenceAmount;
                _transferDerivativeAmount(derivativeId, transferAmount);
            }
        }
    }

    //Depends on condition transfer only to sender (when sender == buyer) or to sender and buyer
    function _transferDerivativeAmount(uint256 derivativeId, uint256 transferAmount) internal {

        if (msg.sender == derivatives[derivativeId].buyer) {
            transferAmount = transferAmount + derivatives[derivativeId].fee.liquidationDepositAmount;
        } else {
            //transfer liquidation deposit to sender
            IERC20(tokens[derivatives[derivativeId].asset]).transfer(msg.sender, derivatives[derivativeId].fee.liquidationDepositAmount);
        }

        //transfer from AMM to buyer
        IERC20(tokens[derivatives[derivativeId].asset]).transfer(derivatives[derivativeId].buyer, transferAmount);
    }

    function provideLiquidity(string memory asset, uint256 liquidityAmount) public {
        liquidityPoolTotalBalances[asset] = liquidityPoolTotalBalances[asset] + liquidityAmount;
        IERC20(tokens[asset]).transferFrom(msg.sender, address(this), liquidityAmount);
    }

    function _calculateClosingFeeAmount(uint256 depositAmount) internal view returns (uint256) {
        return depositAmount * closingFeePercentage / 100 * Constants.MILTON_DECIMALS_FACTOR;
    }

    //@notice FOR FRONTEND
    function getTotalSupply(string memory asset) external view returns (uint256) {
        IERC20 token = IERC20(tokens[asset]);
        return token.balanceOf(address(this));
    }
    //@notice FOR FRONTEND
    function getMyTotalSupply(string memory asset) external view returns (uint256) {
        IERC20 token = IERC20(tokens[asset]);
        return token.balanceOf(msg.sender);
    }
    //@notice FOR TEST
    function getOpenPosition(uint256 derivativeId) external view returns (DataTypes.IporDerivative memory) {
        return derivatives[derivativeId];
    }

    //@notice FOR FRONTEND
    function getPositions() external view returns (DataTypes.IporDerivative[] memory) {
        //TODO: fix it, looks bad
        return derivatives.getPositions();
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `3`, a balance of `707` tokens should
     * be displayed to a user as `0,707` (`707 / 10 ** 3`).
     */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }
    modifier onlyActiveDerivative(uint256 derivativeId) {
        require(derivatives[derivativeId].state == DataTypes.DerivativeState.ACTIVE, Errors.AMM_DERIVATIVE_IS_INACTIVE);
        _;
    }
    /**
     * @notice Modifier which checks if caller is admin for this contract
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, Errors.CALLER_NOT_IPOR_ORACLE_ADMIN);
        _;
    }
}