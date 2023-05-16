// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./ISpread28Days.sol";
import "./ImbalanceSpreadLibs.sol";
import "./SpreadStorageLibs.sol";
import "./ISpreadLens.sol";
import "./ISpread28DaysLens.sol";

contract Spread28Days is ISpread28Days, ISpread28DaysLens {
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
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional
    ) external override returns (uint256 quoteValue) {
        uint256 maxLeverage = 1_000 * 1e18; // TODO get this data;
        uint256 maxLpUtilizationPerLegRate = 5e17; // TODO get this data;
        int256 baseSpread = 0; // TODO get this data;
        uint256 imbalanceSpread = _calculateImbalancePayFixed28Day(
            asset,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate,
            true
        );

        int256 intQuoteValue = accruedIpor.indexValue.toInt256() +
            baseSpread +
            imbalanceSpread.toInt256();

        if (intQuoteValue > 0) {
            return intQuoteValue.toUint256();
        }
    }

    function calculatePayFixed28Days(
        address asset,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional
    ) external override returns (uint256 quoteValue) {
        uint256 maxLeverage = 1_000 * 1e18; // TODO get this data;
        uint256 maxLpUtilizationPerLegRate = 5e17; // TODO get this data;
        int256 baseSpread = 0; // TODO get this data;
        uint256 imbalanceSpread = _calculateImbalancePayFixed28Day(
            asset,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate,
            false
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
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional
    ) external override returns (uint256 quoteValue) {
        uint256 maxLeverage = 1_000 * 1e18; // TODO get this data;
        uint256 maxLpUtilizationPerLegRate = 5e17; // TODO get this data;
        int256 baseSpread = 0; // TODO get this data;
        uint256 imbalanceSpread = _calculateImbalanceReceiveFixed28Day(
            asset,
            accruedIpor,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate,
            true
        );

        int256 intQuoteValueWithIpor = accruedIpor.indexValue.toInt256() +
            baseSpread -
            imbalanceSpread.toInt256();

        quoteValue = _calculateReferenceLegReceiveFixed(
            intQuoteValueWithIpor > 0 ? intQuoteValueWithIpor.toUint256() : 0,
            accruedIpor.exponentialMovingAverage
        );
    }

    function calculateReceiveFixed28Days(
        address asset,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional
    ) external override returns (uint256 quoteValue) {
        uint256 maxLeverage = 1_000 * 1e18; // TODO get this data;
        uint256 maxLpUtilizationPerLegRate = 5e17; // TODO get this data;
        int256 baseSpread = 0; // TODO get this data;
        uint256 imbalanceSpread = _calculateImbalanceReceiveFixed28Day(
            asset,
            accruedIpor,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate,
            false
        );

        int256 intQuoteValueWithIpor = accruedIpor.indexValue.toInt256() +
            baseSpread -
            imbalanceSpread.toInt256();

        quoteValue = _calculateReferenceLegReceiveFixed(
            intQuoteValueWithIpor > 0 ? intQuoteValueWithIpor.toUint256() : 0,
            accruedIpor.exponentialMovingAverage
    );
    }

    function getSupportedAssets() external view returns (address[] memory) {
        address[] memory assets = new address[](3);
        assets[0] = _DAI;
        assets[1] = _USDC;
        assets[2] = _USDT;
        return assets;
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

    function _calculateImbalancePayFixed28Day(
        address asset,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate,
        bool updateWeightedNotional
    ) internal returns (uint256 spreadValue) {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getImbalanceSpreadConfig(
            asset,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate
        );

        spreadValue = ImbalanceSpreadLibs.calculatePayFixedSpread(inputData);

        if (updateWeightedNotional) {
            SpreadTypes.WeightedNotionalMemory memory weightedNotional = SpreadStorageLibs
                .getWeightedNotional(inputData.storageId28Days);

            CalculateWeightedNotionalLibs.updateWeightedNotionalPayFixed(
                weightedNotional,
                inputData.swapNotional,
                28 days
            );
        }
    }

    function _calculateImbalanceReceiveFixed28Day(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate,
        bool updateWeightedNotional
    ) internal returns (uint256 spreadValue) {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getImbalanceSpreadConfig(
            asset,
            accruedIpor,
            accruedBalance,
            swapNotional,
            maxLeverage,
            maxLpUtilizationPerLegRate
        );

        spreadValue = ImbalanceSpreadLibs.calculateReceiveFixedSpread(inputData);

        if (updateWeightedNotional) {
            SpreadTypes.WeightedNotionalMemory memory weightedNotional = SpreadStorageLibs
                .getWeightedNotional(inputData.storageId28Days);

            CalculateWeightedNotionalLibs.updateWeightedNotionalReceiveFixed(
                weightedNotional,
                inputData.swapNotional,
                28 days
            );
        }
    }

    function _getImbalanceSpreadConfig(
        address asset,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate
    ) internal returns (ImbalanceSpreadLibs.SpreadInputData memory inputData) {
        //DAI
        inputData = ImbalanceSpreadLibs.SpreadInputData({
            accruedBalance: accruedBalance,
            swapNotional: swapNotional,
            maxLeverage: maxLeverage,
            maxLpUtilizationPerLegRate: maxLpUtilizationPerLegRate,
            storageIds: new SpreadStorageLibs.StorageId[](2)
        });

        if (asset == _USDC) {
            inputData.storageIds[0] = SpreadStorageLibs.StorageId.WeightedNotional28DaysUsdc;
            inputData.storageIds[1] = SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdc;
            return inputData;
        } else if (asset == _USDT) {
            inputData.storageIds[0] = SpreadStorageLibs.StorageId.WeightedNotional28DaysUsdt;
            inputData.storageIds[1] = SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdt;
            return inputData;
        } else if (asset == _DAI) {
            inputData.storageIds[0] = SpreadStorageLibs.StorageId.WeightedNotional28DaysDai;
            inputData.storageIds[1] = SpreadStorageLibs.StorageId.WeightedNotional90DaysDai;
            return inputData;
        }
        revert("Spread: asset not supported");
    }
}
