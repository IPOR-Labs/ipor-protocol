// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./ISpread28Days.sol";
import "./Spread28DaysConfigLibs.sol";
import "./BaseSpread28DaysLibs.sol";
import "./ImbalanceSpread28DaysLibs.sol";
import "./SpreadStorageLibs.sol";

contract Spread28Days is ISpread28Days {
    using SafeCast for uint256;
    using SafeCast for int256;

    address internal immutable _DAI;
    address internal immutable _USDC;
    address internal immutable _USDT;

    constructor(
        address dai,
        address usdc,
        address usdt
    ) {
        _DAI = dai;
        _USDC = usdc;
        _USDT = usdt;
    }

    function calculateQuotePayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate
    ) external override returns (uint256 quoteValue) {
        int256 baseSpread = _calculateBaseSpreadPayFixed(asset, accruedIpor, accruedBalance);
        uint256 imbalanceSpread = _calculateImbalancePayFixed28Day(
            asset,
            accruedIpor,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate
        );

        int256 intQuoteValue = accruedIpor.indexValue.toInt256() +
            baseSpread +
            imbalanceSpread.toInt256();

        if (intQuoteValue > 0) {
            return intQuoteValue.toUint256();
        }
    }

    function calculateQuoteReceiveFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate
    ) external override returns (uint256 quoteValue) {
        int256 baseSpread = _calculateBaseSpreadReceiveFixed(asset, accruedIpor, accruedBalance);
        uint256 imbalanceSpread = _calculateImbalanceReceiveFixed28Day(
            asset,
            accruedIpor,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate
        );

        int256 intQuoteValueWithIpor = accruedIpor.indexValue.toInt256() +
            baseSpread -
            imbalanceSpread.toInt256();

        quoteValue = _calculateReferenceLegReceiveFixed(
            intQuoteValueWithIpor > 0 ? intQuoteValueWithIpor.toUint256() : 0,
            accruedIpor.exponentialMovingAverage
        );
    }

    function _calculateReferenceLegReceiveFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage
    ) internal pure returns (uint256) {
        if (iporIndexValue < exponentialMovingAverage) {
            return iporIndexValue;
        } else {
            return exponentialMovingAverage;
        }
    }

    function _calculateBaseSpreadPayFixed(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) internal view virtual returns (int256 baseSpread) {
        return
            BaseSpread28DaysLibs._calculateSpreadPremiumsPayFixed(
                accruedIpor,
                accruedBalance,
                _getBaseSpreadConfig(asset)
            );
    }

    function _calculateBaseSpreadReceiveFixed(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance
    ) internal view virtual returns (int256 baseSpread) {
        return
            BaseSpread28DaysLibs._calculateSpreadPremiumsReceiveFixed(
                accruedIpor,
                accruedBalance,
                _getBaseSpreadConfig(asset)
            );
    }

    function _getBaseSpreadConfig(address asset)
        internal
        view
        returns (Spread28DaysConfigLibs.BaseSpreadConfig memory)
    {
        if (asset == _DAI) {
            return Spread28DaysConfigLibs._getBaseSpreadDaiConfig();
        }
        if (asset == _USDC) {
            return Spread28DaysConfigLibs._getBaseSpreadUsdcConfig();
        }
        if (asset == _USDT) {
            return Spread28DaysConfigLibs._getBaseSpreadUsdtConfig();
        }
        revert("Spread: asset not supported");
        //TODO: Do we want costume error code ?
    }

    function _calculateImbalancePayFixed28Day(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate
    ) internal returns (uint256 spreadValue) {
        ImbalanceSpread28DaysLibs.SpreadInputData memory inputData = _getImbalanceSpreadConfig(
            asset,
            accruedIpor,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate
        );

        spreadValue = ImbalanceSpread28DaysLibs.calculatePayFixedSpread(inputData);

        SpreadTypes.WeightedNotionalMemory memory weightedNotional = SpreadStorageLibs
            .getWeightedNotional(inputData.storageId28Days);

        CalculateWeightedNotionalLibs.updateWeightedNotionalPayFixed(
            weightedNotional,
            inputData.swapNotional,
            28 days
        );
    }

    function _calculateImbalanceReceiveFixed28Day(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate
    ) internal returns (uint256 spreadValue) {
        ImbalanceSpread28DaysLibs.SpreadInputData memory inputData = _getImbalanceSpreadConfig(
            asset,
            accruedIpor,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate
        );

        spreadValue = ImbalanceSpread28DaysLibs.calculateReceiveFixedSpread(inputData);

        SpreadTypes.WeightedNotionalMemory memory weightedNotional = SpreadStorageLibs
            .getWeightedNotional(inputData.storageId28Days);

        CalculateWeightedNotionalLibs.updateWeightedNotionalReceiveFixed(
            weightedNotional,
            inputData.swapNotional,
            28 days
        );
    }

    function _getImbalanceSpreadConfig(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate
    ) internal returns (ImbalanceSpread28DaysLibs.SpreadInputData memory inputData) {
        //DAI
        inputData = ImbalanceSpread28DaysLibs.SpreadInputData({
            accruedIpor: accruedIpor,
            accruedBalance: accruedBalance,
            swapNotional: swapNotional,
            maxLeverage: maxLeverage,
            maxLpUtilizationPerLegRate: maxLpUtilizationPerLegRate,
            storageId28Days: SpreadStorageLibs.StorageId.WeightedNotional28DaysDai,
            storageId90Days: SpreadStorageLibs.StorageId.WeightedNotional90DaysDai
        });

        if (asset == _USDC) {
            inputData.storageId28Days = SpreadStorageLibs.StorageId.WeightedNotional28DaysUsdc;
            inputData.storageId90Days = SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdc;
            return inputData;
        } else if (asset == _USDT) {
            inputData.storageId28Days = SpreadStorageLibs.StorageId.WeightedNotional28DaysUsdt;
            inputData.storageId90Days = SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdt;
            return inputData;
        } else if (asset == _DAI) {
            return inputData;
        }
        revert("Spread: asset not supported");
    }
}
