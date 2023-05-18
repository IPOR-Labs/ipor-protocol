// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../interfaces/IAmmOpenSwapService.sol";
import "./libraries/types/AmmMiltonTypes.sol";
import "../libraries/errors/MiltonErrors.sol";
import "./libraries/IporSwapLogic.sol";

contract AmmOpenSwapService is IAmmOpenSwapService {
    using Address for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev represented in 18 decimals
    uint256 internal immutable _iporPublicationFee;

    /// @dev max collateral used to open a swap, represented in 18 decimals
    uint256 internal immutable _maxSwapCollateralAmount;

    /// @dev represented without 18 decimals
    uint256 internal immutable _liquidationDepositAmount;

    /// @dev represented in 18 decimals
    uint256 internal immutable _liquidationDepositAmountWad;

    /// @dev 0 means 0%, 1e18 means 100%, represented in 18 decimals
    uint256 internal immutable _openingFeeRate;

    /// @notice Opening Fee is divided between Treasury Balance and Liquidity Pool Balance,
    /// below value define how big pie going to Treasury Balance
    /// @dev 0 means 0%, 1e18 means 100%, represented in 18 decimals
    uint256 internal immutable _openingFeeTreasuryPortionRate;

    uint256 internal immutable _minLeverage;
    uint256 internal immutable _maxLeverage;

    address internal immutable _usdt;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;

    address internal immutable _usdc;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;

    address internal immutable _dai;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;

    address internal immutable _iporOracle;
    address internal immutable _iporRiskManagementOracle;
    address internal immutable _spreadRouter;

    struct Pool {
        address asset;
        address ammStorage;
        address ammTreasury;
    }

    struct Context {
        address behalfOf;
        address asset;
        address ammStorage;
        address ammTreasury;
        uint256 maturity;
        string spreadMethodSig;
    }

    struct Configuration {
        uint256 iporPublicationFee;
        uint256 maxSwapCollateralAmount;
        uint256 liquidationDepositAmount;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 openingFeeRate;
        uint256 openingFeeTreasuryPortionRate;
    }

    struct SpreadInputs {
        address asset;
        uint256 swapNotional;
        uint256 maxLeverage;
        uint256 maxLpUtilizationPerLegRate;
        int256 baseSpread;
        uint256 totalCollateralPayFixed;
        uint256 totalCollateralReceiveFixed;
        uint256 liquidityPool;
        uint256 totalNotionalPayFixed;
        uint256 totalNotionalReceiveFixed;
    }

    constructor(
        Configuration memory configuration,
        Pool memory usdtPool,
        Pool memory usdcPool,
        Pool memory daiPool,
        address iporOracle,
        address iporRiskManagementOracle,
        address spreadRouter
    ) {
        _iporPublicationFee = configuration.iporPublicationFee;
        _maxSwapCollateralAmount = configuration.maxSwapCollateralAmount;

        _liquidationDepositAmount = configuration.liquidationDepositAmount;
        _liquidationDepositAmountWad = configuration.liquidationDepositAmount * Constants.D18;

        _minLeverage = configuration.minLeverage;
        _maxLeverage = configuration.maxLeverage;

        _openingFeeRate = configuration.openingFeeRate;
        _openingFeeTreasuryPortionRate = configuration.openingFeeTreasuryPortionRate;

        _usdt = usdtPool.asset;
        _usdtAmmStorage = usdtPool.ammStorage;
        _usdtAmmTreasury = usdtPool.ammTreasury;

        _usdc = usdcPool.asset;
        _usdcAmmStorage = usdcPool.ammStorage;
        _usdcAmmTreasury = usdcPool.ammTreasury;

        _dai = daiPool.asset;
        _daiAmmStorage = daiPool.ammStorage;
        _daiAmmTreasury = daiPool.ammTreasury;

        _iporOracle = iporOracle;
        _iporRiskManagementOracle = iporRiskManagementOracle;
        _spreadRouter = spreadRouter;
    }

    function openSwapPayFixed28daysUsdt(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdt,
            ammStorage: _usdtAmmStorage,
            ammTreasury: _usdtAmmTreasury,
            maturity: 28,
            spreadMethodSig: "calculatePayFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed60daysUsdt(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdt,
            ammStorage: _usdtAmmStorage,
            ammTreasury: _usdtAmmTreasury,
            maturity: 60,
            spreadMethodSig: "calculatePayFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed90daysUsdt(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdt,
            ammStorage: _usdtAmmStorage,
            ammTreasury: _usdtAmmTreasury,
            maturity: 90,
            spreadMethodSig: "calculatePayFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed28daysUsdt(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdt,
            ammStorage: _usdtAmmStorage,
            ammTreasury: _usdtAmmTreasury,
            maturity: 28,
            spreadMethodSig: "calculateReceiveFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });

        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed60daysUsdt(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdt,
            ammStorage: _usdtAmmStorage,
            ammTreasury: _usdtAmmTreasury,
            maturity: 60,
            spreadMethodSig: "calculateReceiveFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed90daysUsdt(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdt,
            ammStorage: _usdtAmmStorage,
            ammTreasury: _usdtAmmTreasury,
            maturity: 90,
            spreadMethodSig: "calculateReceiveFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed28daysUsdc(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdc,
            ammStorage: _usdcAmmStorage,
            ammTreasury: _usdcAmmTreasury,
            maturity: 28,
            spreadMethodSig: "calculatePayFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });

        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed60daysUsdc(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdc,
            ammStorage: _usdcAmmStorage,
            ammTreasury: _usdcAmmTreasury,
            maturity: 60,
            spreadMethodSig: "calculatePayFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed90daysUsdc(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdc,
            ammStorage: _usdcAmmStorage,
            ammTreasury: _usdcAmmTreasury,
            maturity: 90,
            spreadMethodSig: "calculatePayFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed28daysUsdc(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdc,
            ammStorage: _usdcAmmStorage,
            ammTreasury: _usdcAmmTreasury,
            maturity: 28,
            spreadMethodSig: "calculateReceiveFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed60daysUsdc(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdc,
            ammStorage: _usdcAmmStorage,
            ammTreasury: _usdcAmmTreasury,
            maturity: 60,
            spreadMethodSig: "calculateReceiveFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed90daysUsdc(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _usdc,
            ammStorage: _usdcAmmStorage,
            ammTreasury: _usdcAmmTreasury,
            maturity: 90,
            spreadMethodSig: "calculateReceiveFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed28daysDai(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _dai,
            ammStorage: _daiAmmStorage,
            ammTreasury: _daiAmmTreasury,
            maturity: 28,
            spreadMethodSig: "calculatePayFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed60daysDai(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _dai,
            ammStorage: _daiAmmStorage,
            ammTreasury: _daiAmmTreasury,
            maturity: 60,
            spreadMethodSig: "calculatePayFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapPayFixed90daysDai(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _dai,
            ammStorage: _daiAmmStorage,
            ammTreasury: _daiAmmTreasury,
            maturity: 90,
            spreadMethodSig: "calculatePayFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapPayFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed28daysDai(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _dai,
            ammStorage: _daiAmmStorage,
            ammTreasury: _daiAmmTreasury,
            maturity: 28,
            spreadMethodSig: "calculateReceiveFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed60daysDai(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _dai,
            ammStorage: _daiAmmStorage,
            ammTreasury: _daiAmmTreasury,
            maturity: 60,
            spreadMethodSig: "calculateReceiveFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed90daysDai(
        address behalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override returns (uint256) {
        Context memory context = Context({
            behalfOf: behalfOf,
            asset: _dai,
            ammStorage: _daiAmmStorage,
            ammTreasury: _daiAmmTreasury,
            maturity: 90,
            spreadMethodSig: "calculateReceiveFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256))"
        });
        return _openSwapReceiveFixed(context, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function _openSwapPayFixed(
        Context memory context,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) internal returns (uint256) {
        AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            context.asset,
            block.timestamp,
            totalAmount,
            leverage
        );

        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IMiltonStorage(context.ammStorage)
            .getBalancesForOpenSwap();
        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralPayFixed = balance.totalCollateralPayFixed + bosStruct.collateral;

        AmmMiltonTypes.OpenSwapRiskIndicators memory riskIndicators = _getRiskIndicators(
            context.asset,
            0,
            context.maturity,
            balance.liquidityPool
        );

        _validateLiquidityPoolUtilizationAndSwapLeverage(
            balance.liquidityPool,
            balance.totalCollateralPayFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
            leverage,
            riskIndicators.maxLeveragePerLeg,
            riskIndicators.maxUtilizationRate,
            riskIndicators.maxUtilizationRatePerLeg
        );

        uint256 quoteValue = abi.decode(
            _spreadRouter.functionCall(
                abi.encodeWithSignature(
                    context.spreadMethodSig,
                    context.asset,
                    bosStruct.notional,
                    riskIndicators.maxLeveragePerLeg,
                    riskIndicators.maxUtilizationRatePerLeg,
                    riskIndicators.spread,
                    balance.totalCollateralPayFixed,
                    balance.totalCollateralReceiveFixed,
                    balance.liquidityPool,
                    balance.totalNotionalPayFixed,
                    balance.totalNotionalReceiveFixed
                )
            ),
            (uint256)
        );

        require(
            acceptableFixedInterestRate > 0 && quoteValue <= acceptableFixedInterestRate,
            MiltonErrors.ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED
        );

        MiltonTypes.IporSwapIndicator memory indicator = MiltonTypes.IporSwapIndicator(
            bosStruct.accruedIpor.indexValue,
            bosStruct.accruedIpor.ibtPrice,
            IporMath.division(bosStruct.notional * Constants.D18, bosStruct.accruedIpor.ibtPrice),
            quoteValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            msg.sender,
            block.timestamp,
            bosStruct.collateral,
            bosStruct.notional,
            indicator.ibtQuantity,
            indicator.fixedInterestRate,
            bosStruct.liquidationDepositAmount,
            bosStruct.openingFeeLPAmount,
            bosStruct.openingFeeTreasuryAmount
        );

        uint256 newSwapId = IMiltonStorage(context.ammStorage).updateStorageWhenOpenSwapPayFixed(
            newSwap,
            _iporPublicationFee
        );

        IERC20Upgradeable(context.asset).safeTransferFrom(msg.sender, context.ammTreasury, totalAmount);

        _emitOpenSwapEvent(
            context.asset,
            newSwapId,
            bosStruct.wadTotalAmount,
            newSwap,
            indicator,
            0,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    //@param totalAmount underlying tokens transferred from buyer to Milton, represented in decimals specific for asset
    function _openSwapReceiveFixed(
        Context memory context,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    )
        internal
        returns (
            //        string memory spreadMethodSig
            uint256
        )
    {
        AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            context.asset,
            block.timestamp,
            totalAmount,
            leverage
        );

        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IMiltonStorage(context.ammStorage)
            .getBalancesForOpenSwap();
        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralReceiveFixed = balance.totalCollateralReceiveFixed + bosStruct.collateral;

        AmmMiltonTypes.OpenSwapRiskIndicators memory riskIndicators = _getRiskIndicators(
            context.asset,
            1,
            context.maturity,
            balance.liquidityPool
        );

        _validateLiquidityPoolUtilizationAndSwapLeverage(
            balance.liquidityPool,
            balance.totalCollateralReceiveFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
            leverage,
            riskIndicators.maxLeveragePerLeg,
            riskIndicators.maxUtilizationRate,
            riskIndicators.maxUtilizationRatePerLeg
        );

        uint256 quoteValue = abi.decode(
            _spreadRouter.functionCall(
                abi.encodeWithSignature(
                    context.spreadMethodSig,
                    context.asset,
                    bosStruct.notional,
                    riskIndicators.maxLeveragePerLeg,
                    riskIndicators.maxUtilizationRatePerLeg,
                    riskIndicators.spread,
                    balance.totalCollateralPayFixed,
                    balance.totalCollateralReceiveFixed,
                    balance.liquidityPool,
                    balance.totalNotionalPayFixed,
                    balance.totalNotionalReceiveFixed
                )
            ),
            (uint256)
        );

        require(acceptableFixedInterestRate <= quoteValue, MiltonErrors.ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED);

        MiltonTypes.IporSwapIndicator memory indicator = MiltonTypes.IporSwapIndicator(
            bosStruct.accruedIpor.indexValue,
            bosStruct.accruedIpor.ibtPrice,
            IporMath.division(bosStruct.notional * Constants.D18, bosStruct.accruedIpor.ibtPrice),
            quoteValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            msg.sender,
            block.timestamp,
            bosStruct.collateral,
            bosStruct.notional,
            indicator.ibtQuantity,
            indicator.fixedInterestRate,
            bosStruct.liquidationDepositAmount,
            bosStruct.openingFeeLPAmount,
            bosStruct.openingFeeTreasuryAmount
        );

        uint256 newSwapId = IMiltonStorage(context.ammStorage).updateStorageWhenOpenSwapReceiveFixed(
            newSwap,
            _iporPublicationFee
        );

        IERC20Upgradeable(context.asset).safeTransferFrom(msg.sender, context.ammTreasury, totalAmount);

        _emitOpenSwapEvent(
            context.asset,
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
        address asset,
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 leverage
    ) internal returns (AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct) {
        require(totalAmount > 0, MiltonErrors.TOTAL_AMOUNT_TOO_LOW);

        require(IERC20Upgradeable(asset).balanceOf(msg.sender) >= totalAmount, IporErrors.ASSET_BALANCE_TOO_LOW);

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, IERC20MetadataUpgradeable(asset).decimals());

        require(
            wadTotalAmount > _liquidationDepositAmountWad + _iporPublicationFee,
            MiltonErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        (uint256 collateral, uint256 notional, uint256 openingFeeAmount) = IporSwapLogic.calculateSwapAmount(
            28,
            wadTotalAmount,
            leverage,
            _liquidationDepositAmountWad,
            _iporPublicationFee,
            _openingFeeRate
        );

        (uint256 openingFeeLPAmount, uint256 openingFeeTreasuryAmount) = _splitOpeningFeeAmount(
            openingFeeAmount,
            _openingFeeTreasuryPortionRate
        );

        require(collateral <= _maxSwapCollateralAmount, MiltonErrors.COLLATERAL_AMOUNT_TOO_HIGH);

        require(
            wadTotalAmount > _liquidationDepositAmountWad + _iporPublicationFee + openingFeeAmount,
            MiltonErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );
        IporTypes.AccruedIpor memory accruedIndex;

        accruedIndex = IIporOracle(_iporOracle).getAccruedIndex(openTimestamp, asset);

        return
            AmmMiltonTypes.BeforeOpenSwapStruct(
                wadTotalAmount,
                collateral,
                notional,
                openingFeeLPAmount,
                openingFeeTreasuryAmount,
                _iporPublicationFee,
                _liquidationDepositAmount,
                accruedIndex
            );
    }

    function _getRiskIndicators(
        address asset,
        uint256 direction,
        uint256 duration,
        uint256 liquidityPool
    ) internal view virtual returns (AmmMiltonTypes.OpenSwapRiskIndicators memory riskIndicators) {
        uint256 maxNotionalPerLeg;
        uint256 maxUtilizationRate;

        (
            maxNotionalPerLeg,
            riskIndicators.maxUtilizationRatePerLeg,
            maxUtilizationRate,
            riskIndicators.spread
        ) = IIporRiskManagementOracle(_iporRiskManagementOracle).getOpenSwapParameters(asset, direction, duration);

        uint256 maxCollateralPerLeg = IporMath.division(
            liquidityPool * riskIndicators.maxUtilizationRatePerLeg,
            Constants.D18
        );

        if (maxCollateralPerLeg > 0) {
            riskIndicators.maxLeveragePerLeg = leverageInRange(
                IporMath.division(maxNotionalPerLeg * Constants.D18, maxCollateralPerLeg)
            );
        } else {
            riskIndicators.maxLeveragePerLeg = _minLeverage;
        }
    }

    function leverageInRange(uint256 leverage) internal view returns (uint256) {
        if (leverage > Constants.LEVERAGE_1000) {
            return Constants.LEVERAGE_1000;
        } else if (leverage < _minLeverage) {
            return _minLeverage;
        } else {
            return leverage;
        }
    }

    function _splitOpeningFeeAmount(uint256 openingFeeAmount, uint256 openingFeeForTreasureRate)
        internal
        pure
        returns (uint256 liquidityPoolAmount, uint256 treasuryAmount)
    {
        treasuryAmount = IporMath.division(openingFeeAmount * openingFeeForTreasureRate, Constants.D18);
        liquidityPoolAmount = openingFeeAmount - treasuryAmount;
    }

    function _emitOpenSwapEvent(
        address asset,
        uint256 newSwapId,
        uint256 wadTotalAmount,
        AmmTypes.NewSwap memory newSwap,
        MiltonTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 iporPublicationFee
    ) internal {
        emit OpenSwap(
            newSwapId,
            newSwap.buyer,
            asset,
            MiltonTypes.SwapDirection(direction),
            AmmTypes.OpenSwapMoney(
                wadTotalAmount,
                newSwap.collateral,
                newSwap.notional,
                newSwap.openingFeeLPAmount,
                newSwap.openingFeeTreasuryAmount,
                iporPublicationFee,
                newSwap.liquidationDepositAmount * Constants.D18
            ),
            newSwap.openTimestamp,
            newSwap.openTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            indicator
        );
    }

    function _validateLiquidityPoolUtilizationAndSwapLeverage(
        uint256 totalLiquidityPoolBalance,
        uint256 collateralPerLegBalance,
        uint256 totalCollateralBalance,
        uint256 leverage,
        uint256 maxLeverage,
        uint256 maxUtilizationRate,
        uint256 maxUtilizationRatePerLeg
    ) internal view {
        uint256 utilizationRate;
        uint256 utilizationRatePerLeg;

        if (totalLiquidityPoolBalance > 0) {
            utilizationRate = IporMath.division(totalCollateralBalance * Constants.D18, totalLiquidityPoolBalance);

            utilizationRatePerLeg = IporMath.division(
                collateralPerLegBalance * Constants.D18,
                totalLiquidityPoolBalance
            );
        } else {
            utilizationRate = Constants.MAX_VALUE;
            utilizationRatePerLeg = Constants.MAX_VALUE;
        }

        require(utilizationRate <= maxUtilizationRate, MiltonErrors.LP_UTILIZATION_EXCEEDED);

        require(utilizationRatePerLeg <= maxUtilizationRatePerLeg, MiltonErrors.LP_UTILIZATION_PER_LEG_EXCEEDED);

        require(leverage >= _minLeverage, MiltonErrors.LEVERAGE_TOO_LOW);
        require(leverage <= _maxLeverage, MiltonErrors.LEVERAGE_TOO_HIGH);
    }
}
