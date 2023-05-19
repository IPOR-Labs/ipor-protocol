// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./ISpread90Days.sol";
import "./ISpread90DaysLens.sol";
import "./ImbalanceSpreadLibs.sol";
import "./SpreadStorageLibs.sol";

contract Spread90Days is ISpread90Days, ISpread90DaysLens {
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

    function calculateQuotePayFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 quoteValue)
    {
        uint256 imbalanceSpread = _calculateImbalancePayFixedAndUpdateTimeWeightedNotional90Day(spreadInputs);

        int256 intQuoteValue = spreadInputs.indexValue.toInt256() +
            spreadInputs.baseSpread +
            imbalanceSpread.toInt256();

        quoteValue = intQuoteValue > 0 ? intQuoteValue.toUint256() : 0;
    }

    function calculatePayFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 quoteValue)
    {
        uint256 imbalanceSpread = _calculateImbalancePayFixed90Day(spreadInputs);

        int256 intQuoteValue = spreadInputs.indexValue.toInt256() +
            spreadInputs.baseSpread +
            imbalanceSpread.toInt256();

        quoteValue = intQuoteValue > 0 ? intQuoteValue.toUint256() : 0;
    }

    function calculateQuoteReceiveFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 quoteValue)
    {
        uint256 imbalanceSpread = _calculateImbalanceReceiveFixedAndUpdateTimeWeightedNotional90Day(spreadInputs);

        int256 intQuoteValueWithIpor = spreadInputs.indexValue.toInt256() +
            spreadInputs.baseSpread -
            imbalanceSpread.toInt256();

        quoteValue = intQuoteValueWithIpor > 0 ? intQuoteValueWithIpor.toUint256() : 0;
    }

    function calculateReceiveFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 quoteValue)
    {
        uint256 imbalanceSpread = _calculateImbalanceReceiveFixed90Day(spreadInputs);

        int256 intQuoteValueWithIpor = spreadInputs.indexValue.toInt256() +
            spreadInputs.baseSpread -
            imbalanceSpread.toInt256();

        quoteValue = intQuoteValueWithIpor > 0 ? intQuoteValueWithIpor.toUint256() : 0;
    }

    function getSupportedAssets() external view returns (address[] memory) {
        address[] memory assets = new address[](3);
        assets[0] = _DAI;
        assets[1] = _USDC;
        assets[2] = _USDT;
        return assets;
    }

    function spreadFunction90DaysConfig() external pure returns (uint256[] memory) {
        return ImbalanceSpreadLibs.spreadFunctionConfig();
    }

    function _calculateImbalancePayFixed90Day(IporTypes.SpreadInputs memory spreadInputs)
        internal
        returns (uint256 spreadValue)
    {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getImbalanceSpreadConfig(spreadInputs);

        spreadValue = ImbalanceSpreadLibs.calculatePayFixedSpread(inputData);
    }

    function _calculateImbalancePayFixedAndUpdateTimeWeightedNotional90Day(IporTypes.SpreadInputs memory spreadInputs)
        internal
        returns (uint256 spreadValue)
    {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getImbalanceSpreadConfig(spreadInputs);

        spreadValue = ImbalanceSpreadLibs.calculatePayFixedSpread(inputData);

        SpreadTypes.WeightedNotionalMemory memory weightedNotional = SpreadStorageLibs.getWeightedNotional(
            inputData.storageId
        );

        CalculateWeightedNotionalLibs.updateWeightedNotionalPayFixed(weightedNotional, inputData.swapNotional, 90 days);
    }

    function _calculateImbalanceReceiveFixed90Day(IporTypes.SpreadInputs calldata spreadInputs)
        internal
        returns (uint256 spreadValue)
    {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getImbalanceSpreadConfig(spreadInputs);

        spreadValue = ImbalanceSpreadLibs.calculateReceiveFixedSpread(inputData);
    }

    function _calculateImbalanceReceiveFixedAndUpdateTimeWeightedNotional90Day(
        IporTypes.SpreadInputs calldata spreadInputs
    ) internal returns (uint256 spreadValue) {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getImbalanceSpreadConfig(spreadInputs);

        spreadValue = ImbalanceSpreadLibs.calculateReceiveFixedSpread(inputData);

        SpreadTypes.WeightedNotionalMemory memory weightedNotional = SpreadStorageLibs.getWeightedNotional(
            inputData.storageId
        );

        CalculateWeightedNotionalLibs.updateWeightedNotionalReceiveFixed(
            weightedNotional,
            inputData.swapNotional,
            90 days
        );
    }

    function _getImbalanceSpreadConfig(IporTypes.SpreadInputs memory spreadInputs)
        internal
        returns (ImbalanceSpreadLibs.SpreadInputData memory inputData)
    {
        inputData = ImbalanceSpreadLibs.SpreadInputData({
            totalCollateralPayFixed: inputData.totalCollateralPayFixed,
            totalCollateralReceiveFixed: inputData.totalCollateralReceiveFixed,
            liquidityPool: inputData.liquidityPool,
            totalNotionalPayFixed: inputData.totalNotionalPayFixed,
            totalNotionalReceiveFixed: inputData.totalNotionalReceiveFixed,
            swapNotional: inputData.swapNotional,
            maxLeverage: inputData.maxLeverage,
            maxLpUtilizationPerLegRate: inputData.maxLpUtilizationPerLegRate,
            storageIds: new SpreadStorageLibs.StorageId[](2),
            maturities: new uint256[](2),
            storageId: SpreadStorageLibs.StorageId.WeightedNotional90DaysDai
        });

        inputData.maturities[0] = 28 days;
        inputData.maturities[1] = 60 days;
        inputData.maturities[2] = 90 days;

        if (spreadInputs.asset == _USDC) {
            inputData.storageId = SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdc;
            inputData.storageIds[0] = SpreadStorageLibs.StorageId.WeightedNotional28DaysUsdc;
            inputData.storageIds[1] = SpreadStorageLibs.StorageId.WeightedNotional60DaysUsdc;
            inputData.storageIds[2] = SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdc;
            return inputData;
        } else if (spreadInputs.asset == _USDT) {
            inputData.storageId = SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdt;
            inputData.storageIds[0] = SpreadStorageLibs.StorageId.WeightedNotional28DaysUsdt;
            inputData.storageIds[1] = SpreadStorageLibs.StorageId.WeightedNotional60DaysUsdt;
            inputData.storageIds[2] = SpreadStorageLibs.StorageId.WeightedNotional90DaysUsdt;
            return inputData;
        } else if (spreadInputs.asset == _DAI) {
            inputData.storageId = SpreadStorageLibs.StorageId.WeightedNotional90DaysDai;
            inputData.storageIds[0] = SpreadStorageLibs.StorageId.WeightedNotional28DaysDai;
            inputData.storageIds[1] = SpreadStorageLibs.StorageId.WeightedNotional60DaysDai;
            inputData.storageIds[2] = SpreadStorageLibs.StorageId.WeightedNotional90DaysDai;
            return inputData;
        }
        revert("Spread: asset not supported");
    }
}
