// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/IporSwapLogic.sol";
import "../libraries/IporMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IporErrors} from "../IporErrors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarren.sol";
import "../amm/MiltonStorage.sol";
import "../interfaces/IMiltonEvents.sol";
import "../libraries/SoapIndicatorLogic.sol";

import "../interfaces/IIporAssetConfiguration.sol";
import "./AccessControlAssetConfiguration.sol";

//TODO: combine with MiltonStorage to minimize external calls in modifiers and simplify code
contract IporAssetConfiguration is
    AccessControlAssetConfiguration(msg.sender),
    IIporAssetConfiguration
{
    uint8 private immutable _decimals;

    uint64 private immutable _maxSlippagePercentage;

    address private immutable _asset;

    address private immutable _ipToken;

    uint64 private _openingFeePercentage;

    uint64 private _incomeTaxPercentage;

    //@notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance, below value define how big
    //pie going to Treasury Balance
    uint64 private _openingFeeForTreasuryPercentage;

    uint64 private _liquidityPoolMaxUtilizationPercentage;

    uint128 private _minCollateralizationFactorValue;

    uint128 private _maxCollateralizationFactorValue;

    uint128 private _liquidationDepositAmount;

    uint128 private _iporPublicationFeeAmount;

    //@notice max total amount used when opening position
    uint128 private _maxSwapTotalAmount;

    //@notice Decay factor, value between 0..1, indicator used in spread calculation
    uint128 private _wadDecayFactorValue;

	uint128 private _redeemMaxUtilizationPercentage;

    address private _milton;

    address private _miltonStorage;

    address private _joseph;

    //TODO: rename DemandComponent to DC, AtParComponent to PC or DemandC, AtParC
    address private _assetManagementVault;

    address private _charlieTreasurer;

    //TODO: fix this name; treasureManager
    address private _treasureTreasurer;



    constructor(address asset, address ipToken) {
        _asset = asset;
        _ipToken = ipToken;
        uint8 decimals = ERC20(asset).decimals();
        require(decimals != 0, IporErrors.CONFIG_ASSET_DECIMALS_TOO_LOW);
        _decimals = decimals;

        _maxSlippagePercentage = uint64(100 * Constants.D18);

        //@notice taken after close position from participant who take income (trader or Milton)
        _incomeTaxPercentage = uint64(IporMath.division(Constants.D18, 10));

        //@notice taken after open position from participant who execute opening position,
        //paid after close position to participant who execute closing position
        _liquidationDepositAmount = uint128(20 * Constants.D18);

        //@notice
        _openingFeePercentage = uint64(
            IporMath.division(3 * Constants.D18, Constants.D4)
        );
        _openingFeeForTreasuryPercentage = 0;
        _iporPublicationFeeAmount = uint128(10 * Constants.D18);
        _liquidityPoolMaxUtilizationPercentage = uint64(
            8 * IporMath.division(Constants.D18, 10)
        );
		
		//@dev Redeem Max Utilization rate cannot be lower than Liquidity Pool Max Utilization rate
		_redeemMaxUtilizationPercentage = uint128(Constants.D18);

        _maxSwapTotalAmount = uint128(1e5 * Constants.D18);

        _minCollateralizationFactorValue = uint128(10 * Constants.D18);
        _maxCollateralizationFactorValue = uint128(1000 * Constants.D18);

        _wadDecayFactorValue = 1e17;
    }

    function getMilton() external view override returns (address) {
        return _milton;
    }

    function setMilton(address milton)
        external
        override
        onlyRole(_MILTON_ROLE)
    {
        //TODO: when Milton address is changing make sure than allowance on Josepth is set to 0 for old milton
        _milton = milton;
        emit MiltonAddressUpdated(milton);
    }

    function getMiltonStorage() external view override returns (address) {
        return _miltonStorage;
    }

    function setMiltonStorage(address miltonStorage)
        external
        override
        onlyRole(_MILTON_STORAGE_ROLE)
    {
        _miltonStorage = miltonStorage;
        emit MiltonStorageAddressUpdated(miltonStorage);
    }

    function getJoseph() external view override returns (address) {
        return _joseph;
    }

    function setJoseph(address joseph)
        external
        override
        onlyRole(_JOSEPH_ROLE)
    {
        _joseph = joseph;
        emit JosephAddressUpdated(joseph);
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
            IporErrors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        _openingFeePercentage = uint64(newOpeningFeePercentage);
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
            IporErrors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        _incomeTaxPercentage = uint64(newIncomeTaxPercentage);
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
            IporErrors.MILTON_CONFIG_MAX_VALUE_EXCEEDED
        );
        _openingFeeForTreasuryPercentage = uint64(
            newOpeningFeeForTreasuryPercentage
        );
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
        _liquidationDepositAmount = uint128(newLiquidationDepositAmount);
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
        _iporPublicationFeeAmount = uint128(newIporPublicationFeeAmount);
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
    ) external override onlyRole(_LP_MAX_UTILIZATION_PERCENTAGE_ROLE) {
        require(
            newLiquidityPoolMaxUtilizationPercentage <= Constants.D18,
            IporErrors.CONFIG_LP_MAX_UTILIZATION_PERCENTAGE_TOO_HIGH
        );

        _liquidityPoolMaxUtilizationPercentage = uint64(
            newLiquidityPoolMaxUtilizationPercentage
        );
        emit LiquidityPoolMaxUtilizationPercentageSet(
            newLiquidityPoolMaxUtilizationPercentage
        );
    }

	function getRedeemMaxUtilizationPercentage()
        external
        view
        override
        returns (uint256)
    {
        return _redeemMaxUtilizationPercentage;
    }

    function setRedeemMaxUtilizationPercentage(
        uint256 newRedeemMaxUtilizationPercentage
    ) external override onlyRole(_REDEEM_MAX_UTILIZATION_PERCENTAGE_ROLE) {
        require(
            newRedeemMaxUtilizationPercentage >= _liquidityPoolMaxUtilizationPercentage,
            IporErrors.CONFIG_REDEEM_MAX_UTILIZATION_LOWER_THAN_LP_MAX_UTILIZATION
        );

		require(
            newRedeemMaxUtilizationPercentage <= Constants.D18,
            IporErrors.CONFIG_REDEEM_MAX_UTILIZATION_PERCENTAGE_TOO_HIGH
        );

        _redeemMaxUtilizationPercentage = uint64(
            newRedeemMaxUtilizationPercentage
        );
        emit RedeemMaxUtilizationPercentageSet(
            newRedeemMaxUtilizationPercentage
        );
    }

    function getMaxSwapTotalAmount() external view override returns (uint256) {
        return _maxSwapTotalAmount;
    }

    function setMaxSwapTotalAmount(uint256 newMaxPositionTotalAmount)
        external
        override
        onlyRole(_MAX_POSITION_TOTAL_AMOUNT_ROLE)
    {
        _maxSwapTotalAmount = uint128(newMaxPositionTotalAmount);
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
        _maxCollateralizationFactorValue = uint128(
            newMaxCollateralizationFactorValue
        );
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
        _minCollateralizationFactorValue = uint128(
            newMinCollateralizationFactorValue
        );
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
        require(newCharlieTreasurer != address(0), IporErrors.WRONG_ADDRESS);
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
        require(newTreasureTreasurer != address(0), IporErrors.WRONG_ADDRESS);
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
            IporErrors.WRONG_ADDRESS
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
            IporErrors.CONFIG_DECAY_FACTOR_TOO_HIGH
        );
        _wadDecayFactorValue = uint128(newWadDecayFactorValue);
        emit DecayFactorValueUpdated(_asset, newWadDecayFactorValue);
    }
}
