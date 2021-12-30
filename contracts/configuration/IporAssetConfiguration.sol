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

//TODO: combine with MiltonStorage to minimize external calls in modifiers and simplify code
contract IporAssetConfiguration is
    AccessControlAssetConfiguration(msg.sender),
    IIporAssetConfiguration
{
    address private immutable _asset;

    address private immutable _ipToken;

    uint8 private immutable _decimals;

    uint256 private immutable _maxSlippagePercentage;

    uint256 private _minCollateralizationFactorValue;

    uint256 private _maxCollateralizationFactorValue;

    uint256 private _incomeTaxPercentage;

    uint256 private _liquidationDepositAmount;

    uint256 private _openingFeePercentage;

    //@notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance, below value define how big
    //pie going to Treasury Balance
    uint256 private _openingFeeForTreasuryPercentage;

    uint256 private _iporPublicationFeeAmount;

    uint256 private _liquidityPoolMaxUtilizationPercentage;

    //@notice max total amount used when opening position
    uint256 private _maxPositionTotalAmount;

    //@notice Decay factor, value between 0..1, indicator used in spread calculation
    uint256 private _wadDecayFactorValue;

	//TODO: move spread params to IporSpreadConfiguration smart contract

    //@notice Part of Spread calculation - Demand Component Kf value - check Whitepaper
    uint256 private _spreadDemandComponentKfValue;

	//@notice Part of Spread calculation - Demand Component Lambda value - check Whitepaper
    uint256 private _spreadDemandComponentLambdaValue;

    //@notice Part of Spread calculation - Demand Component KOmega value - check Whitepaper
    uint256 private _spreadDemandComponentKOmegaValue;

	//@notice Part of Spread calculation - Demand Component Max Liquidity Redemption Value - check Whitepaper
    uint256 private _spreadDemandComponentMaxLiquidityRedemptionValue;

	//@notice Part of Spread calculation - At Par Component - Volatility Kvol value - check Whitepaper
    uint256 private _spreadAtParComponentKVolValue;

    //@notice Part of Spread calculation - At Par Component - Historical Deviation Khist value - check Whitepaper
    uint256 private _spreadAtParComponentKHistValue;

	//@notice Spread Max Value
    uint256 private _spreadMaxValue;

	//TODO: rename DemandComponent to DC, AtParComponent to PC or DemandC, AtParC

    uint256 private _spreadTemporaryValue;

    address private _assetManagementVault;

    address private _charlieTreasurer;

    //TODO: fix this name; treasureManager
    address private _treasureTreasurer;

    constructor(address asset, address ipToken) {
        _asset = asset;
        _ipToken = ipToken;
        uint8 decimals = ERC20(asset).decimals();
        require(decimals > 0, Errors.CONFIG_ASSET_DECIMALS_TOO_LOW);
        _decimals = decimals;

        _maxSlippagePercentage = 100 * Constants.D18;

        //@notice taken after close position from participant who take income (trader or Milton)
        _incomeTaxPercentage = AmmMath.division(Constants.D18, 10);

        //@notice taken after open position from participant who execute opening position,
        //paid after close position to participant who execute closing position
        _liquidationDepositAmount = 20 * Constants.D18;

        //@notice
        _openingFeePercentage = AmmMath.division(
            3 * Constants.D18,
            Constants.D4
        );
        _openingFeeForTreasuryPercentage = 0;
        _iporPublicationFeeAmount = 10 * Constants.D18;
        _liquidityPoolMaxUtilizationPercentage =
            8 *
            AmmMath.division(Constants.D18, 10);

		_maxPositionTotalAmount = 1e5 * Constants.D18;

		_minCollateralizationFactorValue = 10 * Constants.D18;
		_maxCollateralizationFactorValue = 50 * Constants.D18;

		_spreadTemporaryValue = AmmMath.division(Constants.D18, 100);

		_wadDecayFactorValue = 1e17;

        _spreadDemandComponentKfValue = AmmMath.division(
            1 * Constants.D18,
            1000
        );
		_spreadDemandComponentLambdaValue = AmmMath.division(
            1 * Constants.D18,
            1000
        );
        _spreadDemandComponentKOmegaValue = AmmMath.division(3 * Constants.D18,
            10
        );

		_spreadDemandComponentMaxLiquidityRedemptionValue = Constants.D18;

		//TODO: clarify initial value
		_spreadAtParComponentKVolValue = AmmMath.division(
            3 * Constants.D18,
            100
        );

		//TODO: clarify initial value
		_spreadAtParComponentKHistValue = AmmMath.division(			
			3 * Constants.D18,
            100
        );

		_spreadMaxValue = AmmMath.division(
            3 * Constants.D18,
            10
        );

    }

    function getIncomeTaxPercentage() external view override returns (uint256) {
        return _incomeTaxPercentage;
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
        _incomeTaxPercentage = newIncomeTaxPercentage;
        emit IncomeTaxPercentageSet(newIncomeTaxPercentage);
    }

    function getOpeningFeeForTreasuryPercentage()
        external
        view
        override
        returns (uint256)
    {
        return _openingFeeForTreasuryPercentage;
    }

    function setOpeningFeeForTreasuryPercentage(
        uint256 newOpeningFeeForTreasuryPercentage
    ) external override onlyRole(OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE) {
        require(
            newOpeningFeeForTreasuryPercentage <= Constants.D18,
            Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        _openingFeeForTreasuryPercentage = newOpeningFeeForTreasuryPercentage;
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
        return _liquidationDepositAmount;
    }

    function setLiquidationDepositAmount(uint256 newLiquidationDepositAmount)
        external
        override
        onlyRole(LIQUIDATION_DEPOSIT_AMOUNT_ROLE)
    {
        _liquidationDepositAmount = newLiquidationDepositAmount;
        emit LiquidationDepositAmountSet(newLiquidationDepositAmount);
    }

    function getOpeningFeePercentage()
        external
        view
        override
        returns (uint256)
    {
        return _openingFeePercentage;
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
        _openingFeePercentage = newOpeningFeePercentage;
        emit OpeningFeePercentageSet(newOpeningFeePercentage);
    }

    function getIporPublicationFeeAmount()
        external
        view
        override
        returns (uint256)
    {
        return _iporPublicationFeeAmount;
    }

    function setIporPublicationFeeAmount(uint256 newIporPublicationFeeAmount)
        external
        override
        onlyRole(IPOR_PUBLICATION_FEE_AMOUNT_ROLE)
    {
        _iporPublicationFeeAmount = newIporPublicationFeeAmount;
        emit IporPublicationFeeAmountSet(newIporPublicationFeeAmount);
    }

    function getLiquidityPoolMaxUtilizationPercentage()
        external
        view
        override
        returns (uint256)
    {
        return _liquidityPoolMaxUtilizationPercentage;
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

        _liquidityPoolMaxUtilizationPercentage = newLiquidityPoolMaxUtilizationPercentage;
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
        return _maxPositionTotalAmount;
    }

    function setMaxPositionTotalAmount(uint256 newMaxPositionTotalAmount)
        external
        override
        onlyRole(MAX_POSITION_TOTAL_AMOUNT_ROLE)
    {
        _maxPositionTotalAmount = newMaxPositionTotalAmount;
        emit MaxPositionTotalAmountSet(newMaxPositionTotalAmount);
    }

    function getMaxCollateralizationFactorValue()
        external
        view
        override
        returns (uint256)
    {
        return _maxCollateralizationFactorValue;
    }

    function setMaxCollateralizationFactorValue(
        uint256 newMaxCollateralizationFactorValue
    ) external override onlyRole(COLLATERALIZATION_FACTOR_VALUE_ROLE) {
        _maxCollateralizationFactorValue = newMaxCollateralizationFactorValue;
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
        return _minCollateralizationFactorValue;
    }

    function setMinCollateralizationFactorValue(
        uint256 newMinCollateralizationFactorValue
    ) external override onlyRole(COLLATERALIZATION_FACTOR_VALUE_ROLE) {
        _minCollateralizationFactorValue = newMinCollateralizationFactorValue;
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
        return _charlieTreasurer;
    }

    function setCharlieTreasurer(address newCharlieTreasurer)
        external
        override
        onlyRole(CHARLIE_TREASURER_ROLE)
    {
        require(newCharlieTreasurer != address(0), Errors.WRONG_ADDRESS);
        _charlieTreasurer = newCharlieTreasurer;
        emit CharlieTreasurerUpdated(_asset, newCharlieTreasurer);
    }

    function getTreasureTreasurer() external view override returns (address) {
        return _treasureTreasurer;
    }

    function setTreasureTreasurer(address newTreasureTreasurer)
        external
        override
        onlyRole(TREASURE_TREASURER_ROLE)
    {
        require(newTreasureTreasurer != address(0), Errors.WRONG_ADDRESS);
        _treasureTreasurer = newTreasureTreasurer;
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
        return _assetManagementVault;
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
        _assetManagementVault = newAssetManagementVaultAddress;
        emit AssetManagementVaultUpdated(
            _asset,
            newAssetManagementVaultAddress
        );
    }

    function getDecayFactorValue() external view override returns (uint256) {
        return _wadDecayFactorValue;
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
        _wadDecayFactorValue = newWadDecayFactorValue;
        emit DecayFactorValueUpdated(_asset, newWadDecayFactorValue);
    }

    function getSpreadTemporaryValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadTemporaryValue;
    }

    function setSpreadTemporaryValue(uint256 newSpreadTemporaryVale)
        external
        override
    {
        _spreadTemporaryValue = newSpreadTemporaryVale;
    }

    function getSpreadDemandComponentKfValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadDemandComponentKfValue;
    }

    function setSpreadDemandComponentKfValue(
        uint256 newSpreadDemandComponentKfValue
    ) external override onlyRole(SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE) {
        _spreadDemandComponentKfValue = newSpreadDemandComponentKfValue;
        emit SpreadDemandComponentKfValueSet(
            newSpreadDemandComponentKfValue
        );
    }

	function getSpreadDemandComponentLambdaValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadDemandComponentLambdaValue;
    }

    function setSpreadDemandComponentLambdaValue(
        uint256 newSpreadDemandComponentLambdaValue
    )
        external
        override
        onlyRole(SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE)
    {
        _spreadDemandComponentLambdaValue = newSpreadDemandComponentLambdaValue;
        emit SpreadDemandComponentLambdaValueSet(
            newSpreadDemandComponentLambdaValue
        );
    }

    function getSpreadDemandComponentKOmegaValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadDemandComponentKOmegaValue;
    }

    function setSpreadDemandComponentKOmegaValue(
        uint256 newSpreadDemandComponentKOmegaValue
    )
        external
        override
        onlyRole(SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE)
    {
        _spreadDemandComponentKOmegaValue = newSpreadDemandComponentKOmegaValue;
        emit SpreadDemandComponentKOmegaValueSet(
            newSpreadDemandComponentKOmegaValue
        );
    }

	function getSpreadDemandComponentMaxLiquidityRedemptionValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadDemandComponentMaxLiquidityRedemptionValue;
    }

    function setSpreadDemandComponentMaxLiquidityRedemptionValue(
        uint256 newSpreadDemandComponentMaxLiquidityRedemptionValue
    )
        external
        override
        onlyRole(SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE)
    {
        _spreadDemandComponentMaxLiquidityRedemptionValue = newSpreadDemandComponentMaxLiquidityRedemptionValue;
        emit SpreadDemandComponentMaxLiquidityRedemptionValueSet(
            newSpreadDemandComponentMaxLiquidityRedemptionValue
        );
    }

	function getSpreadAtParComponentKVolValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadAtParComponentKVolValue;
    }

    function setSpreadAtParComponentKVolValue(
        uint256 newSpreadAtParComponentKVolValue
    )
        external
        override
        onlyRole(SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE)
    {
        _spreadAtParComponentKVolValue = newSpreadAtParComponentKVolValue;
        emit SpreadAtParComponentKVolValueSet(
            newSpreadAtParComponentKVolValue
        );
    }

	function getSpreadAtParComponentKHistValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadAtParComponentKHistValue;
    }

    function setSpreadAtParComponentKHistValue(
        uint256 newSpreadAtParComponentKHistValue
    )
        external
        override
        onlyRole(SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE)
    {
        _spreadAtParComponentKHistValue = newSpreadAtParComponentKHistValue;
        emit SpreadAtParComponentKHistValueSet(
            newSpreadAtParComponentKHistValue
        );
    }

	function getSpreadMaxValue()
        external
        view
        override
        returns (uint256)
    {
        return _spreadMaxValue;
    }

    function setSpreadMaxValue(
        uint256 newSpreadMaxValue
    )
        external
        override
        onlyRole(SPREAD_MAX_VALUE_ROLE)
    {
        _spreadMaxValue = newSpreadMaxValue;
        emit SpreadMaxValueSet(
            newSpreadMaxValue
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
