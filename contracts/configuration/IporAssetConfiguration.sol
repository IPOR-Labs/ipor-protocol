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

    uint256 private _openingFeePercentage;

	uint256 private _minCollateralizationFactorValue;

    uint256 private _maxCollateralizationFactorValue;

    uint256 private _incomeTaxPercentage;

    uint256 private _liquidationDepositAmount;    

    //@notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance, below value define how big
    //pie going to Treasury Balance
    uint256 private _openingFeeForTreasuryPercentage;

    uint256 private _iporPublicationFeeAmount;

    uint256 private _liquidityPoolMaxUtilizationPercentage;

	//TODO: change to "max collateral position value"
    //@notice max total amount used when opening position
    uint256 private _maxPositionTotalAmount;

    //@notice Decay factor, value between 0..1, indicator used in spread calculation
    uint256 private _wadDecayFactorValue;
    
	//TODO: rename DemandComponent to DC, AtParComponent to PC or DemandC, AtParC
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
		_maxCollateralizationFactorValue = 1000 * Constants.D18;

		_wadDecayFactorValue = 1e17;        

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
        onlyRole(_OPENING_FEE_PERCENTAGE_ROLE)
    {
        require(
            newOpeningFeePercentage <= Constants.D18,
            Errors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        _openingFeePercentage = newOpeningFeePercentage;
        emit OpeningFeePercentageSet(newOpeningFeePercentage);
    }
    function getIncomeTaxPercentage() external view override returns (uint256) {
        return _incomeTaxPercentage;
    }

    function setIncomeTaxPercentage(uint256 newIncomeTaxPercentage)
        external
        override
        onlyRole(_INCOME_TAX_PERCENTAGE_ROLE)
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
    ) external override onlyRole(_OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE) {
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
        onlyRole(_LIQUIDATION_DEPOSIT_AMOUNT_ROLE)
    {
        _liquidationDepositAmount = newLiquidationDepositAmount;
        emit LiquidationDepositAmountSet(newLiquidationDepositAmount);
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
        onlyRole(_IPOR_PUBLICATION_FEE_AMOUNT_ROLE)
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
        onlyRole(_LP_MAX_UTILIZATION_PERCENTAGE_ROLE)
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
        onlyRole(_MAX_POSITION_TOTAL_AMOUNT_ROLE)
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
    ) external override onlyRole(_COLLATERALIZATION_FACTOR_VALUE_ROLE) {
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
    ) external override onlyRole(_COLLATERALIZATION_FACTOR_VALUE_ROLE) {
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
        onlyRole(_CHARLIE_TREASURER_ROLE)
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
        onlyRole(_TREASURE_TREASURER_ROLE)
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
        onlyRole(_ASSET_MANAGEMENT_VAULT_ROLE)
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
        onlyRole(_DECAY_FACTOR_VALUE_ROLE)
    {
        require(
            newWadDecayFactorValue <= Constants.D18,
            Errors.CONFIG_DECAY_FACTOR_TOO_HIGH
        );
        _wadDecayFactorValue = newWadDecayFactorValue;
        emit DecayFactorValueUpdated(_asset, newWadDecayFactorValue);
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
