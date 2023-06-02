// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/AmmErrors.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../interfaces/IAmmOpenSwapService.sol";
import "./libraries/types/AmmInternalTypes.sol";
import "../libraries/errors/AmmErrors.sol";
import "./libraries/IporSwapLogic.sol";

contract AmmOpenSwapService is IAmmOpenSwapService {
    using Address for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;
    uint256 internal immutable _usdtIporPublicationFee;
    uint256 internal immutable _usdtMaxSwapCollateralAmount;
    uint256 internal immutable _usdtLiquidationDepositAmount;
    uint256 internal immutable _usdtMinLeverage;
    uint256 internal immutable _usdtOpeningFeeRate;
    uint256 internal immutable _usdtOpeningFeeTreasuryPortionRate;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;
    uint256 internal immutable _usdcIporPublicationFee;
    uint256 internal immutable _usdcMaxSwapCollateralAmount;
    uint256 internal immutable _usdcLiquidationDepositAmount;
    uint256 internal immutable _usdcMinLeverage;
    uint256 internal immutable _usdcOpeningFeeRate;
    uint256 internal immutable _usdcOpeningFeeTreasuryPortionRate;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;
    uint256 internal immutable _daiIporPublicationFee;
    uint256 internal immutable _daiMaxSwapCollateralAmount;
    uint256 internal immutable _daiLiquidationDepositAmount;
    uint256 internal immutable _daiMinLeverage;
    uint256 internal immutable _daiOpeningFeeRate;
    uint256 internal immutable _daiOpeningFeeTreasuryPortionRate;

    address internal immutable _iporOracle;
    address internal immutable _iporRiskManagementOracle;
    address internal immutable _spreadRouter;

    struct Context {
        address onBehalfOf;
        /// @notice swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
        IporTypes.SwapTenor tenor;
        string spreadMethodSig;
        AmmOpenSwapServicePoolConfiguration poolCfg;
    }

    constructor(
        AmmOpenSwapServicePoolConfiguration memory usdtPoolCfg,
        AmmOpenSwapServicePoolConfiguration memory usdcPoolCfg,
        AmmOpenSwapServicePoolConfiguration memory daiPoolCfg,
        address iporOracle,
        address iporRiskManagementOracle,
        address spreadRouter
    ) {
        require(usdtPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool asset"));
        require(usdtPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammStorage"));
        require(
            usdtPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammTreasury")
        );

        require(usdcPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool asset"));
        require(usdcPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammStorage"));
        require(
            usdcPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammTreasury")
        );

        require(daiPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool asset"));
        require(daiPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammStorage"));
        require(daiPoolCfg.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammTreasury"));

        require(iporOracle != address(0), string.concat(IporErrors.WRONG_ADDRESS, " iporOracle"));
        require(
            iporRiskManagementOracle != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " iporRiskManagementOracle")
        );
        require(spreadRouter != address(0), string.concat(IporErrors.WRONG_ADDRESS, " spreadRouter"));

        _usdt = usdtPoolCfg.asset;
        _usdtDecimals = usdtPoolCfg.decimals;
        _usdtAmmStorage = usdtPoolCfg.ammStorage;
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury;
        _usdtIporPublicationFee = usdtPoolCfg.iporPublicationFee;
        _usdtMaxSwapCollateralAmount = usdtPoolCfg.maxSwapCollateralAmount;
        _usdtLiquidationDepositAmount = usdtPoolCfg.liquidationDepositAmount;
        _usdtMinLeverage = usdtPoolCfg.minLeverage;
        _usdtOpeningFeeRate = usdtPoolCfg.openingFeeRate;
        _usdtOpeningFeeTreasuryPortionRate = usdtPoolCfg.openingFeeTreasuryPortionRate;

        _usdc = usdcPoolCfg.asset;
        _usdcDecimals = usdcPoolCfg.decimals;
        _usdcAmmStorage = usdcPoolCfg.ammStorage;
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury;
        _usdcIporPublicationFee = usdcPoolCfg.iporPublicationFee;
        _usdcMaxSwapCollateralAmount = usdcPoolCfg.maxSwapCollateralAmount;
        _usdcLiquidationDepositAmount = usdcPoolCfg.liquidationDepositAmount;
        _usdcMinLeverage = usdcPoolCfg.minLeverage;
        _usdcOpeningFeeRate = usdcPoolCfg.openingFeeRate;
        _usdcOpeningFeeTreasuryPortionRate = usdcPoolCfg.openingFeeTreasuryPortionRate;

        _dai = daiPoolCfg.asset;
        _daiDecimals = daiPoolCfg.decimals;
        _daiAmmStorage = daiPoolCfg.ammStorage;
        _daiAmmTreasury = daiPoolCfg.ammTreasury;
        _daiIporPublicationFee = daiPoolCfg.iporPublicationFee;
        _daiMaxSwapCollateralAmount = daiPoolCfg.maxSwapCollateralAmount;
        _daiLiquidationDepositAmount = daiPoolCfg.liquidationDepositAmount;
        _daiMinLeverage = daiPoolCfg.minLeverage;
        _daiOpeningFeeRate = daiPoolCfg.openingFeeRate;
        _daiOpeningFeeTreasuryPortionRate = daiPoolCfg.openingFeeTreasuryPortionRate;

        _iporOracle = iporOracle;
        _iporRiskManagementOracle = iporRiskManagementOracle;
        _spreadRouter = spreadRouter;
    }

    function getAmmOpenSwapServicePoolConfiguration(address asset)
        external
        view
        override
        returns (AmmOpenSwapServicePoolConfiguration memory)
    {
        return _getPoolConfiguration(asset);
    }

    function openSwapPayFixed28daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_28,
            spreadMethodSig: "calculateAndUpdateOfferedRatePayFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdt)
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed60daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_60,
            spreadMethodSig: "calculateAndUpdateOfferedRatePayFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdt)
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed90daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_90,
            spreadMethodSig: "calculateAndUpdateOfferedRatePayFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdt)
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed28daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_28,
            spreadMethodSig: "calculateAndUpdateOfferedRateReceiveFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdt)
        });

        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed60daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        require(onBehalfOf != address(0), "AmmOpenSwapService: onBehalfOf is zero address");
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_60,
            spreadMethodSig: "calculateAndUpdateOfferedRateReceiveFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdt)
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed90daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_90,
            spreadMethodSig: "calculateAndUpdateOfferedRateReceiveFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdt)
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed28daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_28,
            spreadMethodSig: "calculateAndUpdateOfferedRatePayFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdc)
        });

        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed60daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_60,
            spreadMethodSig: "calculateAndUpdateOfferedRatePayFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdc)
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed90daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_90,
            spreadMethodSig: "calculateAndUpdateOfferedRatePayFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdc)
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed28daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_28,
            spreadMethodSig: "calculateAndUpdateOfferedRateReceiveFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdc)
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed60daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_60,
            spreadMethodSig: "calculateAndUpdateOfferedRateReceiveFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdc)
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed90daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_90,
            spreadMethodSig: "calculateAndUpdateOfferedRateReceiveFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_usdc)
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed28daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_28,
            spreadMethodSig: "calculateAndUpdateOfferedRatePayFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_dai)
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed60daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_60,
            spreadMethodSig: "calculateAndUpdateOfferedRatePayFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_dai)
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed90daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_90,
            spreadMethodSig: "calculateAndUpdateOfferedRatePayFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_dai)
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed28daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_28,
            spreadMethodSig: "calculateAndUpdateOfferedRateReceiveFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_dai)
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed60daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_60,
            spreadMethodSig: "calculateAndUpdateOfferedRateReceiveFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_dai)
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed90daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            onBehalfOf: onBehalfOf,
            tenor: IporTypes.SwapTenor.DAYS_90,
            spreadMethodSig: "calculateAndUpdateOfferedRateReceiveFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256,uint256))",
            poolCfg: _getPoolConfiguration(_dai)
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function _getPoolConfiguration(address asset) internal view returns (AmmOpenSwapServicePoolConfiguration memory) {
        if (asset == _usdt) {
            return
                AmmOpenSwapServicePoolConfiguration({
                    asset: _usdt,
                    decimals: _usdtDecimals,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury,
                    iporPublicationFee: _usdtIporPublicationFee,
                    maxSwapCollateralAmount: _usdtMaxSwapCollateralAmount,
                    liquidationDepositAmount: _usdtLiquidationDepositAmount,
                    minLeverage: _usdtMinLeverage,
                    openingFeeRate: _usdtOpeningFeeRate,
                    openingFeeTreasuryPortionRate: _usdtOpeningFeeTreasuryPortionRate
                });
        } else if (asset == _usdc) {
            return
                AmmOpenSwapServicePoolConfiguration({
                    asset: _usdc,
                    decimals: _usdcDecimals,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury,
                    iporPublicationFee: _usdcIporPublicationFee,
                    maxSwapCollateralAmount: _usdcMaxSwapCollateralAmount,
                    liquidationDepositAmount: _usdcLiquidationDepositAmount,
                    minLeverage: _usdcMinLeverage,
                    openingFeeRate: _usdcOpeningFeeRate,
                    openingFeeTreasuryPortionRate: _usdcOpeningFeeTreasuryPortionRate
                });
        } else if (asset == _dai) {
            return
                AmmOpenSwapServicePoolConfiguration({
                    asset: _dai,
                    decimals: _daiDecimals,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury,
                    iporPublicationFee: _daiIporPublicationFee,
                    maxSwapCollateralAmount: _daiMaxSwapCollateralAmount,
                    liquidationDepositAmount: _daiLiquidationDepositAmount,
                    minLeverage: _daiMinLeverage,
                    openingFeeRate: _daiOpeningFeeRate,
                    openingFeeTreasuryPortionRate: _daiOpeningFeeTreasuryPortionRate
                });
        } else {
            revert("Unsupported asset");
        }
    }

    function _openSwapPayFixed(
        Context memory ctx,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) internal returns (uint256) {
        AmmInternalTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            ctx.onBehalfOf,
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

        AmmInternalTypes.OpenSwapRiskIndicators memory riskIndicators = _getRiskIndicators(
            ctx.poolCfg.asset,
            0,
            ctx.tenor,
            balance.liquidityPool,
            ctx.poolCfg.minLeverage
        );

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

        uint256 quoteValue = abi.decode(
            _spreadRouter.functionCall(
                abi.encodeWithSignature(
                    ctx.spreadMethodSig,
                    ctx.poolCfg.asset,
                    bosStruct.notional,
                    riskIndicators.maxLeveragePerLeg,
                    riskIndicators.maxCollateralRatioPerLeg,
                    riskIndicators.spread,
                    balance.totalCollateralPayFixed,
                    balance.totalCollateralReceiveFixed,
                    balance.liquidityPool,
                    balance.totalNotionalPayFixed,
                    balance.totalNotionalReceiveFixed,
                    bosStruct.accruedIpor.indexValue,
                    riskIndicators.fixedRateCap
                )
            ),
            (uint256)
        );

        require(
            acceptableFixedInterestRate > 0 && quoteValue <= acceptableFixedInterestRate,
            AmmErrors.ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED
        );

        AmmTypes.IporSwapIndicator memory indicator = AmmTypes.IporSwapIndicator(
            bosStruct.accruedIpor.indexValue,
            bosStruct.accruedIpor.ibtPrice,
            IporMath.division(bosStruct.notional * 1e18, bosStruct.accruedIpor.ibtPrice),
            quoteValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            ctx.onBehalfOf,
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

        uint256 newSwapId = IAmmStorage(ctx.poolCfg.ammStorage).updateStorageWhenOpenSwapPayFixed(
            newSwap,
            ctx.poolCfg.iporPublicationFee
        );

        IERC20Upgradeable(ctx.poolCfg.asset).safeTransferFrom(msg.sender, ctx.poolCfg.ammTreasury, totalAmount);

        _emitOpenSwapEvent(
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
        uint256 leverage
    ) internal returns (uint256) {
        AmmInternalTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            ctx.onBehalfOf,
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

        AmmInternalTypes.OpenSwapRiskIndicators memory riskIndicators = _getRiskIndicators(
            ctx.poolCfg.asset,
            1,
            ctx.tenor,
            balance.liquidityPool,
            ctx.poolCfg.minLeverage
        );

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

        uint256 quoteValue = abi.decode(
            _spreadRouter.functionCall(
                abi.encodeWithSignature(
                    ctx.spreadMethodSig,
                    ctx.poolCfg.asset,
                    bosStruct.notional,
                    riskIndicators.maxLeveragePerLeg,
                    riskIndicators.maxCollateralRatioPerLeg,
                    riskIndicators.spread,
                    balance.totalCollateralPayFixed,
                    balance.totalCollateralReceiveFixed,
                    balance.liquidityPool,
                    balance.totalNotionalPayFixed,
                    balance.totalNotionalReceiveFixed,
                    bosStruct.accruedIpor.indexValue,
                    riskIndicators.fixedRateCap
                )
            ),
            (uint256)
        );

        require(acceptableFixedInterestRate <= quoteValue, AmmErrors.ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED);

        AmmTypes.IporSwapIndicator memory indicator = AmmTypes.IporSwapIndicator(
            bosStruct.accruedIpor.indexValue,
            bosStruct.accruedIpor.ibtPrice,
            IporMath.division(bosStruct.notional * 1e18, bosStruct.accruedIpor.ibtPrice),
            quoteValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            ctx.onBehalfOf,
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

        uint256 newSwapId = IAmmStorage(ctx.poolCfg.ammStorage).updateStorageWhenOpenSwapReceiveFixed(
            newSwap,
            ctx.poolCfg.iporPublicationFee
        );

        IERC20Upgradeable(ctx.poolCfg.asset).safeTransferFrom(msg.sender, ctx.poolCfg.ammTreasury, totalAmount);

        _emitOpenSwapEvent(
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
        address onBehalfOf,
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 leverage,
        IporTypes.SwapTenor tenor,
        AmmOpenSwapServicePoolConfiguration memory poolCfg
    ) internal view returns (AmmInternalTypes.BeforeOpenSwapStruct memory bosStruct) {
        require(onBehalfOf != address(0), IporErrors.WRONG_ADDRESS);

        require(totalAmount > 0, AmmErrors.TOTAL_AMOUNT_TOO_LOW);

        require(
            IERC20Upgradeable(poolCfg.asset).balanceOf(msg.sender) >= totalAmount,
            IporErrors.SENDER_ASSET_BALANCE_TOO_LOW
        );

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, poolCfg.decimals);
        uint256 liquidationDepositAmountWad = poolCfg.liquidationDepositAmount * 1e18;

        require(
            wadTotalAmount > liquidationDepositAmountWad + poolCfg.iporPublicationFee,
            AmmErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        (uint256 collateral, uint256 notional, uint256 openingFeeAmount) = IporSwapLogic.calculateSwapAmount(
            tenor,
            wadTotalAmount,
            leverage,
            liquidationDepositAmountWad,
            poolCfg.iporPublicationFee,
            poolCfg.openingFeeRate
        );

        (uint256 openingFeeLPAmount, uint256 openingFeeTreasuryAmount) = _splitOpeningFeeAmount(
            openingFeeAmount,
            poolCfg.openingFeeTreasuryPortionRate
        );

        require(collateral <= poolCfg.maxSwapCollateralAmount, AmmErrors.COLLATERAL_AMOUNT_TOO_HIGH);

        require(
            wadTotalAmount > liquidationDepositAmountWad + poolCfg.iporPublicationFee + openingFeeAmount,
            AmmErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );
        IporTypes.AccruedIpor memory accruedIndex;

        accruedIndex = IIporOracle(_iporOracle).getAccruedIndex(openTimestamp, poolCfg.asset);

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

    function _getRiskIndicators(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 liquidityPool,
        uint256 cfgMinLeverage
    ) internal view virtual returns (AmmInternalTypes.OpenSwapRiskIndicators memory riskIndicators) {
        uint256 maxNotionalPerLeg;

        (
            maxNotionalPerLeg,
            riskIndicators.maxCollateralRatioPerLeg,
            riskIndicators.maxCollateralRatio,
            riskIndicators.spread,
            riskIndicators.fixedRateCap
        ) = IIporRiskManagementOracle(_iporRiskManagementOracle).getOpenSwapParameters(asset, direction, tenor);

        uint256 maxCollateralPerLeg = IporMath.division(liquidityPool * riskIndicators.maxCollateralRatioPerLeg, 1e18);

        if (maxCollateralPerLeg > 0) {
            riskIndicators.maxLeveragePerLeg = _leverageInRange(
                IporMath.division(maxNotionalPerLeg * 1e18, maxCollateralPerLeg),
                cfgMinLeverage
            );
        } else {
            riskIndicators.maxLeveragePerLeg = cfgMinLeverage;
        }
    }

    function _leverageInRange(uint256 leverage, uint256 cfgMinLeverage) internal pure returns (uint256) {
        if (leverage > Constants.WAD_LEVERAGE_1000) {
            return Constants.WAD_LEVERAGE_1000;
        } else if (leverage < cfgMinLeverage) {
            return cfgMinLeverage;
        } else {
            return leverage;
        }
    }

    function _splitOpeningFeeAmount(uint256 openingFeeAmount, uint256 openingFeeForTreasureRate)
        internal
        pure
        returns (uint256 liquidityPoolAmount, uint256 treasuryAmount)
    {
        treasuryAmount = IporMath.division(openingFeeAmount * openingFeeForTreasureRate, 1e18);
        liquidityPoolAmount = openingFeeAmount - treasuryAmount;
    }

    function _emitOpenSwapEvent(
        address asset,
        uint256 newSwapId,
        uint256 wadTotalAmount,
        AmmTypes.NewSwap memory newSwap,
        AmmTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 iporPublicationFee
    ) internal {
        emit OpenSwap(
            newSwapId,
            newSwap.buyer,
            asset,
            AmmTypes.SwapDirection(direction),
            AmmTypes.OpenSwapMoney(
                wadTotalAmount,
                newSwap.collateral,
                newSwap.notional,
                newSwap.openingFeeLPAmount,
                newSwap.openingFeeTreasuryAmount,
                iporPublicationFee,
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
