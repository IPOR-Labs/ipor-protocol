// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";
import "../libraries/DerivativeLogic.sol";
import "../libraries/AmmMath.sol";
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {Errors} from '../Errors.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IWarren.sol";
import '../amm/MiltonStorage.sol';
import '../amm/IMiltonEvents.sol';
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/TotalSoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";
import "../libraries/SpreadIndicatorLogic.sol";
import "../interfaces/IIporConfiguration.sol";

//TODO: consider using AccessControll instead Ownable - higher flexibility
contract IporConfiguration is Ownable, IIporConfiguration {

    address private _asset;

    uint256 multiplicator;

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

    //TODO: spread from configuration will be deleted, spread will be calculated in runtime
    mapping(address => uint256) spreadPayFixedValues;
    mapping(address => uint256) spreadRecFixedValues;

    IIporAddressesManager internal _addressesManager;

    constructor(address asset) {
        _asset = asset;
        multiplicator = 10 ** ERC20(asset).decimals();
    }

    function initialize(IIporAddressesManager addressesManager) public onlyOwner {
        _addressesManager = addressesManager;

        //@notice taken after close position from participant who take income (trader or Milton)
        incomeTaxPercentage = 1e17;

        require(multiplicator != 0);

        //@notice taken after open position from participant who execute opening position, paid after close position to participant who execute closing position
        liquidationDepositAmount = 20 * multiplicator;

        //@notice
        openingFeePercentage = 1e16;
        openingFeeForTreasuryPercentage = 0;
        iporPublicationFeeAmount = 10 * multiplicator;
        liquidityPoolMaxUtilizationPercentage = 8 * 1e17;
        maxPositionTotalAmount = 100000 * multiplicator;

        minCollateralizationFactorValue = 10 * multiplicator;
        maxCollateralizationFactorValue = 50 * multiplicator;

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
        require(_incomeTaxPercentage <= multiplicator, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        incomeTaxPercentage = _incomeTaxPercentage;
        emit IncomeTaxPercentageSet(_incomeTaxPercentage);
    }

    function getOpeningFeeForTreasuryPercentage() external override view returns (uint256) {
        return openingFeeForTreasuryPercentage;
    }

    function setOpeningFeeForTreasuryPercentage(uint256 _openingFeeForTreasuryPercentage) external override onlyOwner {
        require(_openingFeeForTreasuryPercentage <= multiplicator, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
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
        require(_openingFeePercentage <= multiplicator, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
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

    function setSpreadPayFixedValue(address asset, uint256 spread) external override {
        spreadPayFixedValues[asset] = spread;
    }

    function getSpreadRecFixedValue(address asset) external override view returns (uint256) {
        return spreadRecFixedValues[asset];
    }

    function setSpreadRecFixedValue(address asset, uint256 spread) external override {
        spreadRecFixedValues[asset] = spread;
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

    function getMultiplicator() external view override returns(uint256) {
        return multiplicator;
    }
}
