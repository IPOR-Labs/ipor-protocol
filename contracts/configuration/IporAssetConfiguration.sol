// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "../libraries/types/DataTypes.sol";
import "../libraries/DerivativeLogic.sol";
import "../libraries/AmmMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { Errors } from "../Errors.sol";
import { DataTypes } from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarren.sol";
import "../amm/MiltonStorage.sol";
import "../amm/IMiltonEvents.sol";
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/TotalSoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";
import "../libraries/SpreadIndicatorLogic.sol";
import "../interfaces/IIporAssetConfiguration.sol";

//TODO: consider using AccessControll instead Ownable - higher flexibility
contract IporAssetConfiguration is Ownable, IIporAssetConfiguration {
    address private immutable _asset;

    address private immutable _ipToken;

    uint256 private immutable _multiplicator;

    uint256 private immutable _maxSlippagePercentage;

    uint256 private minCollateralizationFactorValue;

    uint256 private maxCollateralizationFactorValue;

    uint256 private incomeTaxPercentage;

    uint256 private liquidationDepositAmount;

    uint256 private openingFeePercentage;

    //@notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance, below value define how big
    //pie going to Treasury Balance
    uint256 private openingFeeForTreasuryPercentage;

    uint256 private iporPublicationFeeAmount;

    uint256 private liquidityPoolMaxUtilizationPercentage;

    //@notice max total amount used when opening position
    uint256 private maxPositionTotalAmount;

    //TODO: spread from configuration will be deleted, spread will be calculated in runtime
    uint256 private spreadPayFixedValue;
    uint256 private spreadRecFixedValue;

    address private assetManagementVault;
    address private charlieTreasurer;

    //TODO: fix this name; treasureManager
    address private treasureTreasurer;

    constructor(address asset, address ipToken) {
        _asset = asset;
        _ipToken = ipToken;
        uint256 multiplicator = 10**ERC20(asset).decimals();
        _multiplicator = multiplicator;
        _maxSlippagePercentage = 100 * multiplicator;

        //@notice taken after close position from participant who take income (trader or Milton)
        incomeTaxPercentage = AmmMath.division(multiplicator, 10);

        require(multiplicator != 0);

        //@notice taken after open position from participant who execute opening position, paid after close position to participant who execute closing position
        liquidationDepositAmount = 20 * multiplicator;

        //@notice
        openingFeePercentage = AmmMath.division(3 * multiplicator, 10000);
        openingFeeForTreasuryPercentage = 0;
        iporPublicationFeeAmount = 10 * multiplicator;
        liquidityPoolMaxUtilizationPercentage =
            8 *
            AmmMath.division(multiplicator, 10);
        maxPositionTotalAmount = 100000 * multiplicator;

        minCollateralizationFactorValue = 10 * multiplicator;
        maxCollateralizationFactorValue = 50 * multiplicator;

        spreadPayFixedValue = AmmMath.division(multiplicator, 100);
        spreadRecFixedValue = AmmMath.division(multiplicator, 100);
    }

    function getIncomeTaxPercentage() external view override returns (uint256) {
        return incomeTaxPercentage;
    }

    function setIncomeTaxPercentage(uint256 _incomeTaxPercentage)
        external
        override
        onlyOwner
    {
        require(
            _incomeTaxPercentage <= _multiplicator,
            Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        incomeTaxPercentage = _incomeTaxPercentage;
        emit IncomeTaxPercentageSet(_incomeTaxPercentage);
    }

    function getOpeningFeeForTreasuryPercentage()
        external
        view
        override
        returns (uint256)
    {
        return openingFeeForTreasuryPercentage;
    }

    function setOpeningFeeForTreasuryPercentage(
        uint256 _openingFeeForTreasuryPercentage
    ) external override onlyOwner {
        require(
            _openingFeeForTreasuryPercentage <= _multiplicator,
            Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        openingFeeForTreasuryPercentage = _openingFeeForTreasuryPercentage;
        emit OpeningFeeForTreasuryPercentageSet(
            _openingFeeForTreasuryPercentage
        );
    }

    function getLiquidationDepositAmount()
        external
        view
        override
        returns (uint256)
    {
        return liquidationDepositAmount;
    }

    function setLiquidationDepositAmount(uint256 _liquidationDepositAmount)
        external
        override
        onlyOwner
    {
        liquidationDepositAmount = _liquidationDepositAmount;
        emit LiquidationDepositAmountSet(_liquidationDepositAmount);
    }

    function getOpeningFeePercentage()
        external
        view
        override
        returns (uint256)
    {
        return openingFeePercentage;
    }

    function setOpeningFeePercentage(uint256 _openingFeePercentage)
        external
        override
        onlyOwner
    {
        require(
            _openingFeePercentage <= _multiplicator,
            Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        openingFeePercentage = _openingFeePercentage;
        emit OpeningFeePercentageSet(_openingFeePercentage);
    }

    function getIporPublicationFeeAmount()
        external
        view
        override
        returns (uint256)
    {
        return iporPublicationFeeAmount;
    }

    function setIporPublicationFeeAmount(uint256 _iporPublicationFeeAmount)
        external
        override
        onlyOwner
    {
        iporPublicationFeeAmount = _iporPublicationFeeAmount;
        emit IporPublicationFeeAmountSet(_iporPublicationFeeAmount);
    }

    function getLiquidityPoolMaxUtilizationPercentage()
        external
        view
        override
        returns (uint256)
    {
        return liquidityPoolMaxUtilizationPercentage;
    }

    function setLiquidityPoolMaxUtilizationPercentage(
        uint256 _liquidityPoolMaxUtilizationPercentage
    ) external override onlyOwner {
        liquidityPoolMaxUtilizationPercentage = _liquidityPoolMaxUtilizationPercentage;
        emit LiquidityPoolMaxUtilizationPercentageSet(
            _liquidityPoolMaxUtilizationPercentage
        );
    }

    function getMaxPositionTotalAmount()
        external
        view
        override
        returns (uint256)
    {
        return maxPositionTotalAmount;
    }

    function setMaxPositionTotalAmount(uint256 _maxPositionTotalAmount)
        external
        override
        onlyOwner
    {
        maxPositionTotalAmount = _maxPositionTotalAmount;
        emit MaxPositionTotalAmountSet(_maxPositionTotalAmount);
    }

    function getSpreadPayFixedValue() external view override returns (uint256) {
        return spreadPayFixedValue;
    }

    function setSpreadPayFixedValue(uint256 spread) external override {
        spreadPayFixedValue = spread;
    }

    function getSpreadRecFixedValue() external view override returns (uint256) {
        return spreadRecFixedValue;
    }

    function setSpreadRecFixedValue(uint256 spread) external override {
        spreadRecFixedValue = spread;
    }

    function getMaxCollateralizationFactorValue()
        external
        view
        override
        returns (uint256)
    {
        return maxCollateralizationFactorValue;
    }

    function setMaxCollateralizationFactorValue(
        uint256 _maxCollateralizationFactorValue
    ) external override onlyOwner {
        maxCollateralizationFactorValue = _maxCollateralizationFactorValue;
        emit MaxCollateralizationFactorValueSet(
            _maxCollateralizationFactorValue
        );
    }

    function getMinCollateralizationFactorValue()
        external
        view
        override
        returns (uint256)
    {
        return minCollateralizationFactorValue;
    }

    function setMinCollateralizationFactorValue(
        uint256 _minCollateralizationFactorValue
    ) external override onlyOwner {
        minCollateralizationFactorValue = _minCollateralizationFactorValue;
        emit MinCollateralizationFactorValueSet(
            _minCollateralizationFactorValue
        );
    }

    function getMultiplicator() external view override returns (uint256) {
        return _multiplicator;
    }

    function getMaxSlippagePercentage()
        external
        view
        override
        returns (uint256)
    {
        return _maxSlippagePercentage;
    }

    function getCharlieTreasurer() external view override returns (address) {
        return charlieTreasurer;
    }

    function setCharlieTreasurer(address newCharlieTreasurer)
        external
        override
        onlyOwner
    {
        charlieTreasurer = newCharlieTreasurer;
        emit CharlieTreasurerUpdated(_asset, newCharlieTreasurer);
    }

    function getTreasureTreasurer() external view override returns (address) {
        return treasureTreasurer;
    }

    function setTreasureTreasurer(address newTreasureTreasurer)
        external
        override
        onlyOwner
    {
        treasureTreasurer = newTreasureTreasurer;
        emit TreasureTreasurerUpdated(_asset, newTreasureTreasurer);
    }

    function getIpToken() external view override returns (address) {
        return _ipToken;
    }

    function getAssetManagementVault()
        external
        view
        override
        returns (address)
    {
        return assetManagementVault;
    }

    function setAssetManagementVault(address newAssetManagementVaultAddress)
        external
        override
        onlyOwner
    {
        assetManagementVault = newAssetManagementVaultAddress;
        emit AssetManagementVaultUpdated(
            _asset,
            newAssetManagementVaultAddress
        );
    }
}

//TODO: remove drizzle from DevTool and remove this redundant smart contracts below:
contract IporAssetConfigurationUsdt is IporAssetConfiguration {
    constructor(address asset, address ipToken)
        IporAssetConfiguration(asset, ipToken)
    {}
}

contract IporAssetConfigurationUsdc is IporAssetConfiguration {
    constructor(address asset, address ipToken)
        IporAssetConfiguration(asset, ipToken)
    {}
}

contract IporAssetConfigurationDai is IporAssetConfiguration {
    constructor(address asset, address ipToken)
        IporAssetConfiguration(asset, ipToken)
    {}
}
