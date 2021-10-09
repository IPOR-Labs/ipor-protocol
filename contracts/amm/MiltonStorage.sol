// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
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


contract MiltonStorage is Ownable, IMiltonStorage {

    using DerivativeLogic for DataTypes.IporDerivative;
    using SoapIndicatorLogic for DataTypes.SoapIndicator;
    using SpreadIndicatorLogic for DataTypes.SpreadIndicator;
    using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;
    using DerivativesView for DataTypes.MiltonDerivatives;

    IIporAddressesManager internal _addressesManager;

    mapping(address => DataTypes.MiltonTotalBalance) public balances;

    mapping(address => DataTypes.TotalSoapIndicator) public soapIndicators;

    //TODO: when spread is calculated in final way then consider remove this storage (maybe will be not needed)
    mapping(address => DataTypes.TotalSpreadIndicator) public spreadIndicators;

    DataTypes.MiltonDerivatives public derivatives;

    function initialize(IIporAddressesManager addressesManager) public onlyOwner {
        _addressesManager = addressesManager;
        //TODO: allow admin to setup it during runtime
        derivatives.lastDerivativeId = 0;
    }

    //@notice add asset address to MiltonStorage structures
    function addAsset(address asset) external override onlyOwner {

        require(_addressesManager.assetSupported(asset) == 1, Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED);

        soapIndicators[asset] = DataTypes.TotalSoapIndicator(
            DataTypes.SoapIndicator(0, DataTypes.DerivativeDirection.PayFixedReceiveFloating, 0, 0, 0, 0, 0),
            DataTypes.SoapIndicator(0, DataTypes.DerivativeDirection.PayFloatingReceiveFixed, 0, 0, 0, 0, 0)
        );

        //TODO: clarify what is default value for spread when spread is calculated in final way
        spreadIndicators[asset] = DataTypes.TotalSpreadIndicator(
            DataTypes.SpreadIndicator(1e18), DataTypes.SpreadIndicator(1e18)
        );
    }

    function getBalance(address asset) external override view returns (DataTypes.MiltonTotalBalance memory) {
        return balances[asset];
    }

    function getLastDerivativeId() external override view returns (uint256) {
        return derivatives.lastDerivativeId;
    }

    function addLiquidity(address asset, uint256 liquidityAmount) external override onlyLiquidityPool {
        require(liquidityAmount > 0, Errors.MILTON_DEPOSIT_AMOUNT_TOO_LOW);
        balances[asset].liquidityPool = balances[asset].liquidityPool + liquidityAmount;
    }

    function subtractLiquidity(address asset, uint256 liquidityAmount) external override onlyLiquidityPool {
        balances[asset].liquidityPool = balances[asset].liquidityPool - liquidityAmount;
    }

    function getDerivativeItem(uint256 derivativeId) external override view returns (DataTypes.MiltonDerivativeItem memory) {
        return derivatives.items[derivativeId];
    }

    function updateStorageWhenTransferPublicationFee(address asset, uint256 transferedAmount) external override onlyMilton {
        balances[asset].iporPublicationFee = balances[asset].iporPublicationFee - transferedAmount;
    }

    function updateStorageWhenOpenPosition(DataTypes.IporDerivative memory iporDerivative) external override onlyMilton {

        _updateMiltonDerivativesWhenOpenPosition(iporDerivative);
        _updateBalancesWhenOpenPosition(iporDerivative.asset, iporDerivative.collateral, iporDerivative.fee.openingAmount);
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
        address asset,
        uint256 calculateTimestamp) external override view returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue) {
        return (
        spreadPayFixedValue = IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getSpreadPayFixedValue(asset),
        spreadRecFixedValue = IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getSpreadRecFixedValue(asset)
        );
    }

    function calculateSoap(
        address asset,
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
        address asset,
        uint256 ibtPrice,
        uint256 calculateTimestamp) internal view returns (int256 soapPf, int256 soapRf, int256 soap){
        (int256 _soapPf, int256 _soapRf) = soapIndicators[asset].calculateQuasiSoap(calculateTimestamp, ibtPrice);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soapPf + _soapRf);
    }

    function _updateBalancesWhenOpenPosition(address asset, uint256 collateral, uint256 openingFeeAmount) internal {

        IMiltonConfiguration miltonConfiguration = IMiltonConfiguration(_addressesManager.getMiltonConfiguration());

        balances[asset].derivatives = balances[asset].derivatives + collateral;
        balances[asset].openingFee = balances[asset].openingFee + openingFeeAmount;
        balances[asset].liquidationDeposit = balances[asset].liquidationDeposit + miltonConfiguration.getLiquidationDepositAmount();
        balances[asset].iporPublicationFee = balances[asset].iporPublicationFee + miltonConfiguration.getIporPublicationFeeAmount();

        uint256 openingFeeForTreasurePercentage = miltonConfiguration.getOpeningFeeForTreasuryPercentage();
        (uint256 openingFeeLPValue, uint256 openingFeeTreasuryValue) = _splitOpeningFeeAmount(openingFeeAmount, openingFeeForTreasurePercentage);
        balances[asset].liquidityPool = balances[asset].liquidityPool + openingFeeLPValue;
        balances[asset].treasury = balances[asset].treasury + openingFeeTreasuryValue;
    }

    function _splitOpeningFeeAmount(uint256 openingFeeAmount, uint256 openingFeeForTreasurePercentage) internal pure returns (uint256 liquidityPoolValue, uint256 treasuryValue) {
        treasuryValue = AmmMath.division(openingFeeAmount * openingFeeForTreasurePercentage, Constants.MD);
        liquidityPoolValue = openingFeeAmount - treasuryValue;
    }
    event LogDebugUint(string name, uint256 value);

    function _updateBalancesWhenClosePosition(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 interestDifferenceAmount,
        uint256 closingTimestamp) internal {

        uint256 absInterestDifferenceAmount = AmmMath.absoluteValue(interestDifferenceAmount);

        //decrease from balances the liquidation deposit
        require(balances[derivativeItem.item.asset].liquidationDeposit >=
            derivativeItem.item.fee.liquidationDepositAmount,
            Errors.MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW);

        balances[derivativeItem.item.asset].liquidationDeposit
        = balances[derivativeItem.item.asset].liquidationDeposit - derivativeItem.item.fee.liquidationDepositAmount;

        balances[derivativeItem.item.asset].derivatives
        = balances[derivativeItem.item.asset].derivatives - derivativeItem.item.collateral;

        if (interestDifferenceAmount > 0) {

            //tokens transfered from AMM
            if (absInterestDifferenceAmount > derivativeItem.item.collateral) {
                // |I| > D

                require(balances[derivativeItem.item.asset].liquidityPool >= derivativeItem.item.collateral,
                    Errors.MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);

                //fetch "D" amount from Liquidity Pool
                balances[derivativeItem.item.asset].liquidityPool
                = balances[derivativeItem.item.asset].liquidityPool - derivativeItem.item.collateral;

                uint256 incomeTax = AmmMath.calculateIncomeTax(derivativeItem.item.collateral,
                    IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getIncomeTaxPercentage());

                balances[derivativeItem.item.asset].treasury
                = balances[derivativeItem.item.asset].treasury + incomeTax;

                emit LogDebugUint("incomeTax", incomeTax);

            } else {
                // |I| <= D

                require(balances[derivativeItem.item.asset].liquidityPool >= absInterestDifferenceAmount,
                    Errors.MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (user != derivativeItem.item.buyer) {
                    require(closingTimestamp >= derivativeItem.item.endingTimestamp,
                        Errors.MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                //fetch "I" amount from Liquidity Pool
                balances[derivativeItem.item.asset].liquidityPool = balances[derivativeItem.item.asset].liquidityPool - absInterestDifferenceAmount;

                uint256 incomeTax = AmmMath.calculateIncomeTax(absInterestDifferenceAmount,
                    IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getIncomeTaxPercentage());

                balances[derivativeItem.item.asset].treasury
                = balances[derivativeItem.item.asset].treasury + incomeTax;

                emit LogDebugUint("incomeTax", incomeTax);

            }

        } else {
            //tokens transfered to AMM, updates on balances
            if (absInterestDifferenceAmount > derivativeItem.item.collateral) {
                // |I| > D

                uint256 incomeTax = AmmMath.calculateIncomeTax(derivativeItem.item.collateral,
                    IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getIncomeTaxPercentage());

                balances[derivativeItem.item.asset].treasury
                = balances[derivativeItem.item.asset].treasury + incomeTax;

                //transfer D - incomeTax  to Liquidity Pool
                balances[derivativeItem.item.asset].liquidityPool
                = balances[derivativeItem.item.asset].liquidityPool + derivativeItem.item.collateral - incomeTax;
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount

                emit LogDebugUint("incomeTax", incomeTax);

            } else {
                // |I| <= D

                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                if (user != derivativeItem.item.buyer) {
                    require(closingTimestamp >= derivativeItem.item.endingTimestamp,
                        Errors.MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
                }

                uint256 incomeTax = AmmMath.calculateIncomeTax(absInterestDifferenceAmount,
                    IMiltonConfiguration(_addressesManager.getMiltonConfiguration()).getIncomeTaxPercentage());

                balances[derivativeItem.item.asset].treasury
                = balances[derivativeItem.item.asset].treasury + incomeTax;

                //transfer I-incomeTax to Liquidity Pool
                balances[derivativeItem.item.asset].liquidityPool
                = balances[derivativeItem.item.asset].liquidityPool + absInterestDifferenceAmount - incomeTax;

                emit LogDebugUint("incomeTax", incomeTax);
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
        require(derivativeItem.item.id > 0, Errors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID);
        require(derivativeItem.item.state != DataTypes.DerivativeState.INACTIVE, Errors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS);
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
        require(msg.sender == _addressesManager.getMilton(), Errors.MILTON_CALLER_NOT_MILTON);
        _;
    }

    modifier onlyLiquidityPool() {
        require(msg.sender == _addressesManager.getIporLiquidityPool(), Errors.MILTON_CALLER_NOT_IPOR_LIQUIDITY_POOL);
        _;
    }

}
