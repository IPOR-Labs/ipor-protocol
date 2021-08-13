// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";
import "../libraries/DerivativeLogic.sol";
import "../libraries/AmmMath.sol";
//TODO: clarify if better is to have external libraries in local folder
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Errors} from '../Errors.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IWarren.sol";
import './MiltonStorage.sol';
import './MiltonEvents.sol';
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/TotalSoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";
import "../libraries/SpreadIndicatorLogic.sol";
import "../interfaces/IMiltonConfiguration.sol";

/**
 * @title Milton - Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
contract MiltonV1 is Ownable, MiltonV1Storage, MiltonV1Events {

    using DerivativeLogic for DataTypes.IporDerivative;
    using SoapIndicatorLogic for DataTypes.SoapIndicator;
    using SpreadIndicatorLogic for DataTypes.SpreadIndicator;
    using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;
    using DerivativesView for DataTypes.MiltonDerivatives;

    IWarren public warren;
    IMiltonConfiguration public miltonConfiguration;

    //@notice percentage of deposit amount
    uint256 constant SPREAD_FEE_PERCENTAGE = 1e16;

    constructor(
        address miltonConfigurationAddress,
        address warrenAddr,
        address usdtToken, address usdcToken, address daiToken) {

        miltonConfiguration = IMiltonConfiguration(miltonConfigurationAddress);
        warren = IWarren(warrenAddr);

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

        //TODO: clarify what is default value for spread when spread is calculated in final way
        spreadIndicators["USDT"] = DataTypes.TotalSpreadIndicator(
            DataTypes.SpreadIndicator(1e18), DataTypes.SpreadIndicator(1e18)
        );

        spreadIndicators["USDC"] = DataTypes.TotalSpreadIndicator(
            DataTypes.SpreadIndicator(1e18), DataTypes.SpreadIndicator(1e18)
        );

        spreadIndicators["DAI"] = DataTypes.TotalSpreadIndicator(
            DataTypes.SpreadIndicator(1e18), DataTypes.SpreadIndicator(1e18)
        );

        //TODO: allow admin to setup it during runtime
        derivatives.lastDerivativeId = 0;

    }

    function calculateSpread(string memory asset) external view returns (uint256 spreadPf, uint256 spreadRf) {
        (uint256 _spreadPf, uint256 _spreadRf) = _calculateSpread(asset, block.timestamp);
        return (spreadPf = _spreadPf, spreadRf = _spreadRf);
    }

    function calculateSoap(string memory asset) external view returns (int256 soapPf, int256 soapRf, int256 soap) {
        (int256 _soapPf, int256 _soapRf, int256 _soap) = _calculateSoap(asset, block.timestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    //    fallback() external payable  {
    //        require(msg.data.length == 0); emit LogDepositReceived(msg.sender);
    //    }

    function _calculateSpread(
        string memory asset,
        uint256 calculateTimestamp) internal view returns (uint256 spreadPf, uint256 spreadRf) {
        return (
        spreadPf = spreadIndicators[asset].pf.calculateSpread(calculateTimestamp),
        spreadRf = spreadIndicators[asset].rf.calculateSpread(calculateTimestamp)
        );
    }

    function _calculateSoap(
        string memory asset,
        uint256 calculateTimestamp) internal view returns (int256 soapPf, int256 soapRf, int256 soap){
        (int256 qSoapPf, int256 qSoapRf, int256 qSoap) = _calculateQuasiSoap(asset, calculateTimestamp);
        return (
        soapPf = AmmMath.divisionInt(qSoapPf, Constants.MD_P2_YEAR_IN_SECONDS_INT),
        soapRf = AmmMath.divisionInt(qSoapRf, Constants.MD_P2_YEAR_IN_SECONDS_INT),
        soap = AmmMath.divisionInt(qSoap, Constants.MD_P2_YEAR_IN_SECONDS_INT)
        );
    }

    function _calculateQuasiSoap(
        string memory asset,
        uint256 calculateTimestamp) internal view returns (int256 soapPf, int256 soapRf, int256 soap){
        (, uint256 ibtPrice,) = warren.getIndex(asset);
        (int256 _soapPf, int256 _soapRf) = soapIndicators[asset].calculateQuasiSoap(calculateTimestamp, ibtPrice);
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
        require(totalAmount > miltonConfiguration.getLiquidationDepositFeeAmount() + miltonConfiguration.getIporPublicationFeeAmount(), Errors.AMM_TOTAL_AMOUNT_LOWER_THAN_FEE);
        require(totalAmount <= 1e24, Errors.AMM_TOTAL_AMOUNT_TOO_HIGH);
        require(maximumSlippage > 0, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_LOW);
        require(maximumSlippage <= 1e20, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_HIGH);
        require(tokens[asset] != address(0), Errors.AMM_LIQUIDITY_POOL_NOT_EXISTS);
        require(direction <= uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed), Errors.AMM_DERIVATIVE_DIRECTION_NOT_EXISTS);
        require(IERC20(tokens[asset]).balanceOf(msg.sender) >= totalAmount, Errors.AMM_ASSET_BALANCE_OF_TOO_LOW);

        //TODO verify if this opened derivatives is closable based on liquidity pool
        //TODO: add configurable parameter which describe utilization rate of liquidity pool (total deposit amount / total liquidity)

        DataTypes.IporDerivativeAmount memory derivativeAmount = AmmMath.calculateDerivativeAmount(
            totalAmount,
            leverage,
            miltonConfiguration.getLiquidationDepositFeeAmount(),
            miltonConfiguration.getIporPublicationFeeAmount(),
            miltonConfiguration.getOpeningFeePercentage()
        );
        require(totalAmount > miltonConfiguration.getLiquidationDepositFeeAmount() + miltonConfiguration.getIporPublicationFeeAmount() + derivativeAmount.openingFee,
            Errors.AMM_TOTAL_AMOUNT_LOWER_THAN_FEE);

        DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
            miltonConfiguration.getLiquidationDepositFeeAmount(),
            derivativeAmount.openingFee,
            miltonConfiguration.getIporPublicationFeeAmount(),
            SPREAD_FEE_PERCENTAGE);

        DataTypes.IporDerivativeIndicator memory iporDerivativeIndicator = _calculateDerivativeIndicators(asset, direction, derivativeAmount.notional);


        DataTypes.IporDerivative memory iporDerivative = DataTypes.IporDerivative(
            derivatives.lastDerivativeId + 1,
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

        _updateMiltonDerivativesWhenOpenPosition(iporDerivative);

        _updateBalances(asset, derivativeAmount);

        soapIndicators[asset].rebalanceSoapWhenOpenPosition(
            direction,
            openTimestamp,
            derivativeAmount.notional,
            iporDerivativeIndicator.fixedInterestRate,
            iporDerivativeIndicator.ibtQuantity
        );

        //        userDerivatives[msg.sender].push(iporDerivative.id);

        //TODO:Use call() instead, without hardcoded gas limits along with checks-effects-interactions pattern or reentrancy guards for reentrancy protection.
        //TODO: https://swcregistry.io/docs/SWC-134, https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        //TODO: Use OpenZeppelin’s SafeERC20 wrappers.
        //TODO: change transfer to call - transfer rely on gas cost :EDIT May 2021: call{value: amount}("") should now be used for transferring ether (Do not use send or transfer.)
        //TODO: https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage/38642
        IERC20(tokens[asset]).transferFrom(msg.sender, address(this), totalAmount);

        _emitOpenPositionEvent(iporDerivative);

        //TODO: clarify if ipAsset should be transfered to trader when position is opened

        return iporDerivative.id;
    }

    function _updateMiltonDerivativesWhenOpenPosition(DataTypes.IporDerivative memory derivative) internal {
        derivatives.items[derivative.id].item = derivative;
        derivatives.items[derivative.id].idsIndex = derivatives.ids.length;
        derivatives.items[derivative.id].userDerivativeIdsIndex = derivatives.userDerivativeIds[derivative.buyer].length;
        derivatives.ids.push(derivative.id);
        derivatives.userDerivativeIds[derivative.buyer].push(derivative.id);
        derivatives.lastDerivativeId = derivative.id;
    }


    function _updateMiltonDerivativesWhenClosePosition(uint256 derivativeId) internal {
        require(derivativeId > 0, Errors.AMM_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID);
        require(derivatives.items[derivativeId].item.state != DataTypes.DerivativeState.INACTIVE, Errors.AMM_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS);
        uint256 idsIndexToDelete = derivatives.items[derivativeId].idsIndex;

        if (idsIndexToDelete < derivatives.ids.length - 1) {
            uint256 idsDerivativeIdToMove = derivatives.ids[derivatives.ids.length - 1];
            derivatives.items[idsDerivativeIdToMove].idsIndex = idsIndexToDelete;
            derivatives.ids[idsIndexToDelete] = idsDerivativeIdToMove;
        }

        uint256 userDerivativeIdsIndexToDelete = derivatives.items[derivativeId].userDerivativeIdsIndex;
        address buyer = derivatives.items[derivativeId].item.buyer;

        if (userDerivativeIdsIndexToDelete < derivatives.userDerivativeIds[buyer].length - 1) {
            uint256 userDerivativeIdToMove = derivatives.userDerivativeIds[buyer][derivatives.userDerivativeIds[buyer].length - 1];
            derivatives.items[userDerivativeIdToMove].userDerivativeIdsIndex = userDerivativeIdsIndexToDelete;
            derivatives.userDerivativeIds[buyer][userDerivativeIdsIndexToDelete] = userDerivativeIdToMove;
        }

        derivatives.items[derivativeId].item.state = DataTypes.DerivativeState.INACTIVE;
        derivatives.ids.pop();
        derivatives.userDerivativeIds[buyer].pop();
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
        liquidationDepositTotalBalances[asset] = liquidationDepositTotalBalances[asset] + miltonConfiguration.getLiquidationDepositFeeAmount();
        iporPublicationFeeTotalBalances[asset] = iporPublicationFeeTotalBalances[asset] + miltonConfiguration.getIporPublicationFeeAmount();
        liquidityPoolTotalBalances[asset] = liquidityPoolTotalBalances[asset] + derivativeAmount.openingFee;
    }

    function _calculateDerivativeIndicators(string memory asset, uint8 direction, uint256 notionalAmount)
    internal view returns (DataTypes.IporDerivativeIndicator memory _indicator) {
        (uint256 iporIndexValue, uint256  ibtPrice,) = warren.getIndex(asset);
        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
            iporIndexValue,
            ibtPrice,
            AmmMath.calculateIbtQuantity(notionalAmount, ibtPrice),
            direction == 0 ? (iporIndexValue + SPREAD_FEE_PERCENTAGE) : (iporIndexValue - SPREAD_FEE_PERCENTAGE)
        );
        return indicator;
    }

    function _closePosition(uint256 derivativeId, uint256 closeTimestamp) internal {

        _updateMiltonDerivativesWhenClosePosition(derivativeId);

        (, uint256 ibtPrice,) = warren.getIndex(derivatives.items[derivativeId].item.asset);

        DataTypes.IporDerivativeInterest memory derivativeInterest =
        derivatives.items[derivativeId].item.calculateInterest(closeTimestamp, ibtPrice);

        _rebalanceBasedOnInterestDifferenceAmount(derivativeId, derivativeInterest.interestDifferenceAmount, closeTimestamp);

        soapIndicators[derivatives.items[derivativeId].item.asset].rebalanceSoapWhenClosePosition(
            derivatives.items[derivativeId].item.direction,
            closeTimestamp,
            derivatives.items[derivativeId].item.startingTimestamp,
            derivatives.items[derivativeId].item.notionalAmount,
            derivatives.items[derivativeId].item.indicator.fixedInterestRate,
            derivatives.items[derivativeId].item.indicator.ibtQuantity
        );

        emit ClosePosition(
            derivativeId,
            derivatives.items[derivativeId].item.asset,
            closeTimestamp,
            derivativeInterest.interestFixed,
            derivativeInterest.interestFloating
        );

        emit TotalBalances(
            derivatives.items[derivativeId].item.asset,
            IERC20(tokens[derivatives.items[derivativeId].item.asset]).balanceOf(address(this)),
            derivativesTotalBalances[derivatives.items[derivativeId].item.asset],
            openingFeeTotalBalances[derivatives.items[derivativeId].item.asset],
            liquidationDepositTotalBalances[derivatives.items[derivativeId].item.asset],
            iporPublicationFeeTotalBalances[derivatives.items[derivativeId].item.asset],
            liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset]
        );
    }

    function _rebalanceBasedOnInterestDifferenceAmount(uint256 derivativeId, int256 interestDifferenceAmount, uint256 _calculationTimestamp) internal {

        uint256 absInterestDifferenceAmount = AmmMath.absoluteValue(interestDifferenceAmount);

        //decrease from balances the liquidation deposit
        require(liquidationDepositTotalBalances[derivatives.items[derivativeId].item.asset] >=
            derivatives.items[derivativeId].item.fee.liquidationDepositAmount,
            Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW);

        liquidationDepositTotalBalances[derivatives.items[derivativeId].item.asset]
        = liquidationDepositTotalBalances[derivatives.items[derivativeId].item.asset] - derivatives.items[derivativeId].item.fee.liquidationDepositAmount;

        derivativesTotalBalances[derivatives.items[derivativeId].item.asset]
        = derivativesTotalBalances[derivatives.items[derivativeId].item.asset] - derivatives.items[derivativeId].item.depositAmount;

        uint256 transferAmount = derivatives.items[derivativeId].item.depositAmount;

        if (interestDifferenceAmount > 0) {

            //tokens transfered outsite AMM
            if (absInterestDifferenceAmount > derivatives.items[derivativeId].item.depositAmount) {
                // |I| > D

                require(liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset] >= derivatives.items[derivativeId].item.depositAmount, Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);
                //fetch "D" amount from Liquidity Pool
                liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset]
                = liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset] - derivatives.items[derivativeId].item.depositAmount;

                //transfer D+D to user's address
                transferAmount = transferAmount + derivatives.items[derivativeId].item.depositAmount;
                _transferDerivativeAmount(derivativeId, transferAmount);
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount

            } else {
                // |I| <= D

                require(liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset] >= absInterestDifferenceAmount, Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (msg.sender != derivatives.items[derivativeId].item.buyer) {
                    require(_calculationTimestamp >= derivatives.items[derivativeId].item.endingTimestamp, Errors.AMM_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                //fetch "I" amount from Liquidity Pool
                liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset] = liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset] - absInterestDifferenceAmount;

                //transfer P=D+I to user's address
                transferAmount = transferAmount + absInterestDifferenceAmount;

                _transferDerivativeAmount(derivativeId, transferAmount);
            }

        } else {
            //tokens transfered inside AMM, updates on balances
            if (absInterestDifferenceAmount > derivatives.items[derivativeId].item.depositAmount) {
                // |I| > D

                //transfer D  to Liquidity Pool
                liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset]
                = liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset] + derivatives.items[derivativeId].item.depositAmount;
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount
                //TODO: take into consideration token decimals!!!

                IERC20(tokens[derivatives.items[derivativeId].item.asset]).transfer(msg.sender, derivatives.items[derivativeId].item.fee.liquidationDepositAmount);
            } else {
                // |I| <= D

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (msg.sender != derivatives.items[derivativeId].item.buyer) {
                    require(_calculationTimestamp >= derivatives.items[derivativeId].item.endingTimestamp, Errors.AMM_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                //transfer I to Liquidity Pool
                liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset]
                = liquidityPoolTotalBalances[derivatives.items[derivativeId].item.asset] + absInterestDifferenceAmount;

                //transfer D-I to user's address
                transferAmount = transferAmount - absInterestDifferenceAmount;
                _transferDerivativeAmount(derivativeId, transferAmount);
            }
        }
    }

    //Depends on condition transfer only to sender (when sender == buyer) or to sender and buyer
    function _transferDerivativeAmount(uint256 derivativeId, uint256 transferAmount) internal {

        if (msg.sender == derivatives.items[derivativeId].item.buyer) {
            transferAmount = transferAmount + derivatives.items[derivativeId].item.fee.liquidationDepositAmount;
        } else {
            //transfer liquidation deposit to sender
            //TODO: take into consideration token decimals!!!
            IERC20(tokens[derivatives.items[derivativeId].item.asset]).transfer(msg.sender, derivatives.items[derivativeId].item.fee.liquidationDepositAmount);
        }

        //transfer from AMM to buyer
        //TODO: take into consideration token decimals!!!
        IERC20(tokens[derivatives.items[derivativeId].item.asset]).transfer(derivatives.items[derivativeId].item.buyer, transferAmount);
    }

    function provideLiquidity(string memory asset, uint256 liquidityAmount) public {
        liquidityPoolTotalBalances[asset] = liquidityPoolTotalBalances[asset] + liquidityAmount;
        //TODO: take into consideration token decimals!!!
        IERC20(tokens[asset]).transferFrom(msg.sender, address(this), liquidityAmount);
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
    //@notice FOR FRONTEND
    //TODO: use ERC20 directly
    function getMyAllowance(string memory asset) external view returns (uint256) {
        IERC20 token = IERC20(tokens[asset]);
        return token.allowance(msg.sender, address(this));
    }

    //@notice FOR TEST
    function getOpenPosition(uint256 derivativeId) external view returns (DataTypes.IporDerivative memory) {
        return derivatives.items[derivativeId].item;
    }

    //@notice FOR FRONTEND
    function getPositions() external view returns (DataTypes.IporDerivative[] memory) {
        //TODO: fix it, looks bad, DoS, possible out of gas
        return derivatives.getPositions();
    }

    //@notice FOR FRONTEND
    function getMyPositions() external view returns (DataTypes.IporDerivative[] memory items) {
        return derivatives.getUserPositions(msg.sender);
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
        require(derivatives.items[derivativeId].item.state == DataTypes.DerivativeState.ACTIVE, Errors.AMM_DERIVATIVE_IS_INACTIVE);
        _;
    }
}