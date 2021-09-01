// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../libraries/DerivativeLogic.sol";
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/TotalSoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";
import "../interfaces/IIporAddressesManager.sol";
import "../libraries/types/DataTypes.sol";
import "../libraries/SpreadIndicatorLogic.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonConfiguration.sol";


contract MiltonStorage is IMiltonStorage {

    using DerivativeLogic for DataTypes.IporDerivative;
    using SoapIndicatorLogic for DataTypes.SoapIndicator;
    using SpreadIndicatorLogic for DataTypes.SpreadIndicator;
    using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;
    using DerivativesView for DataTypes.MiltonDerivatives;

    IIporAddressesManager internal _addressesManager;

    mapping(string => DataTypes.MiltonTotalBalance) public balances;

    mapping(string => DataTypes.TotalSoapIndicator) public soapIndicators;

    //TODO: when spread is calculated in final way then consider remove this storage (maybe will be not needed)
    mapping(string => DataTypes.TotalSpreadIndicator) public spreadIndicators;

    DataTypes.MiltonDerivatives public derivatives;

    function initialize(IIporAddressesManager addressesManager) public {
        _addressesManager = addressesManager;

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

    function getLastDerivativeId() external override view returns (uint256) {
        return derivatives.lastDerivativeId;
    }

    function addLiquidity(string memory asset, uint256 liquidityAmount) external override {
        balances[asset].liquidityPool = balances[asset].liquidityPool + liquidityAmount;
    }

    function getDerivativeItem(uint256 derivativeId) external override view returns (DataTypes.MiltonDerivativeItem memory) {
        return derivatives.items[derivativeId];
    }

    function updateStorageWhenOpenPosition(DataTypes.IporDerivative memory iporDerivative) external override onlyMilton {

        _updateMiltonDerivativesWhenOpenPosition(iporDerivative);
        _updateBalancesWhenOpenPosition(iporDerivative.asset, iporDerivative.depositAmount, iporDerivative.fee.openingAmount);
        _updateSoapIndicatorsWhenOpenPosition(iporDerivative);

    }

    function updateStorageWhenClosePosition(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 interestDifferenceAmount,
        uint256 closingTimestamp) external override onlyMilton {

        _updateMiltonDerivativesWhenClosePosition(derivativeItem);
        _updateBalancesWhenClosePosition(user, derivativeItem, interestDifferenceAmount, closingTimestamp);
        _updateSoapIndicatorsWhenClosePosition(derivativeItem, closingTimestamp);

    }

    function getPositions() external view override returns (DataTypes.IporDerivative[] memory) {
        return derivatives.getPositions();
    }

    function getUserPositions(address user) external view override returns (DataTypes.IporDerivative[] memory) {
        return derivatives.getUserPositions(user);
    }

    function getDerivativeIds() external override view returns (uint256[] memory) {
        return derivatives.ids;
    }

    function getUserDerivativeIds(address userAddress) external override view returns (uint256[] memory) {
        return derivatives.userDerivativeIds[userAddress];
    }

    function calculateSpread(
        string memory asset,
        uint256 calculateTimestamp) external override view returns (uint256 spreadPf, uint256 spreadRf) {
        return (
        spreadPf = spreadIndicators[asset].pf.calculateSpread(calculateTimestamp),
        spreadRf = spreadIndicators[asset].rf.calculateSpread(calculateTimestamp)
        );
    }

    function calculateSoap(
        string memory asset,
        uint256 ibtPrice,
        uint256 calculateTimestamp) external override view returns (int256 soapPf, int256 soapRf, int256 soap) {
        (int256 qSoapPf, int256 qSoapRf, int256 qSoap) = _calculateQuasiSoap(asset, ibtPrice, calculateTimestamp);
        return (
        soapPf = AmmMath.divisionInt(qSoapPf, Constants.MD_P2_YEAR_IN_SECONDS_INT),
        soapRf = AmmMath.divisionInt(qSoapRf, Constants.MD_P2_YEAR_IN_SECONDS_INT),
        soap = AmmMath.divisionInt(qSoap, Constants.MD_P2_YEAR_IN_SECONDS_INT)
        );
    }

    function _calculateQuasiSoap(
        string memory asset,
        uint256 ibtPrice,
        uint256 calculateTimestamp) internal view returns (int256 soapPf, int256 soapRf, int256 soap){
        (int256 _soapPf, int256 _soapRf) = soapIndicators[asset].calculateQuasiSoap(calculateTimestamp, ibtPrice);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soapPf + _soapRf);
    }

    function _updateBalancesWhenOpenPosition(string memory asset, uint256 depositAmount, uint256 openingFeeAmount) internal {
        IMiltonConfiguration miltonConfiguration = IMiltonConfiguration(_addressesManager.getMiltonConfiguration());
        balances[asset].derivatives = balances[asset].derivatives + depositAmount;
        balances[asset].openingFee = balances[asset].openingFee + openingFeeAmount;
        balances[asset].liquidationDeposit = balances[asset].liquidationDeposit + miltonConfiguration.getLiquidationDepositFeeAmount();
        balances[asset].iporPublicationFee = balances[asset].iporPublicationFee + miltonConfiguration.getIporPublicationFeeAmount();
        balances[asset].liquidityPool = balances[asset].liquidityPool + openingFeeAmount;
    }

    function _updateBalancesWhenClosePosition(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 interestDifferenceAmount,
        uint256 closingTimestamp) internal {

        uint256 absInterestDifferenceAmount = AmmMath.absoluteValue(interestDifferenceAmount);

        //decrease from balances the liquidation deposit
        require(balances[derivativeItem.item.asset].liquidationDeposit >=
            derivativeItem.item.fee.liquidationDepositAmount,
            Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW);

        balances[derivativeItem.item.asset].liquidationDeposit
        = balances[derivativeItem.item.asset].liquidationDeposit - derivativeItem.item.fee.liquidationDepositAmount;

        balances[derivativeItem.item.asset].derivatives
        = balances[derivativeItem.item.asset].derivatives - derivativeItem.item.depositAmount;

        if (interestDifferenceAmount > 0) {

            //tokens transfered from AMM
            if (absInterestDifferenceAmount > derivativeItem.item.depositAmount) {
                // |I| > D

                require(balances[derivativeItem.item.asset].liquidityPool >= derivativeItem.item.depositAmount,
                    Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);

                //fetch "D" amount from Liquidity Pool
                balances[derivativeItem.item.asset].liquidityPool
                = balances[derivativeItem.item.asset].liquidityPool - derivativeItem.item.depositAmount;

                uint256 incomeTax = AmmMath.calculateIncomeTax(derivativeItem.item.depositAmount,
                    IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getIncomeTaxPercentage());

                balances[derivativeItem.item.asset].treasury
                = balances[derivativeItem.item.asset].treasury + incomeTax;

            } else {
                // |I| <= D

                require(balances[derivativeItem.item.asset].liquidityPool >= absInterestDifferenceAmount,
                    Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (user != derivativeItem.item.buyer) {
                    require(closingTimestamp >= derivativeItem.item.endingTimestamp,
                        Errors.AMM_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                //fetch "I" amount from Liquidity Pool
                balances[derivativeItem.item.asset].liquidityPool = balances[derivativeItem.item.asset].liquidityPool - absInterestDifferenceAmount;

                uint256 incomeTax = AmmMath.calculateIncomeTax(absInterestDifferenceAmount,
                    IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getIncomeTaxPercentage());

                balances[derivativeItem.item.asset].treasury
                = balances[derivativeItem.item.asset].treasury + incomeTax;

            }

        } else {
            //tokens transfered to AMM, updates on balances
            if (absInterestDifferenceAmount > derivativeItem.item.depositAmount) {
                // |I| > D

                uint256 incomeTax = AmmMath.calculateIncomeTax(derivativeItem.item.depositAmount,
                    IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getIncomeTaxPercentage());

                balances[derivativeItem.item.asset].treasury
                = balances[derivativeItem.item.asset].treasury + incomeTax;

                //transfer D - incomeTax  to Liquidity Pool
                balances[derivativeItem.item.asset].liquidityPool
                = balances[derivativeItem.item.asset].liquidityPool + derivativeItem.item.depositAmount - incomeTax;
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount

            } else {
                // |I| <= D

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (user != derivativeItem.item.buyer) {
                    require(closingTimestamp >= derivativeItem.item.endingTimestamp,
                        Errors.AMM_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                uint256 incomeTax = AmmMath.calculateIncomeTax(absInterestDifferenceAmount,
                    IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getIncomeTaxPercentage());

                balances[derivativeItem.item.asset].treasury
                = balances[derivativeItem.item.asset].treasury + incomeTax;

                //transfer I-incomeTax to Liquidity Pool
                balances[derivativeItem.item.asset].liquidityPool
                = balances[derivativeItem.item.asset].liquidityPool + absInterestDifferenceAmount - incomeTax;

            }
        }
    }

    function _updateMiltonDerivativesWhenOpenPosition(DataTypes.IporDerivative memory derivative) internal {
        derivatives.items[derivative.id].item = derivative;
        derivatives.items[derivative.id].idsIndex = derivatives.ids.length;
        derivatives.items[derivative.id].userDerivativeIdsIndex = derivatives.userDerivativeIds[derivative.buyer].length;
        derivatives.ids.push(derivative.id);
        derivatives.userDerivativeIds[derivative.buyer].push(derivative.id);
        derivatives.lastDerivativeId = derivative.id;
    }

    function _updateMiltonDerivativesWhenClosePosition(DataTypes.MiltonDerivativeItem memory derivativeItem) internal {
        require(derivativeItem.item.id > 0, Errors.AMM_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID);
        require(derivativeItem.item.state != DataTypes.DerivativeState.INACTIVE, Errors.AMM_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS);
        uint256 idsIndexToDelete = derivativeItem.idsIndex;

        if (idsIndexToDelete < derivatives.ids.length - 1) {
            uint256 idsDerivativeIdToMove = derivatives.ids[derivatives.ids.length - 1];
            derivatives.items[idsDerivativeIdToMove].idsIndex = idsIndexToDelete;
            derivatives.ids[idsIndexToDelete] = idsDerivativeIdToMove;
        }

        uint256 userDerivativeIdsIndexToDelete = derivativeItem.userDerivativeIdsIndex;
        address buyer = derivativeItem.item.buyer;

        if (userDerivativeIdsIndexToDelete < derivatives.userDerivativeIds[buyer].length - 1) {
            uint256 userDerivativeIdToMove = derivatives.userDerivativeIds[buyer][derivatives.userDerivativeIds[buyer].length - 1];
            derivatives.items[userDerivativeIdToMove].userDerivativeIdsIndex = userDerivativeIdsIndexToDelete;
            derivatives.userDerivativeIds[buyer][userDerivativeIdsIndexToDelete] = userDerivativeIdToMove;
        }

        derivatives.items[derivativeItem.item.id].item.state = DataTypes.DerivativeState.INACTIVE;
        derivatives.ids.pop();
        derivatives.userDerivativeIds[buyer].pop();
    }

    function _updateSoapIndicatorsWhenOpenPosition(DataTypes.IporDerivative memory iporDerivative) internal {
        soapIndicators[iporDerivative.asset].rebalanceSoapWhenOpenPosition(
            iporDerivative.direction,
            iporDerivative.startingTimestamp,
            iporDerivative.notionalAmount,
            iporDerivative.indicator.fixedInterestRate,
            iporDerivative.indicator.ibtQuantity
        );
    }

    function _updateSoapIndicatorsWhenClosePosition(
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        uint256 closingTimestamp) internal {
        soapIndicators[derivativeItem.item.asset].rebalanceSoapWhenClosePosition(
            derivativeItem.item.direction,
            closingTimestamp,
            derivativeItem.item.startingTimestamp,
            derivativeItem.item.notionalAmount,
            derivativeItem.item.indicator.fixedInterestRate,
            derivativeItem.item.indicator.ibtQuantity
        );
    }

    modifier onlyMilton() {
        require(msg.sender == _addressesManager.getMilton(), Errors.CALLER_NOT_MILTON);
        _;
    }

}
