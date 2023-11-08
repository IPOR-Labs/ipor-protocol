// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../interfaces/IIporOracle.sol";
import "../../../interfaces/IAmmStorage.sol";
import "../../../interfaces/IAmmOpenSwapService.sol";
import "../../../interfaces/IAmmOpenSwapServiceStEth.sol";
import "../../../interfaces/IAmmOpenSwapLensStEth.sol";
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
import "../libraries/SwapLogicGenOne.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
abstract contract AmmOpenSwapServiceGenOne {
    using Address for address;
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    address internal immutable _asset;
    uint256 internal immutable _decimals;
    address internal immutable _ammStorage;
    address internal immutable _ammTreasury;
    uint256 internal immutable _iporPublicationFee;
    uint256 internal immutable _maxSwapCollateralAmount;
    uint256 internal immutable _liquidationDepositAmount;
    uint256 internal immutable _minLeverage;
    uint256 internal immutable _openingFeeRate;
    uint256 internal immutable _openingFeeTreasuryPortionRate;

    address public immutable iporOracle;
    address public immutable messageSigner;
    address public immutable spreadRouter;

    struct Context {
        address beneficiary;
        /// @notice swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
        IporTypes.SwapTenor tenor;
        bytes4 spreadMethodSig;
        AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration poolCfg;
    }

    constructor(
        AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput,
        address spreadRouterInput
    ) {
        _asset = poolCfg.asset.checkAddress();
        _decimals = poolCfg.decimals;
        _ammStorage = poolCfg.ammStorage.checkAddress();
        _ammTreasury = poolCfg.ammTreasury.checkAddress();
        _iporPublicationFee = poolCfg.iporPublicationFee;
        _maxSwapCollateralAmount = poolCfg.maxSwapCollateralAmount;
        _liquidationDepositAmount = poolCfg.liquidationDepositAmount;
        _minLeverage = poolCfg.minLeverage;
        _openingFeeRate = poolCfg.openingFeeRate;
        _openingFeeTreasuryPortionRate = poolCfg.openingFeeTreasuryPortionRate;

        iporOracle = iporOracleInput.checkAddress();
        messageSigner = messageSignerInput.checkAddress();
        spreadRouter = spreadRouterInput.checkAddress();
    }

    function _openSwapPayFixed28days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_28,
            spreadMethodSig: ISpread28Days.calculateAndUpdateOfferedRatePayFixed28Days.selector,
            poolCfg: _getPoolConfiguration()
        });
        return
            _openSwapPayFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    _asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                    messageSigner
                )
            );
    }

    function _openSwapPayFixed60days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_60,
            spreadMethodSig: ISpread60Days.calculateAndUpdateOfferedRatePayFixed60Days.selector,
            poolCfg: _getPoolConfiguration()
        });
        return
            _openSwapPayFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    _asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                    messageSigner
                )
            );
    }

    function _openSwapPayFixed90days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_90,
            spreadMethodSig: ISpread90Days.calculateAndUpdateOfferedRatePayFixed90Days.selector,
            poolCfg: _getPoolConfiguration()
        });
        return
            _openSwapPayFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    _asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                    messageSigner
                )
            );
    }

    function _openSwapReceiveFixed28days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_28,
            spreadMethodSig: ISpread28Days.calculateAndUpdateOfferedRateReceiveFixed28Days.selector,
            poolCfg: _getPoolConfiguration()
        });

        return
            _openSwapReceiveFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    _asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                    messageSigner
                )
            );
    }

    function _openSwapReceiveFixed60days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_60,
            spreadMethodSig: ISpread60Days.calculateAndUpdateOfferedRateReceiveFixed60Days.selector,
            poolCfg: _getPoolConfiguration()
        });
        return
            _openSwapReceiveFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    _asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                    messageSigner
                )
            );
    }

    function _openSwapReceiveFixed90days(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) internal returns (uint256) {
        Context memory context = Context({
            beneficiary: beneficiary,
            tenor: IporTypes.SwapTenor.DAYS_90,
            spreadMethodSig: ISpread90Days.calculateAndUpdateOfferedRateReceiveFixed90Days.selector,
            poolCfg: _getPoolConfiguration()
        });
        return
            _openSwapReceiveFixed(
                context,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs.verify(
                    _asset,
                    uint256(context.tenor),
                    uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                    messageSigner
                )
            );
    }

    function _getPoolConfiguration() internal view returns (AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory) {
        return
            AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration({
                asset: _asset,
                decimals: _decimals,
                ammStorage: _ammStorage,
                ammTreasury: _ammTreasury,
                iporPublicationFee: _iporPublicationFee,
                maxSwapCollateralAmount: _maxSwapCollateralAmount,
                liquidationDepositAmount: _liquidationDepositAmount,
                minLeverage: _minLeverage,
                openingFeeRate: _openingFeeRate,
                openingFeeTreasuryPortionRate: _openingFeeTreasuryPortionRate
            });
    }

    function _openSwapPayFixed(
        Context memory ctx,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.OpenSwapRiskIndicators memory riskIndicators
    ) internal returns (uint256) {
        AmmInternalTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            ctx.beneficiary,
            block.timestamp,
            totalAmount,
            leverage,
            ctx.tenor,
            ctx.poolCfg
        );

        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IAmmStorage(ctx.poolCfg.ammStorage)
            .getBalancesForOpenSwap();
        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralPayFixed = balance.totalCollateralPayFixed + bosStruct.collateral;

        _validateLiquidityPoolCollateralRatioAndSwapLeverage(
            balance.liquidityPool,
            balance.totalCollateralPayFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
            leverage,
            riskIndicators.maxLeveragePerLeg,
            riskIndicators.maxCollateralRatio,
            riskIndicators.maxCollateralRatioPerLeg,
            ctx.poolCfg.minLeverage
        );

        uint256 offeredRateValue = abi.decode(
            spreadRouter.functionCall(
                abi.encodeWithSelector(
                    ctx.spreadMethodSig,
                    ctx.poolCfg.asset,
                    bosStruct.notional,
                    riskIndicators.demandSpreadFactor,
                    riskIndicators.baseSpreadPerLeg,
                    balance.totalCollateralPayFixed,
                    balance.totalCollateralReceiveFixed,
                    balance.liquidityPool,
                    bosStruct.accruedIpor.indexValue,
                    riskIndicators.fixedRateCapPerLeg
                )
            ),
            (uint256)
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

        uint256 newSwapId = IAmmStorage(ctx.poolCfg.ammStorage).updateStorageWhenOpenSwapPayFixedInternal(
            newSwap,
            ctx.poolCfg.iporPublicationFee
        );

        IERC20Upgradeable(ctx.poolCfg.asset).safeTransferFrom(msg.sender, ctx.poolCfg.ammTreasury, totalAmount);

        _emitOpenSwapEvent(
            ctx.poolCfg.asset, //TODO: fix it
            ctx.poolCfg.asset,
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
            ctx.beneficiary,
            block.timestamp,
            totalAmount,
            leverage,
            ctx.tenor,
            ctx.poolCfg
        );

        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IAmmStorage(ctx.poolCfg.ammStorage)
            .getBalancesForOpenSwap();

        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralReceiveFixed = balance.totalCollateralReceiveFixed + bosStruct.collateral;

        _validateLiquidityPoolCollateralRatioAndSwapLeverage(
            balance.liquidityPool,
            balance.totalCollateralReceiveFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
            leverage,
            riskIndicators.maxLeveragePerLeg,
            riskIndicators.maxCollateralRatio,
            riskIndicators.maxCollateralRatioPerLeg,
            ctx.poolCfg.minLeverage
        );

        uint256 offeredRateValue = abi.decode(
            spreadRouter.functionCall(
                abi.encodeWithSelector(
                    ctx.spreadMethodSig,
                    ctx.poolCfg.asset,
                    bosStruct.notional,
                    riskIndicators.demandSpreadFactor,
                    riskIndicators.baseSpreadPerLeg,
                    balance.totalCollateralPayFixed,
                    balance.totalCollateralReceiveFixed,
                    balance.liquidityPool,
                    bosStruct.accruedIpor.indexValue,
                    riskIndicators.fixedRateCapPerLeg
                )
            ),
            (uint256)
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

        uint256 newSwapId = IAmmStorage(ctx.poolCfg.ammStorage).updateStorageWhenOpenSwapReceiveFixedInternal(
            newSwap,
            ctx.poolCfg.iporPublicationFee
        );

        IERC20Upgradeable(ctx.poolCfg.asset).safeTransferFrom(msg.sender, ctx.poolCfg.ammTreasury, totalAmount);

        _emitOpenSwapEvent(
            ctx.poolCfg.asset, //TODO: fix it
            ctx.poolCfg.asset,
            newSwapId,
            bosStruct.wadTotalAmount,
            newSwap,
            indicator,
            1,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    function _beforeOpenSwap(
        address beneficiary,
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 leverage,
        IporTypes.SwapTenor tenor,
        AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory poolCfg
    ) internal view returns (AmmInternalTypes.BeforeOpenSwapStruct memory bosStruct) {
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        require(totalAmount > 0, AmmErrors.TOTAL_AMOUNT_TOO_LOW);

        require(
            IERC20Upgradeable(poolCfg.asset).balanceOf(msg.sender) >= totalAmount,
            IporErrors.SENDER_ASSET_BALANCE_TOO_LOW
        );

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, poolCfg.decimals);
        uint256 wadLiquidationDepositAmount = poolCfg.liquidationDepositAmount * 1e18;

        (uint256 collateral, uint256 notional, uint256 openingFeeAmount) = SwapLogicGenOne.calculateSwapAmount(
            tenor,
            wadTotalAmount,
            leverage,
            wadLiquidationDepositAmount,
            poolCfg.iporPublicationFee,
            poolCfg.openingFeeRate
        );

        (uint256 openingFeeLPAmount, uint256 openingFeeTreasuryAmount) = SwapLogicGenOne.splitOpeningFeeAmount(
            openingFeeAmount,
            poolCfg.openingFeeTreasuryPortionRate
        );

        require(collateral <= poolCfg.maxSwapCollateralAmount, AmmErrors.COLLATERAL_AMOUNT_TOO_HIGH);

        require(
            wadTotalAmount > wadLiquidationDepositAmount + poolCfg.iporPublicationFee + openingFeeAmount,
            AmmErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );
        IporTypes.AccruedIpor memory accruedIndex = IIporOracle(iporOracle).getAccruedIndex(
            openTimestamp,
            poolCfg.asset
        );

        return
            AmmInternalTypes.BeforeOpenSwapStruct(
                wadTotalAmount,
                collateral,
                notional,
                openingFeeLPAmount,
                openingFeeTreasuryAmount,
                poolCfg.iporPublicationFee,
                poolCfg.liquidationDepositAmount,
                accruedIndex
            );
    }

    function _emitOpenSwapEvent(
        address inputAsset,
        address asset,
        uint256 newSwapId,
        uint256 wadTotalAmount,
        AmmTypes.NewSwap memory newSwap,
        AmmTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 iporPublicationFee
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
                iporPublicationFee,
                newSwap.liquidationDepositAmount * 1e18
            ),
            newSwap.openTimestamp,
            newSwap.openTimestamp + SwapLogicGenOne.getTenorInSeconds(newSwap.tenor),
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
        uint256 maxCollateralRatioPerLeg,
        uint256 cfgMinLeverage
    ) internal pure {
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

        require(leverage >= cfgMinLeverage, AmmErrors.LEVERAGE_TOO_LOW);
        require(leverage <= maxLeverage, AmmErrors.LEVERAGE_TOO_HIGH);
    }
}
