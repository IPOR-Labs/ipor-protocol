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
import "../interfaces/IIporAssetConfiguration.sol";

//TODO: consider using AccessControll instead Ownable - higher flexibility
contract IporAssetConfiguration is Ownable, IIporAssetConfiguration {

    address private immutable _asset;

    uint256 private immutable _multiplicator;

    uint256 private immutable _maxSlippagePercentage;

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
    uint256 spreadPayFixedValue;
    uint256 spreadRecFixedValue;

    address ipToken;
    address assetManagementVault;
    address charlieTreasurer;

    //TODO: fix this name;
    address treasureTreasurer;

    IIporConfiguration internal _iporConfiguration;

    constructor(address asset) {
        _asset = asset;
        _multiplicator = 10 ** ERC20(asset).decimals();
        _maxSlippagePercentage = 100 * 10 ** ERC20(asset).decimals();
    }

    function initialize(IIporConfiguration addressesManager) public onlyOwner {
        _iporConfiguration = addressesManager;

        //@notice taken after close position from participant who take income (trader or Milton)
        incomeTaxPercentage = AmmMath.division(_multiplicator, 10);

        require(_multiplicator != 0);

        //@notice taken after open position from participant who execute opening position, paid after close position to participant who execute closing position
        liquidationDepositAmount = 20 * _multiplicator;

        //@notice
        openingFeePercentage = AmmMath.division(_multiplicator, 100);
        openingFeeForTreasuryPercentage = 0;
        iporPublicationFeeAmount = 10 * _multiplicator;
        liquidityPoolMaxUtilizationPercentage = 8 * AmmMath.division(_multiplicator, 10);
        maxPositionTotalAmount = 100000 * _multiplicator;

        minCollateralizationFactorValue = 10 * _multiplicator;
        maxCollateralizationFactorValue = 50 * _multiplicator;

        spreadPayFixedValue = AmmMath.division(_multiplicator, 100);
        spreadRecFixedValue = AmmMath.division(_multiplicator, 100);

    }

    function getIncomeTaxPercentage() external override view returns (uint256) {
        return incomeTaxPercentage;
    }

    function setIncomeTaxPercentage(uint256 _incomeTaxPercentage) external override onlyOwner {
        require(_incomeTaxPercentage <= _multiplicator, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
        incomeTaxPercentage = _incomeTaxPercentage;
        emit IncomeTaxPercentageSet(_incomeTaxPercentage);
    }

    function getOpeningFeeForTreasuryPercentage() external override view returns (uint256) {
        return openingFeeForTreasuryPercentage;
    }

    function setOpeningFeeForTreasuryPercentage(uint256 _openingFeeForTreasuryPercentage) external override onlyOwner {
        require(_openingFeeForTreasuryPercentage <= _multiplicator, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
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
        require(_openingFeePercentage <= _multiplicator, Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED);
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

    function getSpreadPayFixedValue() external override view returns (uint256) {
        return spreadPayFixedValue;
    }

    function setSpreadPayFixedValue(uint256 spread) external override {
        spreadPayFixedValue = spread;
    }

    function getSpreadRecFixedValue() external override view returns (uint256) {
        return spreadRecFixedValue;
    }

    function setSpreadRecFixedValue(uint256 spread) external override {
        spreadRecFixedValue = spread;
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

    function getMultiplicator() external view override returns (uint256) {
        return _multiplicator;
    }

    function getMaxSlippagePercentage() external view override returns (uint256) {
        return _maxSlippagePercentage;
    }

    function getCharlieTreasurer() external override view returns (address) {
        return charlieTreasurer;
    }

    function setCharlieTreasurer(address newCharlieTreasurer) external override onlyOwner {
        charlieTreasurer = newCharlieTreasurer;
        emit CharlieTreasurerUpdated(_asset, newCharlieTreasurer);
    }

    function getTreasureTreasurer() external override view returns (address) {
        return treasureTreasurer;
    }

    function setTreasureTreasurer(address newTreasureTreasurer) external override onlyOwner {
        treasureTreasurer = newTreasureTreasurer;
        emit TreasureTreasurerUpdated(_asset, newTreasureTreasurer);
    }

    function getIpToken() external override view returns (address){
        return ipToken;
    }

    function setIpToken(address ipTokenAddress) external override onlyOwner {
        ipToken = ipTokenAddress;
        emit IpTokenAddressUpdated(_asset, ipTokenAddress);
    }

    function getAssetManagementVault() external override view returns (address){
        return assetManagementVault;
    }

    function setAssetManagementVault(address newAssetManagementVaultAddress) external override onlyOwner {
        assetManagementVault = newAssetManagementVaultAddress;
        emit AssetManagementVaultUpdated(_asset, newAssetManagementVaultAddress);
    }
}

//TODO: remove drizzle from DevTool and remove this redundant smart contracts below:
contract IporAssetConfigurationUsdt is IporAssetConfiguration {
    constructor(address asset) IporAssetConfiguration(asset) {}
}

contract IporAssetConfigurationUsdc is IporAssetConfiguration {
    constructor(address asset) IporAssetConfiguration(asset) {}
}

contract IporAssetConfigurationDai is IporAssetConfiguration {
    constructor(address asset) IporAssetConfiguration(asset) {}
}