// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../libraries/DerivativeLogic.sol";
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/TotalSoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";
import "../interfaces/IIporConfiguration.sol";
import "../libraries/types/DataTypes.sol";
import "../libraries/SpreadIndicatorLogic.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporAssetConfiguration.sol";


contract MiltonStorage is Ownable, IMiltonStorage {

    using DerivativeLogic for DataTypes.IporDerivative;
    using SoapIndicatorLogic for DataTypes.SoapIndicator;
    using SpreadIndicatorLogic for DataTypes.SpreadIndicator;
    using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;
    using DerivativesView for DataTypes.MiltonDerivatives;

    IIporConfiguration internal _addressesManager;

    mapping(address => DataTypes.MiltonTotalBalance) public balances;

    mapping(address => DataTypes.TotalSoapIndicator) public soapIndicators;

    //TODO: when spread is calculated in final way then consider remove this storage (maybe will be not needed)
    mapping(address => DataTypes.TotalSpreadIndicator) public spreadIndicators;

    DataTypes.MiltonDerivatives public derivatives;

    function initialize(IIporConfiguration addressesManager) public onlyOwner {
        _addressesManager = addressesManager;
    }

    //@notice add asset address to MiltonStorage structures
    function addAsset(address asset) external override onlyOwner {

        require(_addressesManager.assetSupported(asset) == 1, Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED);

        soapIndicators[asset] = DataTypes.TotalSoapIndicator(
            DataTypes.SoapIndicator(0, DataTypes.DerivativeDirection.PayFixedReceiveFloating, 0, 0, 0, 0, 0),
            DataTypes.SoapIndicator(0, DataTypes.DerivativeDirection.PayFloatingReceiveFixed, 0, 0, 0, 0, 0)
        );

        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(_addressesManager.getIporAssetConfiguration(asset));
        uint256 multiplicator = iporAssetConfiguration.getMultiplicator();

        //TODO: clarify what is default value for spread when spread is calculated in final way
        spreadIndicators[asset] = DataTypes.TotalSpreadIndicator(
            DataTypes.SpreadIndicator(multiplicator), DataTypes.SpreadIndicator(multiplicator)
        );
    }

    function getBalance(address asset) external override view returns (DataTypes.MiltonTotalBalance memory) {
        return balances[asset];
    }

    function getTotalOutstandingNotional(address asset) external override view returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional) {
        DataTypes.TotalSoapIndicator memory totalSoapIndicator = soapIndicators[asset];
        payFixedTotalNotional = totalSoapIndicator.pf.totalNotional;
        recFixedTotalNotional = totalSoapIndicator.rf.totalNotional;
    }

    function getLastDerivativeId() external override view returns (uint256) {
        return derivatives.lastDerivativeId;
    }

    function addLiquidity(address asset, uint256 liquidityAmount) external override onlyJoseph {
        require(liquidityAmount > 0, Errors.MILTON_DEPOSIT_AMOUNT_TOO_LOW);
        balances[asset].liquidityPool = balances[asset].liquidityPool + liquidityAmount;
    }

    function subtractLiquidity(address asset, uint256 liquidityAmount) external override onlyJoseph {
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
        _updateBalancesWhenOpenPosition(iporDerivative.asset, iporDerivative.collateral, iporDerivative.fee.openingAmount, iporDerivative.multiplicator);
        _updateSoapIndicatorsWhenOpenPosition(iporDerivative);

    }

    function updateStorageWhenClosePosition(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp) external override onlyMilton {

        _updateMiltonDerivativesWhenClosePosition(derivativeItem);
        _updateBalancesWhenClosePosition(user, derivativeItem, positionValue, closingTimestamp);
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
        spreadPayFixedValue = IIporAssetConfiguration(_addressesManager.getIporAssetConfiguration(asset)).getSpreadPayFixedValue(),
        spreadRecFixedValue = IIporAssetConfiguration(_addressesManager.getIporAssetConfiguration(asset)).getSpreadRecFixedValue()
        );
    }

    function calculateSoap(
        address asset,
        uint256 ibtPrice,
        uint256 calculateTimestamp) external override view returns (int256 soapPf, int256 soapRf, int256 soap) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(_addressesManager.getIporAssetConfiguration(asset));
        uint256 multiplicator = iporAssetConfiguration.getMultiplicator();

        (int256 qSoapPf, int256 qSoapRf, int256 qSoap) = _calculateQuasiSoap(asset, ibtPrice, calculateTimestamp, multiplicator);
        int256 p2YearInSeconds = int256(multiplicator * multiplicator * Constants.YEAR_IN_SECONDS);
        return (
        soapPf = AmmMath.divisionInt(qSoapPf, p2YearInSeconds),
        soapRf = AmmMath.divisionInt(qSoapRf, p2YearInSeconds),
        soap = AmmMath.divisionInt(qSoap, p2YearInSeconds)
        );
    }

    function _calculateQuasiSoap(
        address asset,
        uint256 ibtPrice,
        uint256 calculateTimestamp, uint256 multiplicator) internal view returns (int256 soapPf, int256 soapRf, int256 soap){
        (int256 _soapPf, int256 _soapRf) = soapIndicators[asset].calculateQuasiSoap(calculateTimestamp, ibtPrice, multiplicator);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soapPf + _soapRf);
    }

    function _updateBalancesWhenOpenPosition(address asset, uint256 collateral, uint256 openingFeeAmount, uint256 multiplicator) internal {

        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(_addressesManager.getIporAssetConfiguration(asset));

        balances[asset].derivatives = balances[asset].derivatives + collateral;
        balances[asset].openingFee = balances[asset].openingFee + openingFeeAmount;
        balances[asset].liquidationDeposit = balances[asset].liquidationDeposit + iporAssetConfiguration.getLiquidationDepositAmount();
        balances[asset].iporPublicationFee = balances[asset].iporPublicationFee + iporAssetConfiguration.getIporPublicationFeeAmount();

        uint256 openingFeeForTreasurePercentage = iporAssetConfiguration.getOpeningFeeForTreasuryPercentage();
        (uint256 openingFeeLPValue, uint256 openingFeeTreasuryValue) = _splitOpeningFeeAmount(openingFeeAmount, openingFeeForTreasurePercentage, multiplicator);
        balances[asset].liquidityPool = balances[asset].liquidityPool + openingFeeLPValue;
        balances[asset].treasury = balances[asset].treasury + openingFeeTreasuryValue;
    }

    function _splitOpeningFeeAmount(uint256 openingFeeAmount, uint256 openingFeeForTreasurePercentage, uint256 multiplicator) internal pure returns (uint256 liquidityPoolValue, uint256 treasuryValue) {
        treasuryValue = AmmMath.division(openingFeeAmount * openingFeeForTreasurePercentage, multiplicator);
        liquidityPoolValue = openingFeeAmount - treasuryValue;
    }

    function _updateBalancesWhenClosePosition(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp) internal {

        uint256 abspositionValue = AmmMath.absoluteValue(positionValue);

        //decrease from balances the liquidation deposit
        require(balances[derivativeItem.item.asset].liquidationDeposit >=
            derivativeItem.item.fee.liquidationDepositAmount,
            Errors.MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW);

        balances[derivativeItem.item.asset].liquidationDeposit
        = balances[derivativeItem.item.asset].liquidationDeposit - derivativeItem.item.fee.liquidationDepositAmount;

        balances[derivativeItem.item.asset].derivatives
        = balances[derivativeItem.item.asset].derivatives - derivativeItem.item.collateral;

        if (abspositionValue < derivativeItem.item.collateral) {
            //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (user != derivativeItem.item.buyer) {
                require(closingTimestamp >= derivativeItem.item.endingTimestamp,
                    Errors.MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY);
            }
        }

        uint256 incomeTax = AmmMath.calculateIncomeTax(
            abspositionValue,
            IIporAssetConfiguration(_addressesManager.getIporAssetConfiguration(derivativeItem.item.asset)).getIncomeTaxPercentage(), derivativeItem.item.multiplicator);

        balances[derivativeItem.item.asset].treasury
        = balances[derivativeItem.item.asset].treasury + incomeTax;

        if (positionValue > 0) {

            require(balances[derivativeItem.item.asset].liquidityPool >= abspositionValue,
                Errors.MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);

            balances[derivativeItem.item.asset].liquidityPool
            = balances[derivativeItem.item.asset].liquidityPool - abspositionValue;

        } else {
            balances[derivativeItem.item.asset].liquidityPool
            = balances[derivativeItem.item.asset].liquidityPool + abspositionValue - incomeTax;
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
            iporDerivative.indicator.ibtQuantity,
            iporDerivative.multiplicator
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
            derivativeItem.item.indicator.ibtQuantity, derivativeItem.item.multiplicator
        );
    }

    modifier onlyMilton() {
        //TODO: check if msg.sender == tx.origin - czy jest smart contractem de facto
        require(msg.sender == _addressesManager.getMilton(), Errors.MILTON_CALLER_NOT_MILTON);
        _;
    }

    modifier onlyJoseph() {
        //TODO: check if msg.sender == tx.origin - czy jest smart contractem de facto
        require(msg.sender == _addressesManager.getJoseph(), Errors.MILTON_CALLER_NOT_JOSEPH);
        _;
    }

}
