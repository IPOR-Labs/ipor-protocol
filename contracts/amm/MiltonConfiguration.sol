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
contract MiltonConfiguration is Ownable, IMiltonConfiguration {

    uint256 minCollateralizationValue;
    uint256 maxCollateralizationValue;

    uint256 incomeTaxPercentage;
    uint256 maxIncomeTaxPercentage;

    uint256 liquidationDepositFeeAmount;
    uint256 maxLiquidationDepositFeeAmount;

    uint256 openingFeePercentage;
    uint256 maxOpeningFeePercentage;

    //@notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance, below value define how big
    //pie going to Treasury Balance
    uint256 openingFeeForTreasuryPercentage;

    uint256 iporPublicationFeeAmount;
    uint256 maxIporPublicationFeeAmount;

    uint256 liquidityPoolMaxUtilizationPercentage;

    //@notice max total amount used when opening position
    uint256 maxPositionTotalAmount;

    uint256 spread;

    constructor() {
        incomeTaxPercentage = 1e17;
        maxIncomeTaxPercentage = 2e17;

        liquidationDepositFeeAmount = 20 * Constants.MD;
        //TODO: clarify this value:
        maxLiquidationDepositFeeAmount = 100 * Constants.MD;

        openingFeePercentage = 1e16;
        maxOpeningFeePercentage = Constants.MD;
        openingFeeForTreasuryPercentage = 0;

        iporPublicationFeeAmount = 10 * Constants.MD;
        maxIporPublicationFeeAmount = 1000 * Constants.MD;

        liquidityPoolMaxUtilizationPercentage = 8 * 1e17;

        maxPositionTotalAmount = 100000 * Constants.MD;

        spread = 1e16;

        minCollateralizationValue = 10 * Constants.MD;
        maxCollateralizationValue = 50 * Constants.MD;

    }

    function getIncomeTaxPercentage() external override view returns (uint256) {
        return incomeTaxPercentage;
    }

    function setIncomeTaxPercentage(uint256 _incomeTaxPercentage) external override onlyOwner {
        require(_incomeTaxPercentage <= maxIncomeTaxPercentage, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        incomeTaxPercentage = _incomeTaxPercentage;
        emit IncomeTaxPercentageSet(_incomeTaxPercentage);
    }

    function getMaxIncomeTaxPercentage() external override view returns (uint256) {
        return maxIncomeTaxPercentage;
    }

    function setMaxIncomeTaxPercentage(uint256 _maxIncomeTaxPercentage) external override onlyOwner {
        require(_maxIncomeTaxPercentage <= 1e18, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        maxIncomeTaxPercentage = _maxIncomeTaxPercentage;
        emit MaxIncomeTaxPercentageSet(_maxIncomeTaxPercentage);
    }

    function getOpeningFeeForTreasuryPercentage() external override view returns (uint256) {
        return openingFeeForTreasuryPercentage;
    }

    function setOpeningFeeForTreasuryPercentage(uint256 _openingFeeForTreasuryPercentage) external override onlyOwner {
        require(_openingFeeForTreasuryPercentage <= Constants.MD, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        openingFeeForTreasuryPercentage = _openingFeeForTreasuryPercentage;
        emit OpeningFeeForTreasuryPercentageSet(_openingFeeForTreasuryPercentage);
    }

    function getLiquidationDepositFeeAmount() external override view returns (uint256) {
        return liquidationDepositFeeAmount;
    }

    function setLiquidationDepositFeeAmount(uint256 _liquidationDepositFeeAmount) external override onlyOwner {
        require(_liquidationDepositFeeAmount <= maxLiquidationDepositFeeAmount, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        liquidationDepositFeeAmount = _liquidationDepositFeeAmount;
        emit LiquidationDepositFeeAmountSet(_liquidationDepositFeeAmount);
    }

    function getMaxLiquidationDepositFeeAmount() external override view returns (uint256) {
        return maxLiquidationDepositFeeAmount;
    }

    function setMaxLiquidationDepositFeeAmount(uint256 _maxLiquidationDepositFeeAmount) external override onlyOwner {
        maxLiquidationDepositFeeAmount = _maxLiquidationDepositFeeAmount;
        emit MaxLiquidationDepositFeeAmountSet(_maxLiquidationDepositFeeAmount);
    }

    function getOpeningFeePercentage() external override view returns (uint256) {
        return openingFeePercentage;
    }

    function setOpeningFeePercentage(uint256 _openingFeePercentage) external override onlyOwner {
        require(_openingFeePercentage <= maxOpeningFeePercentage, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        openingFeePercentage = _openingFeePercentage;
        emit OpeningFeePercentageSet(_openingFeePercentage);
    }

    function getMaxOpeningFeePercentage() external override view returns (uint256) {
        return maxOpeningFeePercentage;
    }

    function setMaxOpeningFeePercentage(uint256 _maxOpeningFeePercentage) external override onlyOwner {
        require(_maxOpeningFeePercentage <= 1e18, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        maxOpeningFeePercentage = _maxOpeningFeePercentage;
        emit MaxOpeningFeePercentageSet(_maxOpeningFeePercentage);
    }

    function getIporPublicationFeeAmount() external override view returns (uint256) {
        return iporPublicationFeeAmount;
    }

    function setIporPublicationFeeAmount(uint256 _iporPublicationFeeAmount) external override onlyOwner {
        require(_iporPublicationFeeAmount <= maxIporPublicationFeeAmount, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        iporPublicationFeeAmount = _iporPublicationFeeAmount;
        emit IporPublicationFeeAmountSet(_iporPublicationFeeAmount);
    }

    function getMaxIporPublicationFeeAmount() external override view returns (uint256) {
        return maxIporPublicationFeeAmount;
    }

    function setMaxIporPublicationFeeAmount(uint256 _maxIporPublicationFeeAmount) external override onlyOwner {
        maxIporPublicationFeeAmount = _maxIporPublicationFeeAmount;
        emit MaxIporPublicationFeeAmountSet(_maxIporPublicationFeeAmount);
    }

    function getLiquidityPoolMaxUtilizationPercentage() external override view returns (uint256) {
        return liquidityPoolMaxUtilizationPercentage;
    }

    function setLiquidityPoolMaxUtilizationPercentage(uint256 _liquidityPoolMaxUtilizationPercentage) external override onlyOwner {
        require(_liquidityPoolMaxUtilizationPercentage <= 1e18, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
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

    function getSpread() external override view returns (uint256) {
        return spread;
    }

    function setSpread(uint256 _spread) external override {
        spread = _spread;
        emit SpreadSet(_spread);
    }

    function getMaxCollateralizationValue() external override view returns (uint256) {
        return maxCollateralizationValue;
    }

    function setMaxCollateralizationValue(uint256 _maxCollateralizationValue) external override onlyOwner {
        maxCollateralizationValue = _maxCollateralizationValue;
        emit MaxCollateralizationValueSet(_maxCollateralizationValue);
    }

    function getMinCollateralizationValue() external override view returns (uint256) {
        return minCollateralizationValue;
    }

    function setMinCollateralizationValue(uint256 _minCollateralizationValue) external override onlyOwner {
        minCollateralizationValue = _minCollateralizationValue;
        emit MinCollateralizationValueSet(_minCollateralizationValue);
    }
}
