// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/DerivativeLogic.sol";
import "../libraries/AmmMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Errors } from "../Errors.sol";
import { DataTypes } from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarren.sol";
import "../amm/MiltonStorage.sol";
import "../amm/IMiltonEvents.sol";
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/TotalSoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";

import "../interfaces/IIporAssetConfiguration.sol";
import "./AccessControlAssetConfiguration.sol";

contract IporAssetConfiguration is
    AccessControlAssetConfiguration(msg.sender),
    IIporAssetConfiguration
{
    address private immutable _asset;

    address private immutable _ipToken;

    uint8 private immutable _decimals;

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

    //@notice Decay factor, value between 0..1, indicator used in spread calculation
    uint256 private wadDecayFactorValue;

    //@notice Part of Spread calculation - Utilization Component Kf value - check Whitepaper
    uint256 private spreadUtilizationComponentKfValue;

    //@notice Part of Spread calculation - Utilization Component Lambda value - check Whitepaper
    uint256 private spreadUtilizationComponentLambdaValue;

    uint256 private spreadTemporaryValue;

    address private assetManagementVault;

    address private charlieTreasurer;

    //TODO: fix this name; treasureManager
    address private treasureTreasurer;

    constructor(address asset, address ipToken) {
        _asset = asset;
        _ipToken = ipToken;
        uint8 decimals = ERC20(asset).decimals();
        require(decimals > 0, Errors.CONFIG_ASSET_DECIMALS_TOO_LOW);
        _decimals = decimals;

        _maxSlippagePercentage = 100 * Constants.D18;

        //@notice taken after close position from participant who take income (trader or Milton)
        incomeTaxPercentage = AmmMath.division(Constants.D18, 10);

        //@notice taken after open position from participant who execute opening position,
        //paid after close position to participant who execute closing position
        liquidationDepositAmount = 20 * Constants.D18;

        //@notice
        openingFeePercentage = AmmMath.division(
            3 * Constants.D18,
            Constants.D4
        );
        openingFeeForTreasuryPercentage = 0;
        iporPublicationFeeAmount = 10 * Constants.D18;
        liquidityPoolMaxUtilizationPercentage =
            8 *
            AmmMath.division(Constants.D18, 10);
        maxPositionTotalAmount = 1e5 * Constants.D18;

        minCollateralizationFactorValue = 10 * Constants.D18;
        maxCollateralizationFactorValue = 50 * Constants.D18;

        spreadTemporaryValue = AmmMath.division(Constants.D18, 100);

        wadDecayFactorValue = 1e17;

        spreadUtilizationComponentKfValue = AmmMath.division(
            1 * Constants.D18,
            1000
        );
        spreadUtilizationComponentLambdaValue = AmmMath.division(
            3 * Constants.D18,
            10
        );
    }

    function getIncomeTaxPercentage() external view override returns (uint256) {
        return incomeTaxPercentage;
    }

    function setIncomeTaxPercentage(uint256 newIncomeTaxPercentage)
        external
        override
        onlyRole(INCOME_TAX_PERCENTAGE_ROLE)
    {
        require(
            newIncomeTaxPercentage <= Constants.D18,
            Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        incomeTaxPercentage = newIncomeTaxPercentage;
        emit IncomeTaxPercentageSet(newIncomeTaxPercentage);
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
        uint256 newOpeningFeeForTreasuryPercentage
    ) external override onlyRole(OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE) {
        require(
            newOpeningFeeForTreasuryPercentage <= Constants.D18,
            Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        openingFeeForTreasuryPercentage = newOpeningFeeForTreasuryPercentage;
        emit OpeningFeeForTreasuryPercentageSet(
            newOpeningFeeForTreasuryPercentage
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

    function setLiquidationDepositAmount(uint256 newLiquidationDepositAmount)
        external
        override
        onlyRole(LIQUIDATION_DEPOSIT_AMOUNT_ROLE)
    {
        liquidationDepositAmount = newLiquidationDepositAmount;
        emit LiquidationDepositAmountSet(newLiquidationDepositAmount);
    }

    function getOpeningFeePercentage()
        external
        view
        override
        returns (uint256)
    {
        return openingFeePercentage;
    }

    function setOpeningFeePercentage(uint256 newOpeningFeePercentage)
        external
        override
        onlyRole(OPENING_FEE_PERCENTAGE_ROLE)
    {
        require(
            newOpeningFeePercentage <= Constants.D18,
            Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        openingFeePercentage = newOpeningFeePercentage;
        emit OpeningFeePercentageSet(newOpeningFeePercentage);
    }

    function getIporPublicationFeeAmount()
        external
        view
        override
        returns (uint256)
    {
        return iporPublicationFeeAmount;
    }

    function setIporPublicationFeeAmount(uint256 newIporPublicationFeeAmount)
        external
        override
        onlyRole(IPOR_PUBLICATION_FEE_AMOUNT_ROLE)
    {
        iporPublicationFeeAmount = newIporPublicationFeeAmount;
        emit IporPublicationFeeAmountSet(newIporPublicationFeeAmount);
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
        uint256 newLiquidityPoolMaxUtilizationPercentage
    )
        external
        override
        onlyRole(LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE)
    {
        require(
            newLiquidityPoolMaxUtilizationPercentage <= Constants.D18,
            Errors.CONFIG_LIQUIDITY_POOL_MAX_UTILIZATION_PERCENTAGE_TOO_HIGH
        );

        liquidityPoolMaxUtilizationPercentage = newLiquidityPoolMaxUtilizationPercentage;
        emit LiquidityPoolMaxUtilizationPercentageSet(
            newLiquidityPoolMaxUtilizationPercentage
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

    function setMaxPositionTotalAmount(uint256 newMaxPositionTotalAmount)
        external
        override
        onlyRole(MAX_POSITION_TOTAL_AMOUNT_ROLE)
    {
        maxPositionTotalAmount = newMaxPositionTotalAmount;
        emit MaxPositionTotalAmountSet(newMaxPositionTotalAmount);
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
        uint256 newMaxCollateralizationFactorValue
    ) external override onlyRole(COLLATERALIZATION_FACTOR_VALUE_ROLE) {
        maxCollateralizationFactorValue = newMaxCollateralizationFactorValue;
        emit MaxCollateralizationFactorValueSet(
            newMaxCollateralizationFactorValue
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
        uint256 newMinCollateralizationFactorValue
    ) external override onlyRole(COLLATERALIZATION_FACTOR_VALUE_ROLE) {
        minCollateralizationFactorValue = newMinCollateralizationFactorValue;
        emit MinCollateralizationFactorValueSet(
            newMinCollateralizationFactorValue
        );
    }

    function getDecimals() external view override returns (uint8) {
        return _decimals;
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
        onlyRole(CHARLIE_TREASURER_ROLE)
    {
        require(newCharlieTreasurer != address(0), Errors.WRONG_ADDRESS);
        charlieTreasurer = newCharlieTreasurer;
        emit CharlieTreasurerUpdated(_asset, newCharlieTreasurer);
    }

    function getTreasureTreasurer() external view override returns (address) {
        return treasureTreasurer;
    }

    function setTreasureTreasurer(address newTreasureTreasurer)
        external
        override
        onlyRole(TREASURE_TREASURER_ROLE)
    {
        require(newTreasureTreasurer != address(0), Errors.WRONG_ADDRESS);
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
        onlyRole(ASSET_MANAGEMENT_VAULT_ROLE)
    {
        require(
            newAssetManagementVaultAddress != address(0),
            Errors.WRONG_ADDRESS
        );
        assetManagementVault = newAssetManagementVaultAddress;
        emit AssetManagementVaultUpdated(
            _asset,
            newAssetManagementVaultAddress
        );
    }

    function getDecayFactorValue() external view override returns (uint256) {
        return wadDecayFactorValue;
    }

    //@param newWadDecayFactorValue - WAD value
    function setDecayFactorValue(uint256 newWadDecayFactorValue)
        external
        override
        onlyRole(DECAY_FACTOR_VALUE_ROLE)
    {
        require(
            newWadDecayFactorValue <= Constants.D18,
            Errors.CONFIG_DECAY_FACTOR_TOO_HIGH
        );
        wadDecayFactorValue = newWadDecayFactorValue;
        emit DecayFactorValueUpdated(_asset, newWadDecayFactorValue);
    }

    function getSpreadTemporaryValue()
        external
        view
        override
        returns (uint256)
    {
        return spreadTemporaryValue;
    }

    function setSpreadTemporaryValue(uint256 newSpreadTemporaryVale)
        external
        override
    {
        spreadTemporaryValue = newSpreadTemporaryVale;
    }

    function getSpreadUtilizationComponentKfValue()
        external
        view
        override
        returns (uint256)
    {
        return spreadUtilizationComponentKfValue;
    }

    function setSpreadUtilizationComponentKfValue(
        uint256 newSpreadUtilizationComponentKfValue
    ) external override onlyRole(SPREAD_UTILIZATION_COMPONENT_KF_VALUE_ROLE) {
        spreadUtilizationComponentKfValue = newSpreadUtilizationComponentKfValue;
        emit SpreadUtilizationComponentKfValueSet(
            newSpreadUtilizationComponentKfValue
        );
    }

    function getSpreadUtilizationComponentLambdaValue()
        external
        view
        override
        returns (uint256)
    {
        return spreadUtilizationComponentLambdaValue;
    }

    function setSpreadUtilizationComponentLambdaValue(
        uint256 newSpreadUtilizationComponentLambdaValue
    )
        external
        override
        onlyRole(SPREAD_UTILIZATION_COMPONENT_LAMBDA_VALUE_ROLE)
    {
        spreadUtilizationComponentLambdaValue = newSpreadUtilizationComponentLambdaValue;
        emit SpreadUtilizationComponentLambdaValueSet(
            newSpreadUtilizationComponentLambdaValue
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
