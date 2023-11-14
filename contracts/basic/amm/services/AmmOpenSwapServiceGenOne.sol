// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../interfaces/IIporOracle.sol";
import "../../../interfaces/IAmmStorage.sol";
import "../../../interfaces/IAmmOpenSwapService.sol";
import "../../../amm/spread/ISpread28Days.sol";
import "../../../amm/spread/ISpread60Days.sol";
import "../../../amm/spread/ISpread90Days.sol";
import "../../../libraries/Constants.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/SwapEvents.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/RiskManagementLogic.sol";
import "../../../amm/libraries/types/AmmInternalTypes.sol";
import "../../../amm/libraries/IporSwapLogic.sol";
import "../libraries/SwapLogicGenOne.sol";
import "../../../basic/spread/SpreadGenOne.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
abstract contract AmmOpenSwapServiceGenOne {
    using Address for address;
    using IporContractValidator for address;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    uint256 public immutable version = 1;

    address public immutable asset;
    uint256 public immutable decimals;

    address public immutable messageSigner;
    address public immutable iporOracle;

    address public immutable spread;
    address public immutable ammStorage;
    address public immutable ammTreasury;

    uint256 public immutable iporPublicationFee;
    uint256 public immutable maxSwapCollateralAmount;
    uint256 public immutable wadLiquidationDepositAmount;
    uint256 public immutable minLeverage;
    uint256 public immutable openingFeeRate;
    uint256 public immutable openingFeeTreasuryPortionRate;

    struct Context {
        /// @dev asset which user enters to open swap, can be different than underlying asset but have to be in 1:1 price relation with underlying asset
        address assetInput;
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
        wadLiquidationDepositAmount = poolCfg.wadLiquidationDepositAmount;
        minLeverage = poolCfg.minLeverage;
        openingFeeRate = poolCfg.openingFeeRate;
        openingFeeTreasuryPortionRate = poolCfg.openingFeeTreasuryPortionRate;

        iporOracle = iporOracleInput.checkAddress();
        messageSigner = messageSignerInput.checkAddress();
    }

    /// @dev Notice! assetInput is in price relation 1:1 to underlying asset
    function _openSwapPayFixed28days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            assetInput: assetInput,
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_28
        });
        return
            _openSwapPayFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                    messageSigner
                )
            );
    }

    /// @dev Notice! assetInput is in price relation 1:1 to underlying asset
    function _openSwapPayFixed60days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            assetInput: assetInput,
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_60
        });
        return
            _openSwapPayFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                    messageSigner
                )
            );
    }

    /// @dev Notice! assetInput is in price relation 1:1 to underlying asset
    function _openSwapPayFixed90days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            assetInput: assetInput,
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_90
        });
        return
            _openSwapPayFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                    messageSigner
                )
            );
    }

    /// @dev Notice! assetInput is in price relation 1:1 to underlying asset
    function _openSwapReceiveFixed28days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            assetInput: assetInput,
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_28
        });

        return
            _openSwapReceiveFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                    messageSigner
                )
            );
    }

    /// @dev Notice! assetInput is in price relation 1:1 to underlying asset
    function _openSwapReceiveFixed60days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            assetInput: assetInput,
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_60
        });
        return
            _openSwapReceiveFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                    messageSigner
                )
            );
    }

    /// @dev Notice! assetInput is in price relation 1:1 to underlying asset
    function _openSwapReceiveFixed90days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            assetInput: assetInput,
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_90
        });
        return
            _openSwapReceiveFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                    messageSigner
                )
            );
    }

    function _openSwapPayFixed(
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

        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IAmmStorage(ammStorage).getBalancesForOpenSwap();
        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralPayFixed = balance.totalCollateralPayFixed + bosStruct.collateral;

        _validateLiquidityPoolCollateralRatioAndSwapLeverage(
            balance.liquidityPool,
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
                liquidityPoolBalance: balance.liquidityPool,
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

        uint256 newSwapId = IAmmStorage(ammStorage).updateStorageWhenOpenSwapPayFixedInternal(
            newSwap,
            iporPublicationFee
        );

        _transferAssetInputToAmmTreasury(ctx.assetInput, totalAmount);

        _emitOpenSwapEvent(
            ctx.assetInput,
            newSwapId,
            bosStruct.wadTotalAmount,
            newSwap,
            indicator,
            0,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    function _openSwapReceiveFixed(
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

        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IAmmStorage(ammStorage).getBalancesForOpenSwap();

        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralReceiveFixed = balance.totalCollateralReceiveFixed + bosStruct.collateral;

        _validateLiquidityPoolCollateralRatioAndSwapLeverage(
            balance.liquidityPool,
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
                liquidityPoolBalance: balance.liquidityPool,
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

        uint256 newSwapId = IAmmStorage(ammStorage).updateStorageWhenOpenSwapReceiveFixedInternal(
            newSwap,
            iporPublicationFee
        );

        _transferAssetInputToAmmTreasury(ctx.assetInput, totalAmount);

        _emitOpenSwapEvent(
            ctx.assetInput,
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
    /// @param assetInput Address of the asset input the asset which user enters to open swap, can be different than underlying asset but have to be in 1:1 price relation with underlying asset
    /// @param totalAmount Total amount of asset input
    function _transferAssetInputToAmmTreasury(address assetInput, uint256 totalAmount) internal virtual;

    function _beforeOpenSwap(
        Context memory ctx,
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 leverage
    ) internal view returns (AmmInternalTypes.BeforeOpenSwapStruct memory bosStruct) {
        require(ctx.beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        require(totalAmount > 0, AmmErrors.TOTAL_AMOUNT_TOO_LOW);

        if (ctx.assetInput == address(0)) {
            require(msg.value >= totalAmount, IporErrors.SENDER_ASSET_BALANCE_TOO_LOW);
        } else {
            require(
                IERC20Upgradeable(ctx.assetInput).balanceOf(msg.sender) >= totalAmount,
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW
            );
        }

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, decimals);

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
                wadLiquidationDepositAmount,
                accruedIndex
            );
    }

    function _emitOpenSwapEvent(
        address inputAsset,
        uint256 newSwapId,
        uint256 wadTotalAmount,
        AmmTypes.NewSwap memory newSwap,
        AmmTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 iporPublicationFeeAmount
    ) internal {
        emit SwapEvents.OpenSwap(
            newSwapId,
            newSwap.buyer,
            inputAsset,
            asset,
            AmmTypes.SwapDirection(direction),
            AmmTypes.OpenSwapAmount(
                wadTotalAmount,
                newSwap.collateral,
                newSwap.notional,
                newSwap.openingFeeLPAmount,
                newSwap.openingFeeTreasuryAmount,
                iporPublicationFeeAmount,
                newSwap.liquidationDepositAmount * 1e18
            ),
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
