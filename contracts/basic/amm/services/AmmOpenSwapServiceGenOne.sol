// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/Address.sol";

import "../../../interfaces/IIporOracle.sol";
import "../../interfaces/IAmmTreasuryGenOne.sol";
import "../../../libraries/Constants.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../amm/libraries/types/AmmInternalTypes.sol";
import "../../../amm/libraries/IporSwapLogic.sol";
import "../../../basic/spread/SpreadGenOne.sol";
import "../libraries/SwapEventsGenOne.sol";
import "../libraries/SwapLogicGenOne.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
abstract contract AmmOpenSwapServiceGenOne {
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

    struct Context {
        /// @dev asset which user enters to open swap, can be different than underlying asset but have to be in 1:1 price relation with underlying asset
        address accountInputToken;
        address beneficiary;
        /// @notice swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
        IporTypes.SwapTenor tenor;
    }

    constructor(
        AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput,
        address spreadInput
    ) {
        asset = poolCfg.asset.checkAddress();
        decimals = poolCfg.decimals;

        spread = spreadInput.checkAddress();
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
        address accountInputToken,
        address beneficiary,
        IporTypes.SwapTenor tenor,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        _validateAccountInputToken(accountInputToken);
        return
            _openSwapPayFixedInternal(
                Context({accountInputToken: accountInputToken, beneficiary: beneficiary, tenor: tenor}),
                totalAmount,
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
        address accountInputToken,
        address beneficiary,
        IporTypes.SwapTenor tenor,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        _validateAccountInputToken(accountInputToken);
        return
            _openSwapReceiveFixedInternal(
                Context({accountInputToken: accountInputToken, beneficiary: beneficiary, tenor: tenor}),
                totalAmount,
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
        Context memory ctx,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.OpenSwapRiskIndicators memory riskIndicators
    ) internal returns (uint256) {
        AmmInternalTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            ctx,
            block.timestamp,
            totalAmount,
            leverage
        );

        AmmTypesGenOne.AmmBalanceForOpenSwap memory balance = IAmmStorageGenOne(ammStorage).getBalancesForOpenSwap();

        uint256 liquidityPoolBalance = IAmmTreasuryGenOne(ammTreasury).getLiquidityPoolBalance() +
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

        uint256 offeredRateValue = SpreadGenOne(spread).calculateAndUpdateOfferedRatePayFixed(
            SpreadGenOne.SpreadInputs({
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

        uint256 newSwapId = IAmmStorageGenOne(ammStorage).updateStorageWhenOpenSwapPayFixedInternal(
            newSwap,
            iporPublicationFee
        );

        uint256 accountInputTokenAmount = _transferAssetInputToAmmTreasury(ctx.accountInputToken, totalAmount);

        _emitOpenSwapEvent(
            ctx.accountInputToken,
            accountInputTokenAmount,
            newSwapId,
            bosStruct.wadTotalAmount,
            newSwap,
            indicator,
            0,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    function _openSwapReceiveFixedInternal(
        Context memory ctx,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.OpenSwapRiskIndicators memory riskIndicators
    ) internal returns (uint256) {
        AmmInternalTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            ctx,
            block.timestamp,
            totalAmount,
            leverage
        );

        AmmTypesGenOne.AmmBalanceForOpenSwap memory balance = IAmmStorageGenOne(ammStorage).getBalancesForOpenSwap();

        uint256 liquidityPoolBalance = IAmmTreasuryGenOne(ammTreasury).getLiquidityPoolBalance() +
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

        uint256 offeredRateValue = SpreadGenOne(spread).calculateAndUpdateOfferedRateReceiveFixed(
            SpreadGenOne.SpreadInputs({
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

        uint256 newSwapId = IAmmStorageGenOne(ammStorage).updateStorageWhenOpenSwapReceiveFixedInternal(
            newSwap,
            iporPublicationFee
        );

        uint256 accountInputTokenAmount = _transferAssetInputToAmmTreasury(ctx.accountInputToken, totalAmount);

        _emitOpenSwapEvent(
            ctx.accountInputToken,
            accountInputTokenAmount,
            newSwapId,
            bosStruct.wadTotalAmount,
            newSwap,
            indicator,
            1,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    /// @notice Transfer asset input to AMM Treasury in underlying token (asset) after opening swap
    /// @param accountInputToken Address of the asset input the asset which user enters to open swap, can be different than underlying asset but have to be in 1:1 price relation with underlying asset
    /// @param totalAmount Total amount of asset input
    /// @return accountInputTokenAmount Amount of asset input transferred to AMM Treasury
    function _transferAssetInputToAmmTreasury(
        address accountInputToken,
        uint256 totalAmount
    ) internal virtual returns (uint256 accountInputTokenAmount);

    function _validateTotalAmount(address accountInputToken, uint256 totalAmount) internal view virtual;

    function _validateAccountInputToken(address accountInputToken) internal view virtual;

    function _beforeOpenSwap(
        Context memory ctx,
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 leverage
    ) internal view returns (AmmInternalTypes.BeforeOpenSwapStruct memory bosStruct) {
        require(ctx.beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        _validateTotalAmount(ctx.accountInputToken, totalAmount);

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, decimals);
        /// @dev to achieve 18 decimals precision we multiply by 1e12 because for stETH
        /// pool liquidationDepositAmount is represented in 6 decimals in storage and in Service configuration.
        uint256 wadLiquidationDepositAmount = liquidationDepositAmount * 1e12;

        (uint256 collateral, uint256 notional, uint256 openingFeeAmount) = SwapLogicGenOne.calculateSwapAmount(
            ctx.tenor,
            wadTotalAmount,
            leverage,
            wadLiquidationDepositAmount,
            iporPublicationFee,
            openingFeeRate
        );

        (uint256 openingFeeLPAmount, uint256 openingFeeTreasuryAmount) = IporSwapLogic.splitOpeningFeeAmount(
            openingFeeAmount,
            openingFeeTreasuryPortionRate
        );

        require(collateral <= maxSwapCollateralAmount, AmmErrors.COLLATERAL_AMOUNT_TOO_HIGH);

        require(
            wadTotalAmount > wadLiquidationDepositAmount + iporPublicationFee + openingFeeAmount,
            AmmErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        IporTypes.AccruedIpor memory accruedIndex = IIporOracle(iporOracle).getAccruedIndex(openTimestamp, asset);

        return
            AmmInternalTypes.BeforeOpenSwapStruct(
                wadTotalAmount,
                collateral,
                notional,
                openingFeeLPAmount,
                openingFeeTreasuryAmount,
                iporPublicationFee,
                liquidationDepositAmount,
                accruedIndex
            );
    }

    function _emitOpenSwapEvent(
        address accountInputToken,
        uint256 accountInputTokenAmount,
        uint256 newSwapId,
        uint256 wadTotalAmount,
        AmmTypes.NewSwap memory newSwap,
        AmmTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 iporPublicationFeeAmount
    ) internal {
        emit SwapEventsGenOne.OpenSwap(
            newSwapId,
            newSwap.buyer,
            accountInputToken,
            asset,
            AmmTypes.SwapDirection(direction),
            AmmTypesGenOne.OpenSwapAmount({
                accountInputTokenAmount: accountInputTokenAmount,
                totalAmount: wadTotalAmount,
                collateral: newSwap.collateral,
                notional: newSwap.notional,
                openingFeeLPAmount: newSwap.openingFeeLPAmount,
                openingFeeTreasuryAmount: newSwap.openingFeeTreasuryAmount,
                iporPublicationFee: iporPublicationFeeAmount,
                /// @dev to achieve 18 decimals precision we multiply by 1e12 because for stETH pool liquidationDepositAmount is represented in 6 decimals in storage.
                liquidationDepositAmount: newSwap.liquidationDepositAmount * 1e12
            }),
            newSwap.openTimestamp,
            newSwap.openTimestamp + IporSwapLogic.getTenorInSeconds(newSwap.tenor),
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
