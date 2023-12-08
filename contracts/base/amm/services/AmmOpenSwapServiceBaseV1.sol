// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/Address.sol";

import "../../../interfaces/IIporOracle.sol";
import "../../interfaces/IAmmTreasuryBaseV1.sol";
import "../../../libraries/Constants.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../amm/libraries/types/AmmInternalTypes.sol";
import "../../../base/spread/SpreadBaseV1.sol";
import "../libraries/SwapEventsBaseV1.sol";
import "../libraries/SwapLogicBaseV1.sol";
import "../../interfaces/ISpreadBaseV1.sol";
import "../../../base/interfaces/IAmmStorageBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
abstract contract AmmOpenSwapServiceBaseV1 {
    using Address for address;
    using IporContractValidator for address;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public immutable version = 1;

    address public immutable asset;
    uint256 public immutable decimals;

    address public immutable messageSigner;
    address public immutable iporOracle;
    address public immutable spread;
    address public immutable ammStorage;
    address public immutable ammTreasury;

    /// @dev IPOR publication fee in underlying token (asset), represented in 18 decimals
    uint256 public immutable iporPublicationFee;
    /// @dev Maximum collateral amount for swap, represented in 18 decimals
    uint256 public immutable maxSwapCollateralAmount;
    /// @dev Liquidation deposit amount for stETH represented in 6 decimals. Example 25 stETH = 25000000 = 25.000000
    uint256 public immutable liquidationDepositAmount;
    /// @dev Minimum leverage for swap, represented in 18 decimals
    uint256 public immutable minLeverage;
    /// @dev Opening fee rate, represented in 18 decimals
    uint256 public immutable openingFeeRate;
    /// @dev Opening fee treasury portion rate, represented in 18 decimals
    uint256 public immutable openingFeeTreasuryPortionRate;

    struct ContextStruct {
        /// @dev asset which user enters to open swap, can be different than underlying asset but have to be in 1:1 price relation with underlying asset
        address inputAsset;
        address beneficiary;
        /// @notice swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
        IporTypes.SwapTenor tenor;
    }

    constructor(
        AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput
    ) {
        asset = poolCfg.asset.checkAddress();
        decimals = poolCfg.decimals;

        spread = poolCfg.spread.checkAddress();
        ammStorage = poolCfg.ammStorage.checkAddress();
        ammTreasury = poolCfg.ammTreasury.checkAddress();

        iporPublicationFee = poolCfg.iporPublicationFee;
        maxSwapCollateralAmount = poolCfg.maxSwapCollateralAmount;
        liquidationDepositAmount = poolCfg.liquidationDepositAmount;
        minLeverage = poolCfg.minLeverage;
        openingFeeRate = poolCfg.openingFeeRate;
        openingFeeTreasuryPortionRate = poolCfg.openingFeeTreasuryPortionRate;

        iporOracle = iporOracleInput.checkAddress();
        messageSigner = messageSignerInput.checkAddress();
    }

    /// @dev Notice! assetInput is in price relation 1:1 to underlying asset
    function _openSwapPayFixed(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        IporTypes.SwapTenor tenor,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        _validateInputAsset(inputAsset, inputAssetTotalAmount);
        return
            _openSwapPayFixedInternal(
                ContextStruct({inputAsset: inputAsset, beneficiary: beneficiary, tenor: tenor}),
                inputAssetTotalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    asset,
                    uint256(tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                    messageSigner
                )
            );
    }

    /// @dev Notice! assetInput is in price relation 1:1 to underlying asset
    function _openSwapReceiveFixed(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        IporTypes.SwapTenor tenor,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        _validateInputAsset(inputAsset, inputAssetTotalAmount);
        return
            _openSwapReceiveFixedInternal(
                ContextStruct({inputAsset: inputAsset, beneficiary: beneficiary, tenor: tenor}),
                inputAssetTotalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    asset,
                    uint256(tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                    messageSigner
                )
            );
    }

    function _openSwapPayFixedInternal(
        ContextStruct memory ctx,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.OpenSwapRiskIndicators memory riskIndicators
    ) internal returns (uint256) {
        AmmTypesBaseV1.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            ctx,
            block.timestamp,
            inputAssetTotalAmount,
            leverage
        );

        AmmTypesBaseV1.AmmBalanceForOpenSwap memory balance = IAmmStorageBaseV1(ammStorage).getBalancesForOpenSwap();

        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasury).getLiquidityPoolBalance() +
            bosStruct.openingFeeLPAmount;

        balance.totalCollateralPayFixed = balance.totalCollateralPayFixed + bosStruct.collateral;

        _validateLiquidityPoolCollateralRatioAndSwapLeverage(
            liquidityPoolBalance,
            balance.totalCollateralPayFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
            leverage,
            riskIndicators.maxLeveragePerLeg,
            riskIndicators.maxCollateralRatio,
            riskIndicators.maxCollateralRatioPerLeg
        );

        uint256 offeredRateValue = ISpreadBaseV1(spread).calculateAndUpdateOfferedRatePayFixed(
            ISpreadBaseV1.SpreadInputs({
                asset: asset,
                swapNotional: bosStruct.notional,
                demandSpreadFactor: riskIndicators.demandSpreadFactor,
                baseSpreadPerLeg: riskIndicators.baseSpreadPerLeg,
                totalCollateralPayFixed: balance.totalCollateralPayFixed,
                totalCollateralReceiveFixed: balance.totalCollateralReceiveFixed,
                liquidityPoolBalance: liquidityPoolBalance,
                iporIndexValue: bosStruct.accruedIpor.indexValue,
                fixedRateCapPerLeg: riskIndicators.fixedRateCapPerLeg,
                tenor: ctx.tenor
            })
        );

        require(
            acceptableFixedInterestRate > 0 && offeredRateValue <= acceptableFixedInterestRate,
            AmmErrors.ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED
        );

        AmmTypes.IporSwapIndicator memory indicator = AmmTypes.IporSwapIndicator(
            bosStruct.accruedIpor.indexValue,
            bosStruct.accruedIpor.ibtPrice,
            IporMath.division(bosStruct.notional * 1e18, bosStruct.accruedIpor.ibtPrice),
            offeredRateValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            ctx.beneficiary,
            block.timestamp,
            bosStruct.collateral,
            bosStruct.notional,
            indicator.ibtQuantity,
            indicator.fixedInterestRate,
            bosStruct.liquidationDepositAmount,
            bosStruct.openingFeeLPAmount,
            bosStruct.openingFeeTreasuryAmount,
            ctx.tenor
        );

        uint256 newSwapId = IAmmStorageBaseV1(ammStorage).updateStorageWhenOpenSwapPayFixedInternal(
            newSwap,
            iporPublicationFee
        );

        _transferTotalAmountToAmmTreasury(ctx.inputAsset, bosStruct.inputAssetTotalAmount, bosStruct.assetTotalAmount);

        _emitOpenSwapEvent(
            ctx.inputAsset,
            bosStruct.wadInputAssetTotalAmount,
            newSwapId,
            bosStruct.wadAssetTotalAmount,
            newSwap,
            indicator,
            0,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    function _openSwapReceiveFixedInternal(
        ContextStruct memory ctx,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.OpenSwapRiskIndicators memory riskIndicators
    ) internal returns (uint256) {
        AmmTypesBaseV1.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            ctx,
            block.timestamp,
            totalAmount,
            leverage
        );

        AmmTypesBaseV1.AmmBalanceForOpenSwap memory balance = IAmmStorageBaseV1(ammStorage).getBalancesForOpenSwap();

        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasury).getLiquidityPoolBalance() +
            bosStruct.openingFeeLPAmount;

        balance.totalCollateralReceiveFixed = balance.totalCollateralReceiveFixed + bosStruct.collateral;

        _validateLiquidityPoolCollateralRatioAndSwapLeverage(
            liquidityPoolBalance,
            balance.totalCollateralReceiveFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
            leverage,
            riskIndicators.maxLeveragePerLeg,
            riskIndicators.maxCollateralRatio,
            riskIndicators.maxCollateralRatioPerLeg
        );

        uint256 offeredRateValue = ISpreadBaseV1(spread).calculateAndUpdateOfferedRateReceiveFixed(
            ISpreadBaseV1.SpreadInputs({
                asset: asset,
                swapNotional: bosStruct.notional,
                demandSpreadFactor: riskIndicators.demandSpreadFactor,
                baseSpreadPerLeg: riskIndicators.baseSpreadPerLeg,
                totalCollateralPayFixed: balance.totalCollateralPayFixed,
                totalCollateralReceiveFixed: balance.totalCollateralReceiveFixed,
                liquidityPoolBalance: liquidityPoolBalance,
                iporIndexValue: bosStruct.accruedIpor.indexValue,
                fixedRateCapPerLeg: riskIndicators.fixedRateCapPerLeg,
                tenor: ctx.tenor
            })
        );

        require(acceptableFixedInterestRate <= offeredRateValue, AmmErrors.ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED);

        AmmTypes.IporSwapIndicator memory indicator = AmmTypes.IporSwapIndicator(
            bosStruct.accruedIpor.indexValue,
            bosStruct.accruedIpor.ibtPrice,
            IporMath.division(bosStruct.notional * 1e18, bosStruct.accruedIpor.ibtPrice),
            offeredRateValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            ctx.beneficiary,
            block.timestamp,
            bosStruct.collateral,
            bosStruct.notional,
            indicator.ibtQuantity,
            indicator.fixedInterestRate,
            bosStruct.liquidationDepositAmount,
            bosStruct.openingFeeLPAmount,
            bosStruct.openingFeeTreasuryAmount,
            ctx.tenor
        );

        uint256 newSwapId = IAmmStorageBaseV1(ammStorage).updateStorageWhenOpenSwapReceiveFixedInternal(
            newSwap,
            iporPublicationFee
        );

        _transferTotalAmountToAmmTreasury(ctx.inputAsset, bosStruct.inputAssetTotalAmount, bosStruct.assetTotalAmount);

        _emitOpenSwapEvent(
            ctx.inputAsset,
            bosStruct.wadInputAssetTotalAmount,
            newSwapId,
            bosStruct.wadAssetTotalAmount,
            newSwap,
            indicator,
            1,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    /// @notice Transfer asset input to AMM Treasury in underlying token (asset) after opening swap
    /// @param inputAsset Address of the asset input the asset which user enters to open swap, can be different than underlying asset but have to be in 1:1 price relation with underlying asset
    /// @param assetTotalAmount Total amount of underlying asset.
    function _transferTotalAmountToAmmTreasury(
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 assetTotalAmount
    ) internal virtual;

    //    function _validateTotalAmount(address inputAsset, uint256 totalAmount) internal view virtual;

    function _validateInputAsset(address inputAsset, uint256 inputAssetTotalAmount) internal view virtual;

    /// @notice Converts input asset amount to underlying asset amount using exchange rate between input asset and underlying asset.
    /// @param inputAsset Address of the asset input the asset which user enters to open swap, can be different than underlying asset.
    /// @param inputAssetAmount Amount of input asset.
    /// @return asset amount represented in underlying asset in decimals of underlying asset
    /// @dev Notice! Returned value is represented in decimals of underlying asset which in general can could be different than 18 decimals.
    function _convertToAssetAmount(
        address inputAsset,
        uint256 inputAssetAmount
    ) internal view virtual returns (uint256);

    /// @notice Converts input asset amount to amount represented in 18 decimals.
    /// @param inputAsset Address of the asset input the asset which user enters to open swap, can be different than underlying asset.
    /// @param inputAssetAmount Amount of input asset.
    /// @return input asset amount represented in 18 decimals
    function _convertInputAssetAmountToWadAmount(
        address inputAsset,
        uint256 inputAssetAmount
    ) internal view virtual returns (uint256);

    function _beforeOpenSwap(
        ContextStruct memory ctx,
        uint256 openTimestamp,
        uint256 inputAssetTotalAmount,
        uint256 leverage
    ) internal view returns (AmmTypesBaseV1.BeforeOpenSwapStruct memory bosStruct) {
        require(ctx.beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 assetTotalAmount = _convertToAssetAmount(ctx.inputAsset, inputAssetTotalAmount);

        uint256 wadAssetTotalAmount = IporMath.convertToWad(assetTotalAmount, decimals);

        /// @dev to achieve 18 decimals precision we multiply by 1e12 because for stETH
        /// pool liquidationDepositAmount is represented in 6 decimals in storage and in Service configuration.
        uint256 wadLiquidationDepositAmount = liquidationDepositAmount * 1e12;

        (uint256 collateral, uint256 notional, uint256 openingFeeAmount) = SwapLogicBaseV1.calculateSwapAmount(
            ctx.tenor,
            wadAssetTotalAmount,
            leverage,
            wadLiquidationDepositAmount,
            iporPublicationFee,
            openingFeeRate
        );

        (uint256 openingFeeLPAmount, uint256 openingFeeTreasuryAmount) = SwapLogicBaseV1.splitOpeningFeeAmount(
            openingFeeAmount,
            openingFeeTreasuryPortionRate
        );

        require(collateral <= maxSwapCollateralAmount, AmmErrors.COLLATERAL_AMOUNT_TOO_HIGH);

        require(
            wadAssetTotalAmount > wadLiquidationDepositAmount + iporPublicationFee + openingFeeAmount,
            AmmErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        return
            AmmTypesBaseV1.BeforeOpenSwapStruct({
                inputAssetTotalAmount: inputAssetTotalAmount,
                wadInputAssetTotalAmount: _convertInputAssetAmountToWadAmount(ctx.inputAsset, inputAssetTotalAmount),
                assetTotalAmount: assetTotalAmount,
                wadAssetTotalAmount: wadAssetTotalAmount,
                collateral: collateral,
                notional: notional,
                openingFeeLPAmount: openingFeeLPAmount,
                openingFeeTreasuryAmount: openingFeeTreasuryAmount,
                iporPublicationFeeAmount: iporPublicationFee,
                liquidationDepositAmount: liquidationDepositAmount,
                accruedIpor: IIporOracle(iporOracle).getAccruedIndex(openTimestamp, asset)
            });
    }

    function _emitOpenSwapEvent(
        address inputAsset,
        uint256 wadInputAssetTotalAmount,
        uint256 newSwapId,
        uint256 wadAssetTotalAmount,
        AmmTypes.NewSwap memory newSwap,
        AmmTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 iporPublicationFeeAmount
    ) internal {
        emit SwapEventsBaseV1.OpenSwap(
            newSwapId,
            newSwap.buyer,
            inputAsset,
            asset,
            AmmTypes.SwapDirection(direction),
            AmmTypesBaseV1.OpenSwapAmount({
                inputAssetTotalAmount: wadInputAssetTotalAmount,
                assetTotalAmount: wadAssetTotalAmount,
                collateral: newSwap.collateral,
                notional: newSwap.notional,
                openingFeeLPAmount: newSwap.openingFeeLPAmount,
                openingFeeTreasuryAmount: newSwap.openingFeeTreasuryAmount,
                iporPublicationFee: iporPublicationFeeAmount,
                /// @dev to achieve 18 decimals precision we multiply by 1e12 because for stETH pool liquidationDepositAmount is represented in 6 decimals in storage.
                liquidationDepositAmount: newSwap.liquidationDepositAmount * 1e12
            }),
            newSwap.openTimestamp,
            newSwap.openTimestamp + SwapLogicBaseV1.getTenorInSeconds(newSwap.tenor),
            indicator
        );
    }

    function _validateLiquidityPoolCollateralRatioAndSwapLeverage(
        uint256 totalLiquidityPoolBalance,
        uint256 collateralPerLegBalance,
        uint256 totalCollateralBalance,
        uint256 leverage,
        uint256 maxLeverage,
        uint256 maxCollateralRatio,
        uint256 maxCollateralRatioPerLeg
    ) internal view {
        uint256 collateralRatio;
        uint256 collateralRatioPerLeg;

        if (totalLiquidityPoolBalance > 0) {
            collateralRatio = IporMath.division(totalCollateralBalance * 1e18, totalLiquidityPoolBalance);
            collateralRatioPerLeg = IporMath.division(collateralPerLegBalance * 1e18, totalLiquidityPoolBalance);
        } else {
            collateralRatio = Constants.MAX_VALUE;
            collateralRatioPerLeg = Constants.MAX_VALUE;
        }

        require(collateralRatio <= maxCollateralRatio, AmmErrors.LP_COLLATERAL_RATIO_EXCEEDED);
        require(collateralRatioPerLeg <= maxCollateralRatioPerLeg, AmmErrors.LP_COLLATERAL_RATIO_PER_LEG_EXCEEDED);
        require(leverage >= minLeverage, AmmErrors.LEVERAGE_TOO_LOW);
        require(leverage <= maxLeverage, AmmErrors.LEVERAGE_TOO_HIGH);
    }
}
