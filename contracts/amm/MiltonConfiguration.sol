// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";
import "../libraries/DerivativeLogic.sol";
import "../libraries/AmmMath.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
//TODO: clarify if better is to have external libraries in local folder - pros for local folder - can execute Mythril and Karl static analisys
import '@openzeppelin/contracts/access/Ownable.sol';
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

//TODO: Ownable here - consider add admin address to MiltonAddressesManager and here use custom modifier onlyOwner which checks if sender is an admin
//TODO: rename to IporConfiguration
contract MiltonConfiguration is Ownable, IMiltonConfiguration {

    uint256 minCollateralizationFactorValue;

    uint256 maxCollateralizationFactorValue;

    uint256 incomeTaxPercentage;

    uint256 liquidationDepositAmount;

    uint256 openingFeePercentage;

    //@notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance, below value define how big
    //pie going to Treasury Balance
    uint256 openingFeeForTreasuryPercentage;

    uint256 iporPublicationFeeAmount;

    uint256 liquidityPoolMaxUtilizationPercentage;

    //@notice max total amount used when opening position
    uint256 maxPositionTotalAmount;

    uint256 coolOffPeriodInSec;

    //TODO: spread from configuration will be deleted, spread will be calculated in runtime
    mapping(address => uint256) spreadPayFixedValues;
    mapping(address => uint256) spreadRecFixedValues;

    IIporAddressesManager internal _addressesManager;

    function initialize(IIporAddressesManager addressesManager) public onlyOwner {
        _addressesManager = addressesManager;

        //@notice taken after close position from participant who take income (trader or Milton)
        incomeTaxPercentage = 1e17;

        //@notice taken after open position from participant who execute opening position, paid after close position to participant who execute closing position
        liquidationDepositAmount = 20 * Constants.MD;

        //@notice 
        openingFeePercentage = 1e16;
        openingFeeForTreasuryPercentage = 0;
        iporPublicationFeeAmount = 10 * Constants.MD;
        liquidityPoolMaxUtilizationPercentage = 8 * 1e17;
        maxPositionTotalAmount = 100000 * Constants.MD;

        minCollateralizationFactorValue = 10 * Constants.MD;
        maxCollateralizationFactorValue = 50 * Constants.MD;

        //@notice 14 days
        coolOffPeriodInSec = 1209600;

        address[] memory assets = _addressesManager.getAssets();

        for (uint256 i = 0; i < assets.length; i++) {
            spreadPayFixedValues[assets[i]] = 1e16;
            spreadRecFixedValues[assets[i]] = 1e16;
        }
    }

    function getIncomeTaxPercentage() external override view returns (uint256) {
        return incomeTaxPercentage;
    }

    function setIncomeTaxPercentage(uint256 _incomeTaxPercentage) external override onlyOwner {
        require(_incomeTaxPercentage <= Constants.MD, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        incomeTaxPercentage = _incomeTaxPercentage;
        emit IncomeTaxPercentageSet(_incomeTaxPercentage);
    }

    function getOpeningFeeForTreasuryPercentage() external override view returns (uint256) {
        return openingFeeForTreasuryPercentage;
    }

    function setOpeningFeeForTreasuryPercentage(uint256 _openingFeeForTreasuryPercentage) external override onlyOwner {
        require(_openingFeeForTreasuryPercentage <= Constants.MD, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        openingFeeForTreasuryPercentage = _openingFeeForTreasuryPercentage;
        emit OpeningFeeForTreasuryPercentageSet(_openingFeeForTreasuryPercentage);
    }

    function getLiquidationDepositAmount() external override view returns (uint256) {
        return liquidationDepositAmount;
    }

    function setLiquidationDepositAmount(uint256 _liquidationDepositAmount) external override onlyOwner {
        liquidationDepositAmount = _liquidationDepositAmount;
        emit LiquidationDepositAmountSet(_liquidationDepositAmount);
    }

    function getOpeningFeePercentage() external override view returns (uint256) {
        return openingFeePercentage;
    }

    function setOpeningFeePercentage(uint256 _openingFeePercentage) external override onlyOwner {
        require(_openingFeePercentage <= Constants.MD, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        openingFeePercentage = _openingFeePercentage;
        emit OpeningFeePercentageSet(_openingFeePercentage);
    }

    function getIporPublicationFeeAmount() external override view returns (uint256) {
        return iporPublicationFeeAmount;
    }

    function setIporPublicationFeeAmount(uint256 _iporPublicationFeeAmount) external override onlyOwner {
        iporPublicationFeeAmount = _iporPublicationFeeAmount;
        emit IporPublicationFeeAmountSet(_iporPublicationFeeAmount);
    }

    function getLiquidityPoolMaxUtilizationPercentage() external override view returns (uint256) {
        return liquidityPoolMaxUtilizationPercentage;
    }

    function setLiquidityPoolMaxUtilizationPercentage(uint256 _liquidityPoolMaxUtilizationPercentage) external override onlyOwner {
        liquidityPoolMaxUtilizationPercentage = _liquidityPoolMaxUtilizationPercentage;
        emit LiquidityPoolMaxUtilizationPercentageSet(_liquidityPoolMaxUtilizationPercentage);
    }

    function getMaxPositionTotalAmount() external override view returns (uint256) {
        return maxPositionTotalAmount;
    }

    function setMaxPositionTotalAmount(uint256 _maxPositionTotalAmount) external override onlyOwner {
        maxPositionTotalAmount = _maxPositionTotalAmount;
        emit MaxPositionTotalAmountSet(_maxPositionTotalAmount);
    }

    function getSpreadPayFixedValue(address asset) external override view returns (uint256) {
        return spreadPayFixedValues[asset];
    }

    function setSpreadPayFixedValue(address asset, uint256 _spread) external override {
        spreadPayFixedValues[asset] = _spread;
    }

    function getSpreadRecFixedValue(address asset) external override view returns (uint256) {
        return spreadRecFixedValues[asset];
    }

    function setSpreadRecFixedValue(address asset, uint256 _spread) external override {
        spreadRecFixedValues[asset] = _spread;
    }

    function getMaxCollateralizationFactorValue() external override view returns (uint256) {
        return maxCollateralizationFactorValue;
    }

    function setMaxCollateralizationFactorValue(uint256 _maxCollateralizationFactorValue) external override onlyOwner {
        maxCollateralizationFactorValue = _maxCollateralizationFactorValue;
        emit MaxCollateralizationFactorValueSet(_maxCollateralizationFactorValue);
    }

    function getMinCollateralizationFactorValue() external override view returns (uint256) {
        return minCollateralizationFactorValue;
    }

    function setMinCollateralizationFactorValue(uint256 _minCollateralizationFactorValue) external override onlyOwner {
        minCollateralizationFactorValue = _minCollateralizationFactorValue;
        emit MinCollateralizationFactorValueSet(_minCollateralizationFactorValue);
    }

    function getCoolOffPeriodInSec() external override view returns (uint256) {
        return coolOffPeriodInSec;
    }

    function setCoolOffPeriodInSec(uint256 _coolOffPeriodInSec) external override onlyOwner {
        coolOffPeriodInSec = _coolOffPeriodInSec;
        emit CoolOffPeriodInSecSet(_coolOffPeriodInSec);
    }
}
