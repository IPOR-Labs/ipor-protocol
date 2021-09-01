// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";
import "../libraries/AmmMath.sol";
//TODO: clarify if better is to have external libraries in local folder
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Errors} from '../Errors.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IWarren.sol";
import '../oracles/WarrenStorage.sol';
import './MiltonStorage.sol';
import './MiltonEvents.sol';

import "../interfaces/IMiltonConfiguration.sol";
import "../interfaces/IMilton.sol";

/**
 * @title Milton - Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
contract Milton is Ownable, MiltonEvents, IMilton {

    using DerivativeLogic for DataTypes.IporDerivative;

    IIporAddressesManager internal _addressesManager;

    //@notice percentage of deposit amount
    uint256 constant SPREAD_FEE_PERCENTAGE = 1e16;

    function initialize(IIporAddressesManager addressesManager) public {
        _addressesManager = addressesManager;
    }

    //    fallback() external payable  {
    //        require(msg.data.length == 0); emit LogDepositReceived(msg.sender);
    //    }

    function openPosition(
        string memory asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint8 leverage,
        uint8 direction) external override returns (uint256){
        return _openPosition(block.timestamp, asset, totalAmount, maximumSlippage, leverage, direction);
    }

    function closePosition(uint256 derivativeId) onlyActiveDerivative(derivativeId) external override {
        _closePosition(derivativeId, block.timestamp);
    }


    function provideLiquidity(string memory asset, uint256 liquidityAmount) external override {
        IMiltonStorage(_addressesManager.getMiltonStorage()).addLiquidity(asset, liquidityAmount);
        //TODO: take into consideration token decimals!!!
        IERC20(_addressesManager.getAddress(asset)).transferFrom(msg.sender, address(this), liquidityAmount);
    }

    function calculateSpread(string memory asset) external override view returns (uint256 spreadPf, uint256 spreadRf) {
        (uint256 _spreadPf, uint256 _spreadRf) = _calculateSpread(asset, block.timestamp);
        return (spreadPf = _spreadPf, spreadRf = _spreadRf);
    }

    function calculateSoap(string memory asset) external override view returns (int256 soapPf, int256 soapRf, int256 soap) {
        (int256 _soapPf, int256 _soapRf, int256 _soap) = _calculateSoap(asset, block.timestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function _calculateSpread(string memory asset, uint256 calculateTimestamp) internal view returns (uint256 spreadPf, uint256 spreadRf) {
        (uint256 _spreadPf, uint256 _spreadRf) = IMiltonStorage(_addressesManager.getMiltonStorage()).calculateSpread(asset, calculateTimestamp);
        return (spreadPf = _spreadPf, spreadRf = _spreadRf);
    }

    function _calculateSoap(string memory asset, uint256 calculateTimestamp) internal view returns (int256 soapPf, int256 soapRf, int256 soap) {
        IWarren warren = IWarren(_addressesManager.getWarren());
        uint256 accruedIbtPrice = warren.calculateAccruedIbtPrice(asset, calculateTimestamp);
        (int256 _soapPf, int256 _soapRf, int256 _soap) = IMiltonStorage(_addressesManager.getMiltonStorage()).calculateSoap(asset, accruedIbtPrice, calculateTimestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function _openPosition(
        uint256 openTimestamp,
        string memory asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint8 leverage,
        uint8 direction) internal returns (uint256) {

        IMiltonStorage miltonStorage = IMiltonStorage(_addressesManager.getMiltonStorage());
        IMiltonConfiguration miltonConfiguration = IMiltonConfiguration(_addressesManager.getMiltonConfiguration());

        //TODO: confirm if _totalAmount always with 18 ditigs or what? (appeared question because this amount contain fee)
        //TODO: _totalAmount multiply if required based on _asset

        require(leverage > 0, Errors.AMM_LEVERAGE_TOO_LOW);
        require(totalAmount > 0, Errors.AMM_TOTAL_AMOUNT_TOO_LOW);
        require(address(miltonConfiguration) != address(0), "MiltonConfiguration address not configured");
        require(address(_addressesManager) != address(0), "_addressesManager address not configured");
        require(totalAmount > miltonConfiguration.getLiquidationDepositFeeAmount() + miltonConfiguration.getIporPublicationFeeAmount(), Errors.AMM_TOTAL_AMOUNT_LOWER_THAN_FEE);
        require(totalAmount <= miltonConfiguration.getMaxPositionTotalAmount(), Errors.AMM_TOTAL_AMOUNT_TOO_HIGH);
        require(maximumSlippage > 0, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_LOW);
        //TODO: setup max slippage in milton configuration
        require(maximumSlippage <= 1e20, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_HIGH);
        require(_addressesManager.getAddress(asset) != address(0), Errors.AMM_LIQUIDITY_POOL_NOT_EXISTS);
        require(direction <= uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed), Errors.AMM_DERIVATIVE_DIRECTION_NOT_EXISTS);
        require(IERC20(_addressesManager.getAddress(asset)).balanceOf(msg.sender) >= totalAmount, Errors.AMM_ASSET_BALANCE_OF_TOO_LOW);

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

        DataTypes.IporDerivativeIndicator memory iporDerivativeIndicator = _calculateDerivativeIndicators(openTimestamp, asset, direction, derivativeAmount.notional);


        DataTypes.IporDerivative memory iporDerivative = DataTypes.IporDerivative(
            miltonStorage.getLastDerivativeId() + 1,
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

        miltonStorage.updateStorageWhenOpenPosition(iporDerivative);

        //TODO:Use call() instead, without hardcoded gas limits along with checks-effects-interactions pattern or reentrancy guards for reentrancy protection.
        //TODO: https://swcregistry.io/docs/SWC-134, https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        //TODO: Use OpenZeppelin’s SafeERC20 wrappers.
        //TODO: change transfer to call - transfer rely on gas cost :EDIT May 2021: call{value: amount}("") should now be used for transferring ether (Do not use send or transfer.)
        //TODO: https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage/38642
        IERC20(_addressesManager.getAddress(asset)).transferFrom(msg.sender, address(this), totalAmount);

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

    function _calculateDerivativeIndicators(uint256 calculateTimestamp, string memory asset, uint8 direction, uint256 notionalAmount)
    internal view returns (DataTypes.IporDerivativeIndicator memory _indicator) {
        IWarren warren = IWarren(_addressesManager.getWarren());
        (uint256 indexValue, ,) = warren.getIndex(asset);
        uint256 accruedIbtPrice = warren.calculateAccruedIbtPrice(asset, calculateTimestamp);
        require(accruedIbtPrice > 0, Errors.MILTON_IBT_PRICE_CANNOT_BE_ZERO);

        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
            indexValue,
            accruedIbtPrice,
            AmmMath.calculateIbtQuantity(notionalAmount, accruedIbtPrice),
            direction == 0 ? (indexValue + SPREAD_FEE_PERCENTAGE) : (indexValue - SPREAD_FEE_PERCENTAGE)
        );
        return indicator;
    }

    function _closePosition(uint256 derivativeId, uint256 closeTimestamp) internal {
        IMiltonStorage miltonStorage = IMiltonStorage(_addressesManager.getMiltonStorage());

        DataTypes.MiltonDerivativeItem memory derivativeItem = miltonStorage.getDerivativeItem(derivativeId);

        uint256 accruedIbtPrice = IWarren(_addressesManager.getWarren()).calculateAccruedIbtPrice(derivativeItem.item.asset, closeTimestamp);

        DataTypes.IporDerivativeInterest memory derivativeInterest =
        derivativeItem.item.calculateInterest(closeTimestamp, accruedIbtPrice);

        miltonStorage.updateStorageWhenClosePosition(msg.sender, derivativeItem, derivativeInterest.interestDifferenceAmount, closeTimestamp);

        _transferTokensBasedOnInterestDifferenceAmount(derivativeItem, derivativeInterest.interestDifferenceAmount, closeTimestamp);

        emit ClosePosition(
            derivativeId,
            derivativeItem.item.asset,
            closeTimestamp
        );
    }

    function _transferTokensBasedOnInterestDifferenceAmount(
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 interestDifferenceAmount,
        uint256 _calculationTimestamp) internal {
        IMiltonConfiguration miltonConfiguration = IMiltonConfiguration(_addressesManager.getMiltonConfiguration());
        uint256 absInterestDifferenceAmount = AmmMath.absoluteValue(interestDifferenceAmount);

        uint256 transferAmount = derivativeItem.item.depositAmount;

        if (interestDifferenceAmount > 0) {

            //tokens transfered from AMM
            if (absInterestDifferenceAmount > derivativeItem.item.depositAmount) {
                // |I| > D
                uint256 incomeTax = AmmMath.calculateIncomeTax(derivativeItem.item.depositAmount, miltonConfiguration.getIncomeTaxPercentage());

                //transfer D+D-incomeTax to user's address
                transferAmount = transferAmount + derivativeItem.item.depositAmount - incomeTax;

                _transferDerivativeAmount(derivativeItem, transferAmount);
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount

            } else {
                // |I| <= D

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (msg.sender != derivativeItem.item.buyer) {
                    require(_calculationTimestamp >= derivativeItem.item.endingTimestamp,
                        Errors.AMM_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                uint256 incomeTax = AmmMath.calculateIncomeTax(absInterestDifferenceAmount, miltonConfiguration.getIncomeTaxPercentage());

                //transfer P=D+I-incomeTax to user's address
                transferAmount = transferAmount + absInterestDifferenceAmount - incomeTax;

                _transferDerivativeAmount(derivativeItem, transferAmount);
            }

        } else {
            //tokens transfered to AMM, updates on balances
            if (absInterestDifferenceAmount > derivativeItem.item.depositAmount) {
                // |I| > D

                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount
                //TODO: take into consideration token decimals!!!
                IERC20(_addressesManager.getAddress(derivativeItem.item.asset))
                .transfer(msg.sender, derivativeItem.item.fee.liquidationDepositAmount);
            } else {
                // |I| <= D

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (msg.sender != derivativeItem.item.buyer) {
                    require(_calculationTimestamp >= derivativeItem.item.endingTimestamp,
                        Errors.AMM_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                //transfer D-I to user's address
                transferAmount = transferAmount - absInterestDifferenceAmount;
                _transferDerivativeAmount(derivativeItem, transferAmount);
            }
        }
    }

    //Depends on condition transfer only to sender (when sender == buyer) or to sender and buyer
    function _transferDerivativeAmount(DataTypes.MiltonDerivativeItem memory derivativeItem, uint256 transferAmount) internal {
        //TODO: take into consideration state "PENDING_WITHDRAWAL"

        if (msg.sender == derivativeItem.item.buyer) {
            transferAmount = transferAmount + derivativeItem.item.fee.liquidationDepositAmount;
        } else {
            //transfer liquidation deposit to sender
            //TODO: take into consideration token decimals!!!
            //TODO: don't use transer but call
            IERC20(_addressesManager.getAddress(derivativeItem.item.asset)).transfer(msg.sender, derivativeItem.item.fee.liquidationDepositAmount);
        }

        //transfer from AMM to buyer
        //TODO: take into consideration token decimals!!!
        IERC20(_addressesManager.getAddress(derivativeItem.item.asset)).transfer(derivativeItem.item.buyer, transferAmount);
    }

    modifier onlyActiveDerivative(uint256 derivativeId) {
        require(IMiltonStorage(_addressesManager.getMiltonStorage()).getDerivativeItem(derivativeId).item.state == DataTypes.DerivativeState.ACTIVE, Errors.AMM_DERIVATIVE_IS_INACTIVE);
        _;
    }

}
