// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";
import "../libraries/AmmMath.sol";
//TODO: clarify if better is to have external libraries in local folder
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from '../Errors.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IWarren.sol";
import '../oracles/WarrenStorage.sol';
import './MiltonStorage.sol';
import './MiltonEvents.sol';
import '../tokenization/IporToken.sol';

import "../interfaces/IMiltonConfiguration.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
import "../interfaces/IMiltonSpreadStrategy.sol";
import "../interfaces/IIporLiquidityPool.sol";

/**
 * @title Milton - Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
contract Milton is Ownable, MiltonEvents, IMilton {

//    using SafeERC20 for IERC20;

    using DerivativeLogic for DataTypes.IporDerivative;

    IIporAddressesManager internal _addressesManager;

    function initialize(IIporAddressesManager addressesManager) public onlyOwner {
        _addressesManager = addressesManager;
    }

    //    fallback() external payable  {
    //        require(msg.data.length == 0); emit LogDepositReceived(msg.sender);
    //    }

    function authorizeLiquidityPool(address asset) external override onlyOwner {
        IERC20(asset).approve(_addressesManager.getIporLiquidityPool(), Constants.MAX_VALUE);
    }

    //@notice transfer publication fee to configured charlie treasurer address
    function transferPublicationFee(address asset, uint256 amount) external onlyPublicationFeeTransferer {

        require(amount > 0, Errors.MILTON_NOT_ENOUGH_AMOUNT_TO_TRANSFER);
        IMiltonStorage miltonStorage = IMiltonStorage(_addressesManager.getMiltonStorage());
        require(amount <= miltonStorage.getBalance(asset).openingFee, Errors.MILTON_NOT_ENOUGH_OPENING_FEE_BALANCE);
        require(address(0) != _addressesManager.getCharlieTreasurer(asset), Errors.MILTON_INCORRECT_CHARLIE_TREASURER_ADDRESS);
        miltonStorage.updateStorageWhenTransferPublicationFee(asset, amount);
        IERC20(asset).transfer(_addressesManager.getCharlieTreasurer(asset), amount);
    }

    function openPosition(
        address asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor,
        uint8 direction) external override returns (uint256){
        return _openPosition(block.timestamp, asset, totalAmount, maximumSlippage, collateralizationFactor, direction);
    }

    function closePosition(uint256 derivativeId) onlyActiveDerivative(derivativeId) external override {
        _closePosition(derivativeId, block.timestamp);
    }

    function calculateSpread(address asset) external override view returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue) {
        (uint256 _spreadPayFixedValue, uint256 _spreadRecFixedValue) = _calculateSpread(asset, block.timestamp);
        return (spreadPayFixedValue = _spreadPayFixedValue, spreadRecFixedValue = _spreadRecFixedValue);
    }

    function calculateSoap(address asset) external override view returns (int256 soapPf, int256 soapRf, int256 soap) {
        (int256 _soapPf, int256 _soapRf, int256 _soap) = _calculateSoap(asset, block.timestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function _calculateSpread(address asset, uint256 calculateTimestamp) internal view returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue) {
        return IMiltonSpreadStrategy(_addressesManager.getMiltonSpreadStrategy()).calculateSpread(asset, calculateTimestamp);
    }

    function _calculateSoap(address asset, uint256 calculateTimestamp) internal view returns (int256 soapPf, int256 soapRf, int256 soap) {
        IWarren warren = IWarren(_addressesManager.getWarren());
        uint256 accruedIbtPrice = warren.calculateAccruedIbtPrice(asset, calculateTimestamp);
        (int256 _soapPf, int256 _soapRf, int256 _soap) = IMiltonStorage(_addressesManager.getMiltonStorage()).calculateSoap(asset, accruedIbtPrice, calculateTimestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function _openPosition(
        uint256 openTimestamp,
        address asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor,
        uint8 direction) internal returns (uint256) {

        require(address(_addressesManager) != address(0), Errors.MILTON_INCORRECT_ADRESSES_MANAGER_ADDRESS);
        require(asset != address(0), Errors.MILTON_LIQUIDITY_POOL_NOT_EXISTS);
        require(_addressesManager.assetSupported(asset) == 1, Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED);

        IMiltonConfiguration miltonConfiguration = IMiltonConfiguration(_addressesManager.getMiltonConfiguration());
        require(address(miltonConfiguration) != address(0), Errors.MILTON_INCORRECT_CONFIGURATION_ADDRESS);

        //TODO: confirm if _totalAmount always with 18 ditigs or what? (appeared question because this amount contain fee)
        //TODO: _totalAmount multiply if required based on _asset

        require(collateralizationFactor >= miltonConfiguration.getMinCollateralizationFactorValue(), Errors.MILTON_COLLATERALIZATION_FACTOR_TOO_LOW);
        require(collateralizationFactor <= miltonConfiguration.getMaxCollateralizationFactorValue(), Errors.MILTON_COLLATERALIZATION_FACTOR_TOO_HIGH);

        require(totalAmount > 0, Errors.MILTON_TOTAL_AMOUNT_TOO_LOW);
        require(totalAmount > miltonConfiguration.getLiquidationDepositAmount() + miltonConfiguration.getIporPublicationFeeAmount(),
            Errors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE);
        require(totalAmount <= miltonConfiguration.getMaxPositionTotalAmount(), Errors.MILTON_TOTAL_AMOUNT_TOO_HIGH);
        require(IERC20(asset).balanceOf(msg.sender) >= totalAmount, Errors.MILTON_ASSET_BALANCE_OF_TOO_LOW);

        require(maximumSlippage > 0, Errors.MILTON_MAXIMUM_SLIPPAGE_TOO_LOW);
        //TODO: setup max slippage in milton configuration
        require(maximumSlippage <= 1e20, Errors.MILTON_MAXIMUM_SLIPPAGE_TOO_HIGH);

        require(direction <= uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed), Errors.MILTON_DERIVATIVE_DIRECTION_NOT_EXISTS);

        //TODO verify if this opened derivatives is closable based on liquidity pool

        DataTypes.IporDerivativeAmount memory derivativeAmount = AmmMath.calculateDerivativeAmount(
            totalAmount, collateralizationFactor,
            miltonConfiguration.getLiquidationDepositAmount(),
            miltonConfiguration.getIporPublicationFeeAmount(),
            miltonConfiguration.getOpeningFeePercentage()
        );

        require(totalAmount > miltonConfiguration.getLiquidationDepositAmount() + miltonConfiguration.getIporPublicationFeeAmount() + derivativeAmount.openingFee,
            Errors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE);

        require(IMiltonLPUtilizationStrategy(
            _addressesManager.getMiltonUtilizationStrategy()).calculateUtilization(asset, derivativeAmount.deposit, derivativeAmount.openingFee) <= miltonConfiguration.getLiquidityPoolMaxUtilizationPercentage(),
            Errors.MILTON_LIQUIDITY_POOL_UTILISATION_EXCEEDED);

        (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue) = _calculateSpread(asset, openTimestamp);

        IMiltonStorage miltonStorage = IMiltonStorage(_addressesManager.getMiltonStorage());

        DataTypes.IporDerivative memory iporDerivative = DataTypes.IporDerivative(
            miltonStorage.getLastDerivativeId() + 1,
            DataTypes.DerivativeState.ACTIVE,
            msg.sender,
            asset,
            direction,
            derivativeAmount.deposit,
            DataTypes.IporDerivativeFee(
                miltonConfiguration.getLiquidationDepositAmount(),
                derivativeAmount.openingFee,
                miltonConfiguration.getIporPublicationFeeAmount(),
                spreadPayFixedValue,
                spreadRecFixedValue),
                collateralizationFactor,
            derivativeAmount.notional,
            openTimestamp,
            openTimestamp + Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
            _calculateDerivativeIndicators(openTimestamp, asset, direction, derivativeAmount.notional)
        );

        miltonStorage.updateStorageWhenOpenPosition(iporDerivative);

        //TODO:Use call() instead, without hardcoded gas limits along with checks-effects-interactions pattern or reentrancy guards for reentrancy protection.
        //TODO: https://swcregistry.io/docs/SWC-134, https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        //TODO: Use OpenZeppelin’s SafeERC20 wrappers.
        //TODO: change transfer to call - transfer rely on gas cost :EDIT May 2021: call{value: amount}("") should now be used for transferring ether (Do not use send or transfer.)
        //TODO: https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage/38642
        IERC20(asset).transferFrom(msg.sender, address(this), totalAmount);

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
            iporDerivative.collateral,
            iporDerivative.fee,
            iporDerivative.collateralizationFactor,
            iporDerivative.notionalAmount,
            iporDerivative.startingTimestamp,
            iporDerivative.endingTimestamp,
            iporDerivative.indicator
        );
    }

    function _calculateDerivativeIndicators(uint256 calculateTimestamp, address asset, uint8 direction, uint256 notionalAmount)
    internal view returns (DataTypes.IporDerivativeIndicator memory _indicator) {
        IWarren warren = IWarren(_addressesManager.getWarren());
        (uint256 indexValue, ,) = warren.getIndex(asset);
        uint256 accruedIbtPrice = warren.calculateAccruedIbtPrice(asset, calculateTimestamp);
        require(accruedIbtPrice > 0, Errors.MILTON_IBT_PRICE_CANNOT_BE_ZERO);
        (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue) = _calculateSpread(asset, block.timestamp);
        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
            indexValue,
            accruedIbtPrice,
            AmmMath.calculateIbtQuantity(notionalAmount, accruedIbtPrice),
            direction == 0 ? (indexValue + spreadPayFixedValue) : (indexValue - spreadRecFixedValue)
        );
        return indicator;
    }
    event LogDebug(string name, int256 value);
    event LogDebugUint(string name, uint256 value);
    function _closePosition(uint256 derivativeId, uint256 closeTimestamp) internal {
        IMiltonStorage miltonStorage = IMiltonStorage(_addressesManager.getMiltonStorage());

        DataTypes.MiltonDerivativeItem memory derivativeItem = miltonStorage.getDerivativeItem(derivativeId);

        uint256 accruedIbtPrice = IWarren(_addressesManager.getWarren()).calculateAccruedIbtPrice(derivativeItem.item.asset, closeTimestamp);

        DataTypes.IporDerivativeInterest memory derivativeInterest =
        derivativeItem.item.calculateInterest(closeTimestamp, accruedIbtPrice);
        emit LogDebug("interestDifferenceAmount", derivativeInterest.interestDifferenceAmount);
        emit LogDebugUint("InterestFixed", AmmMath.division(derivativeInterest.quasiInterestFixed, Constants.MD_YEAR_IN_SECONDS));
        emit LogDebugUint("InterestFloating", AmmMath.division(derivativeInterest.quasiInterestFloating, Constants.MD_YEAR_IN_SECONDS));
        emit LogDebugUint("accruedIbtPrice",accruedIbtPrice);


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

        uint256 transferAmount = derivativeItem.item.collateral;

        if (interestDifferenceAmount > 0) {
            //Trader earn, Milton loose

            //tokens transfered from Milton
            if (absInterestDifferenceAmount > derivativeItem.item.collateral) {
                // |I| > D
                uint256 incomeTax = AmmMath.calculateIncomeTax(derivativeItem.item.collateral, miltonConfiguration.getIncomeTaxPercentage());
                emit LogDebugUint("incomeTax", incomeTax);

                //transfer D+D-incomeTax to user's address
                transferAmount = transferAmount + derivativeItem.item.collateral - incomeTax;

                _transferDerivativeAmount(derivativeItem, transferAmount);
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount

            } else {
                // |I| <= D

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (msg.sender != derivativeItem.item.buyer) {
                    require(_calculationTimestamp >= derivativeItem.item.endingTimestamp,
                        Errors.MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                uint256 incomeTax = AmmMath.calculateIncomeTax(absInterestDifferenceAmount, miltonConfiguration.getIncomeTaxPercentage());
                emit LogDebugUint("incomeTax", incomeTax);

                //transfer P=D+I-incomeTax to user's address
                transferAmount = transferAmount + absInterestDifferenceAmount - incomeTax;

                _transferDerivativeAmount(derivativeItem, transferAmount);
            }

        } else {
            //Milton earn, Trader loose

            //tokens transfered to Milton, updates on balances
            if (absInterestDifferenceAmount > derivativeItem.item.collateral) {
                // |I| > D

                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount
                //TODO: take into consideration token decimals!!!
                IERC20(derivativeItem.item.asset)
                .transfer(msg.sender, derivativeItem.item.fee.liquidationDepositAmount);
            } else {
                // |I| <= D

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (msg.sender != derivativeItem.item.buyer) {
                    require(_calculationTimestamp >= derivativeItem.item.endingTimestamp,
                        Errors.MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
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
            IERC20(derivativeItem.item.asset).transfer(msg.sender, derivativeItem.item.fee.liquidationDepositAmount);
        }

        //transfer from AMM to buyer
        //TODO: take into consideration token decimals!!!
        IERC20(derivativeItem.item.asset).transfer(derivativeItem.item.buyer, transferAmount);
    }

    modifier onlyActiveDerivative(uint256 derivativeId) {
        require(IMiltonStorage(_addressesManager.getMiltonStorage()).getDerivativeItem(derivativeId).item.state == DataTypes.DerivativeState.ACTIVE,
            Errors.MILTON_DERIVATIVE_IS_INACTIVE);
        _;
    }

    modifier onlyPublicationFeeTransferer() {
        require(msg.sender == _addressesManager.getPublicationFeeTransferer(), Errors.MILTON_CALLER_NOT_PUBLICATION_FEE_TRANSFERER);
        _;
    }

}
